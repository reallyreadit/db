/*
	This migration updates multiple analytics reports and adds a new monthly recurring revenue report.
*/

-- Add new monthly recurring revenue report.
CREATE TYPE
	analytics.monthly_recurring_revenue_report_line_item AS (
		period timestamp,
		amount int
	);

CREATE FUNCTION
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
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					subscription_account.user_account_id NOT IN (1, 2) AND
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

-- Report prorated amount.
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
					account.environment = 'production'::core.subscription_environment AND
					account.user_account_id NOT IN (1, 2)
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

-- Filter out blog post reads, remove extraneous columns, and add date_subscribed.
DROP FUNCTION
	analytics.get_signups(
		start_date timestamp,
		end_date timestamp
	);
CREATE FUNCTION
	analytics.get_signups(
		start_date timestamp,
		end_date timestamp
	)
RETURNS TABLE (
	id bigint,
	name text,
	email text,
	date_created timestamp,
	time_zone_name text,
	client_mode text,
	marketing_variant integer,
	referrer_url text,
	initial_path text,
	current_path text,
	action text,
	article_view_count bigint,
	article_read_count bigint,
	date_subscribed timestamp
)
LANGUAGE
	sql
STABLE
AS $$
	WITH new_user AS (
		SELECT
			user_account.id,
			user_account.name,
			user_account.email,
			user_account.date_created,
			user_account.time_zone_id,
			user_account.creation_analytics
		FROM
			core.user_account
		WHERE
			user_account.date_created <@ tsrange(get_signups.start_date, get_signups.end_date)
	)
	SELECT
		new_user.id,
		new_user.name,
		new_user.email,
		new_user.date_created,
		time_zone.name,
		new_user.creation_analytics->'client'->>'mode',
		(new_user.creation_analytics->>'marketing_variant')::int,
		new_user.creation_analytics->>'referrer_url',
		new_user.creation_analytics->>'initial_path',
		new_user.creation_analytics->>'current_path',
		new_user.creation_analytics->>'action',
		coalesce(user_article_stats.view_count, 0),
		coalesce(user_article_stats.read_count, 0),
		subscription_purchase.date_paid
	FROM
		new_user
		LEFT JOIN time_zone ON
			time_zone.id = new_user.time_zone_id
		LEFT JOIN (
			SELECT
				new_user.id AS user_account_id,
				count(*) AS view_count,
				count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS read_count
			FROM
				new_user
				JOIN
					core.user_article ON
						new_user.id = user_article.user_account_id
				JOIN
					core.article ON
						user_article.article_id = article.id
			WHERE
				article.source_id != 48542 -- readup blog
			GROUP BY
				new_user.id
		) AS user_article_stats ON
			user_article_stats.user_account_id = new_user.id
		LEFT JOIN (
			SELECT
				new_user.id AS user_account_id,
				min(subscription_period.date_paid) AS date_paid
			FROM
				new_user
				JOIN
					core.subscription_account ON
						new_user.id = subscription_account.user_account_id
				JOIN
					core.subscription ON
						subscription_account.provider = subscription.provider AND
						subscription_account.provider_account_id = subscription.provider_account_id
				JOIN
					core.subscription_period ON
						subscription.provider = subscription_period.provider AND
						subscription.provider_subscription_id = subscription_period.provider_subscription_id
			WHERE
				subscription_account.environment = 'production'::core.subscription_environment AND
				subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			GROUP BY
				new_user.id
		) AS subscription_purchase ON
			subscription_purchase.user_account_id = new_user.id
	ORDER BY
		new_user.date_created DESC;
$$;

-- Filter out blog post reads and remove extraneous columns.
DROP FUNCTION
	analytics.get_conversions(
		start_date timestamp,
		end_date timestamp
	);
CREATE FUNCTION
	analytics.get_conversions(
		start_date timestamp,
		end_date timestamp
	)
RETURNS TABLE (
	week timestamp,
	visitor_count bigint,
	signup_count bigint,
	signup_conversion numeric,
	article_viewer_count bigint,
	article_viewer_conversion numeric,
	article_reader_count bigint,
	article_reader_conversion numeric
)
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
				get_conversions.start_date,
				get_conversions.end_date,
				'1 week'::interval
			) AS week (first_day)
	)
	SELECT
		report_period.week,
		visitor_total.count,
		signup_total.count,
		(
			CASE WHEN visitor_total.count > 0
				THEN signup_total.count::numeric / visitor_total.count
				ELSE 0
			END
		),
		article_action_total.viewer_count,
		(
			CASE WHEN signup_total.count > 0
				THEN article_action_total.viewer_count::numeric / signup_total.count
				ELSE 0
			END
		),
		article_action_total.reader_count,
		(
			CASE WHEN article_action_total.viewer_count > 0
				THEN article_action_total.reader_count::numeric / article_action_total.viewer_count
				ELSE 0
			END
		)
	FROM
		report_period
		JOIN (
			SELECT
				report_period.week,
				coalesce(sum(traffic_total.unique_visit_count), 0) AS count
			FROM
				report_period
				LEFT JOIN core.website_traffic_weekly_total AS traffic_total ON
					traffic_total.week <@ report_period.range
			GROUP BY
				report_period.week
		) AS visitor_total ON
			visitor_total.week = report_period.week
		JOIN (
			SELECT
				report_period.week,
				coalesce(count(user_account.id), 0) AS count
			FROM
				report_period
				LEFT JOIN core.user_account ON
					user_account.date_created <@ report_period.range
			GROUP BY
				report_period.week
		) AS signup_total ON
			signup_total.week = report_period.week
		JOIN (
			SELECT
				report_period.week,
				coalesce(
					count(new_user.date_created) FILTER (WHERE new_user.has_viewed_article),
					0
				) AS viewer_count,
				coalesce(
					count(new_user.date_created) FILTER (WHERE new_user.has_read_article),
					0
				) AS reader_count
			FROM
				report_period
				LEFT JOIN (
					SELECT
						user_account.date_created,
						coalesce(
							min(user_article.date_created) < user_account.date_created + '1 week'::interval,
							false
						) AS has_viewed_article,
						coalesce(
							min(user_article.date_completed) < user_account.date_created + '1 week'::interval,
							false
						) AS has_read_article
					FROM
						core.user_account
						JOIN
							core.user_article ON
								user_account.id = user_article.user_account_id
						JOIN
							core.article ON
								user_article.article_id = article.id
					WHERE
						user_account.date_created <@ (
							SELECT
								tsrange(
									min(lower(report_period.range)),
									max(upper(report_period.range))
								)
							FROM
								report_period
						) AND
						article.source_id != 48542 -- readup blog
					GROUP BY
						user_account.id
				) AS new_user ON
					report_period.range @> new_user.date_created
			GROUP BY
				report_period.week
		) AS article_action_total ON
			report_period.week = article_action_total.week
	ORDER BY
		report_period.week DESC;
$$;

-- Add subscriptions active and subscription lapse counts.
DROP FUNCTION
	analytics.get_daily_totals(
		start_date timestamp,
		end_date timestamp
	);
CREATE FUNCTION
	analytics.get_daily_totals(
		start_date timestamp,
		end_date timestamp
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
							coalesce(next_period.payment_status, 'failed'::core.subscription_payment_status) != 'succeeded'::core.subscription_payment_status
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
				LEFT JOIN
					core.subscription_period AS next_period ON
						subscription_period.provider = next_period.provider AND
						subscription_period.next_provider_period_id = next_period.provider_period_id
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					subscription_account.user_account_id NOT IN (1, 2) AND
					subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			GROUP BY
				report_period.day
		) AS subscriptions_total ON
			report_period.day = subscriptions_total.day
	ORDER BY report_period.day DESC;
$$;