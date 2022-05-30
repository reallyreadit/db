-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- Create author earnings report.
CREATE TYPE
	subscriptions.author_earnings_report_line_item
AS (
	author_id bigint,
	author_name text,
	author_slug text,
	user_account_id bigint,
	user_account_name text,
	minutes_read int,
	amount_earned int,
	amount_paid int
);

CREATE FUNCTION
	subscriptions.run_authors_earnings_report()
RETURNS
	SETOF subscriptions.author_earnings_report_line_item
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		author.id,
		author.name,
		author.slug,
		user_account.id,
		user_account.name,
		sum(author_distribution.minutes_read)::int,
		sum(author_distribution.amount)::int,
		0
	FROM
		core.subscription_period_author_distribution AS author_distribution
		JOIN
			core.subscription_period AS period ON
				author_distribution.provider = period.provider AND
				author_distribution.provider_period_id = period.provider_period_id AND
				period.date_refunded IS NULL
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
			core.author ON
				author_distribution.author_id = author.id
		LEFT JOIN
			core.author_user_account_assignment AS user_account_assignment ON
				author.id = user_account_assignment.author_id
		LEFT JOIN
			core.user_account ON
				user_account_assignment.user_account_id = user_account.id
	GROUP BY
		author.id,
		user_account.id;
$$;

-- Create admin revenue report.
CREATE TYPE
	analytics.revenue_report_line_item
AS (
	period timestamp,
	provider core.subscription_provider,
	price_name text,
	price_amount int,
	quantity_purchased int,
	quantity_refunded int
);

CREATE FUNCTION
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
			price.amount AS price_amount
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
