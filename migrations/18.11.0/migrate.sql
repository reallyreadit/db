-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
	Adding authenticated visits to website traffic, adding weekly user activity report, and removing admin users from all
	analytics reports.
*/

-- Add new unique_authenticated_visit_count column and update the analytics function.
ALTER TABLE
	core.website_traffic_weekly_total
ADD COLUMN
	unique_authenticated_visit_count int NOT NULL DEFAULT 0;

DROP FUNCTION
	analytics.create_or_update_website_traffic_weekly_total(
		week timestamp,
		unique_visit_count int
	);

CREATE FUNCTION
	analytics.create_or_update_website_traffic_weekly_total(
		week timestamp,
		unique_visit_count int,
		unique_authenticated_visit_count int
	)
RETURNS
	SETOF core.website_traffic_weekly_total
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.website_traffic_weekly_total (
			week,
			unique_visit_count,
			unique_authenticated_visit_count,
			last_updated
		)
	VALUES (
		create_or_update_website_traffic_weekly_total.week,
		create_or_update_website_traffic_weekly_total.unique_visit_count,
		create_or_update_website_traffic_weekly_total.unique_authenticated_visit_count,
		core.utc_now()
	)
	ON CONFLICT (
		week
	)
	DO UPDATE SET
		unique_visit_count = create_or_update_website_traffic_weekly_total.unique_visit_count,
		unique_authenticated_visit_count = create_or_update_website_traffic_weekly_total.unique_authenticated_visit_count,
		last_updated = core.utc_now()
	RETURNING
		*;
$$;

-- Create the new weekly user activity report.
CREATE TYPE
	analytics.weekly_user_activity_report
AS (
	week timestamp,
	active_user_count int,
	active_reader_count int,
	minutes_reading int,
	minutes_reading_to_completion int
);

CREATE FUNCTION
	analytics.get_weekly_user_activity(
		start_date timestamp,
		end_date timestamp
	)
RETURNS
	SETOF analytics.weekly_user_activity_report
LANGUAGE
	sql
STABLE
AS $$
	WITH report_period AS (
		SELECT
			first_day AS week,
			tsrange(first_day, first_day + '1 week'::interval) AS range
		FROM
			generate_series(
				get_weekly_user_activity.start_date,
				get_weekly_user_activity.end_date,
				'1 week'::interval
			) AS week (first_day)
	)
	SELECT
		report_period.week,
		coalesce(active_user_total.count::int, 0),
		coalesce(reading_time_total.user_count::int, 0),
		coalesce(reading_time_total.minutes_reading, 0),
		coalesce(reading_time_total.minutes_reading_to_completion, 0)
	FROM
		report_period
		LEFT JOIN (
			SELECT
				report_period.week,
				sum(traffic_total.unique_authenticated_visit_count) AS count
			FROM
				report_period
				JOIN
					core.website_traffic_weekly_total AS traffic_total ON
						report_period.range @> traffic_total.week
			GROUP BY
				report_period.week
		) AS active_user_total ON
			report_period.week = active_user_total.week
		LEFT JOIN (
			SELECT
				report_period.week,
				count(DISTINCT user_account.id) AS user_count,
				core.estimate_reading_time(
					sum(progress.words_read)
				) AS minutes_reading,
				core.estimate_reading_time(
					sum(progress.words_read)
						FILTER (
							WHERE user_article.date_completed IS NOT NULL
						)
				) AS minutes_reading_to_completion
			FROM
				report_period
				JOIN
					core.user_article_progress AS progress ON
						report_period.range @> progress.period
				JOIN
					core.user_article ON
						progress.user_account_id = user_article.user_account_id AND
						progress.article_id = user_article.article_id
				JOIN
					core.user_account ON
						user_article.user_account_id = user_account.id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.week
		) AS reading_time_total ON
			report_period.week = reading_time_total.week
	ORDER BY
		report_period.week DESC;
$$;

-- Filter admin users from existing reports and fix subscription lapse count bug.
CREATE OR REPLACE FUNCTION
	analytics.get_daily_totals(
		start_date timestamp without time zone,
		end_date timestamp without time zone
	)
RETURNS TABLE(
	day timestamp,
	signup_app_count bigint,
	signup_browser_count bigint,
	signup_unknown_count bigint,
	read_app_count bigint,
	read_browser_count bigint,
	read_unknown_count bigint,
	post_app_count bigint,
	post_browser_count bigint,
	post_unknown_count bigint,
	reply_app_count bigint,
	reply_browser_count bigint,
	reply_unknown_count bigint,
	post_tweet_app_count bigint,
	post_tweet_browser_count bigint,
	extension_installation_count bigint,
	extension_removal_count bigint,
	subscriptions_active_count bigint,
	subscription_lapse_count bigint
)
LANGUAGE
	sql
STABLE
AS $$
	WITH report_period AS (
		SELECT
			date AS day,
			tsrange(date, date + '1 day'::interval) AS range
		FROM generate_series(
			get_daily_totals.start_date,
			get_daily_totals.end_date,
			'1 day'::interval
		) AS series (date)
	)
	SELECT
		report_period.day,
		coalesce(signup_totals.app_count, 0),
		coalesce(signup_totals.browser_count, 0),
		coalesce(signup_totals.unknown_count, 0),
		coalesce(read_totals.app_count, 0),
		coalesce(read_totals.browser_count, 0),
		coalesce(read_totals.unknown_count, 0),
		coalesce(comment_totals.post_app_count, 0) + coalesce(silent_post_totals.app_count, 0),
		coalesce(comment_totals.post_browser_count, 0) + coalesce(silent_post_totals.browser_count, 0),
		coalesce(comment_totals.post_unknown_count, 0) + coalesce(silent_post_totals.unknown_count, 0),
		coalesce(comment_totals.reply_app_count, 0),
		coalesce(comment_totals.reply_browser_count, 0),
		coalesce(comment_totals.reply_unknown_count, 0),
		coalesce(post_tweet_total.app_count, 0) AS post_tweet_app_count,
		coalesce(post_tweet_total.browser_count, 0) AS post_tweet_browser_count,
		coalesce(extension_installation_total.count, 0) AS extension_installation_count,
		coalesce(extension_removal_total.count, 0) AS extension_removal_count,
		coalesce(subscriptions_total.active_count, 0),
		coalesce(subscriptions_total.lapsed_count, 0)
	FROM
		report_period
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE creation_analytics IS NULL) AS unknown_count
			FROM
				user_account
				JOIN report_period ON user_account.date_created <@ report_period.range
			GROUP BY report_period.day
		) AS signup_totals ON signup_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_article
				JOIN report_period ON user_article.date_completed <@ report_period.range
				JOIN user_account ON user_article.user_account_id = user_account.id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY report_period.day
		) AS read_totals ON read_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						(
							comment.analytics->'client'->>'mode' = 'App' OR
							comment.analytics->'client'->>'type' = 'ios/app'
						)
				) AS post_app_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						(
							comment.analytics->'client'->>'mode' = 'Browser' OR
							comment.analytics->'client'->>'type' = 'web/extension'
						)
				) AS post_browser_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						comment.analytics IS NULL
				) AS post_unknown_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						(
							comment.analytics->'client'->>'mode' = 'App' OR
							comment.analytics->'client'->>'type' = 'ios/app'
						)
				) AS reply_app_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						(
							comment.analytics->'client'->>'mode' = 'Browser' OR
							comment.analytics->'client'->>'type' = 'web/extension'
						)
				) AS reply_browser_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						comment.analytics IS NULL
				) AS reply_unknown_count
			FROM
				report_period
				JOIN core.comment ON
					comment.date_created <@ report_period.range
				JOIN core.user_account ON
					user_account.id = comment.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS comment_totals ON
			comment_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						silent_post.analytics->'client'->>'mode' = 'App' OR
						silent_post.analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (
					WHERE
						silent_post.analytics->'client'->>'mode' = 'Browser' OR
						silent_post.analytics->'client'->>'type' = 'web/extension'
				) AS browser_count,
				count(*) FILTER (WHERE silent_post.analytics IS NULL) AS unknown_count
			FROM
				report_period
				JOIN core.silent_post ON
					silent_post.date_created <@ report_period.range
				JOIN core.user_account ON
					user_account.id = silent_post.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS silent_post_totals ON
			silent_post_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						comment.analytics->'client'->>'mode' = 'App' OR
						comment.analytics->'client'->>'type' = 'ios/app' OR
						silent_post.analytics->'client'->>'mode' = 'App' OR
						silent_post.analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (
					WHERE
						comment.analytics->'client'->>'mode' = 'Browser' OR
						comment.analytics->'client'->>'type' = 'web/extension' OR
						silent_post.analytics->'client'->>'mode' = 'Browser' OR
						silent_post.analytics->'client'->>'type' = 'web/extension'
				) AS browser_count
			FROM
				report_period
				JOIN core.auth_service_post ON
					auth_service_post.date_posted <@ report_period.range
				LEFT JOIN core.comment ON
					comment.id = auth_service_post.comment_id
				LEFT JOIN core.silent_post ON
					silent_post.id = auth_service_post.silent_post_id
				JOIN core.user_account ON
					user_account.id = comment.user_account_id OR
					user_account.id = silent_post.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS post_tweet_total ON
				post_tweet_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) AS count
			FROM
				extension_installation
				JOIN report_period ON extension_installation.timestamp <@ report_period.range
				LEFT JOIN user_account ON extension_installation.user_account_id = user_account.id
			WHERE
				coalesce(user_account.role, 'regular'::core.user_account_role) != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS extension_installation_total ON extension_installation_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) AS count
			FROM
				extension_removal
				JOIN report_period ON extension_removal.timestamp <@ report_period.range
				LEFT JOIN user_account ON extension_removal.user_account_id = user_account.id
			WHERE
				coalesce(user_account.role, 'regular'::core.user_account_role) != 'admin'::core.user_account_role
		GROUP BY
			report_period.day
		) AS extension_removal_total ON extension_removal_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(DISTINCT subscription_account.user_account_id)
					FILTER (
						WHERE
							report_period.range && tsrange(
								subscription_period.begin_date,
								coalesce(subscription_period.date_refunded, subscription_period.end_date)
							)
					) AS active_count,
				count(DISTINCT subscription_account.user_account_id)
					FILTER (
						WHERE
							report_period.range @> subscription_period.renewal_grace_period_end_date AND
							coalesce(next_period.payment_status, 'failed'::core.subscription_payment_status) != 'succeeded'::core.subscription_payment_status AND
							subscription_period.renewal_grace_period_end_date <= core.utc_now()
					) AS lapsed_count
			FROM
				report_period
				JOIN
					core.subscription_period ON
						report_period.range && tsrange(
							subscription_period.begin_date,
							coalesce(subscription_period.date_refunded, subscription_period.end_date)
						) OR
						report_period.range @> subscription_period.renewal_grace_period_end_date
				JOIN
					core.subscription ON
						subscription_period.provider = subscription.provider AND
						subscription_period.provider_subscription_id = subscription.provider_subscription_id
				JOIN
					core.subscription_account ON
						subscription.provider = subscription_account.provider AND
						subscription.provider_account_id = subscription_account.provider_account_id
				JOIN
					core.user_account ON
						subscription_account.user_account_id = user_account.id
				LEFT JOIN
					core.subscription_period AS next_period ON
						subscription_period.provider = next_period.provider AND
						subscription_period.next_provider_period_id = next_period.provider_period_id
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					user_account.role != 'admin'::core.user_account_role AND
					subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			GROUP BY
				report_period.day
		) AS subscriptions_total ON
			report_period.day = subscriptions_total.day
	ORDER BY report_period.day DESC;
$$;

CREATE OR REPLACE FUNCTION
	analytics.get_monthly_recurring_revenue_report(
		start_date timestamp,
		end_date timestamp
	)
RETURNS
	SETOF analytics.monthly_recurring_revenue_report_line_item
LANGUAGE
	sql
STABLE
AS $$
	WITH report_period AS (
		SELECT
			series.period,
			tsrange(series.period, series.period + '1 day'::interval) AS range
		FROM
			generate_series(
				get_monthly_recurring_revenue_report.start_date,
				get_monthly_recurring_revenue_report.end_date,
				'1 day'::interval
			) AS series (
				period
			)
	)
	SELECT
		report_period.period,
		coalesce(
			sum(report_period_user_account_amount.amount)::int,
			0
		)
	FROM
		report_period
		LEFT JOIN (
			SELECT DISTINCT ON (
					report_period.period,
					subscription_account.user_account_id
				)
				report_period.period,
				coalesce(
					subscription_period.prorated_price_amount,
					price_level.amount
				) AS amount
			FROM
				report_period
				JOIN
					core.subscription_period ON
						report_period.range && tsrange(
							subscription_period.begin_date,
							coalesce(subscription_period.date_refunded, subscription_period.end_date)
						)
				JOIN
					subscriptions.price_level ON
						subscription_period.provider = price_level.provider AND
						subscription_period.provider_price_id = price_level.provider_price_id
				JOIN
					core.subscription ON
						subscription_period.provider = subscription.provider AND
						subscription_period.provider_subscription_id = subscription.provider_subscription_id
				JOIN
					core.subscription_account ON
						subscription.provider = subscription_account.provider AND
						subscription.provider_account_id = subscription_account.provider_account_id
				JOIN
					core.user_account ON
						subscription_account.user_account_id = user_account.id
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					user_account.role != 'admin'::core.user_account_role AND
					subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			ORDER BY
				period,
				subscription_account.user_account_id,
				subscription_period.begin_date DESC
		) AS report_period_user_account_amount ON
			report_period.period = report_period_user_account_amount.period
	GROUP BY
		report_period.period
	ORDER BY
		report_period.period;
$$;

CREATE OR REPLACE FUNCTION
	analytics.get_revenue_report(
		start_date timestamp,
		end_date timestamp
	)
RETURNS
	SETOF analytics.revenue_report_line_item
LANGUAGE
	sql
STABLE
AS $$
	WITH report_period AS (
		SELECT
			series.period,
			tsrange(series.period, series.period + '1 day'::interval) AS range
		FROM
			generate_series(
				get_revenue_report.start_date,
				get_revenue_report.end_date,
				'1 day'::interval
			) AS series (
				period
			)
	),
	purchase AS (
		SELECT
			period.date_paid,
			period.date_refunded,
			period.provider,
			price.name AS price_name,
			coalesce(period.prorated_price_amount, price.amount) AS price_amount
		FROM
			core.subscription_period AS period
			JOIN
				subscriptions.price_level AS price ON
					period.provider = price.provider AND
					period.provider_price_id = price.provider_price_id
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id AND
					account.environment = 'production'::core.subscription_environment
			JOIN
				core.user_account ON
					account.user_account_id = user_account.id AND
					user_account.role != 'admin'::core.user_account_role
		WHERE
			period.payment_status = 'succeeded'::core.subscription_payment_status
	)
	SELECT
		report_period.period,
		purchase.provider,
		purchase.price_name,
		coalesce(purchase.price_amount, 0),
		count(purchase.date_paid)::int,
		count(purchase.date_refunded)::int
	FROM
		report_period
		LEFT JOIN
			purchase ON
				report_period.range @> purchase.date_paid OR
				report_period.range @> purchase.date_refunded
	GROUP BY
		report_period.period,
		purchase.provider,
		purchase.price_amount,
		purchase.price_name;
$$;