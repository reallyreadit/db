/*
	Writer leaderboards 2.0.
*/

-- Add contact_status to author.
CREATE TYPE
	core.author_contact_status AS enum (
		'none',
		'attempted'
	);

ALTER TABLE
	core.author
ADD COLUMN
	contact_status core.author_contact_status NOT NULL
		DEFAULT
			'none'::core.author_contact_status;

CREATE TYPE
	authors.author_contact_status_assignment AS (
		slug text,
		contact_status text
	);

CREATE FUNCTION
	authors.assign_contact_status_to_authors(
		assignments authors.author_contact_status_assignment[]
	)
RETURNS
	SETOF bigint
LANGUAGE
	sql
AS $$
	UPDATE
		core.author
	SET
		contact_status = assignment.contact_status::core.author_contact_status
	FROM
		unnest(assign_contact_status_to_authors.assignments) AS assignment (
			slug,
			contact_status
		)
	WHERE
		author.slug = assignment.slug AND
		author.contact_status != assignment.contact_status::core.author_contact_status
	RETURNING
		author.id;
$$;

-- Add new earnings report with min/max filtering and minimal computation.
CREATE FUNCTION
	subscriptions.run_authors_earnings_report(
		min_amount_earned int,
		max_amount_earned int
	)
RETURNS
	TABLE (
		author_id bigint,
		amount_earned int
	)
LANGUAGE
	sql
STABLE
AS $$
	WITH author_distributions AS (
		SELECT
			author_distribution.author_id,
			sum(author_distribution.amount) AS distribution_total
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
				core.subscription_account ON
					subscription.provider = subscription_account.provider AND
					subscription.provider_account_id = subscription_account.provider_account_id AND
					subscription_account.environment = 'production'::core.subscription_environment
		GROUP BY
			author_distribution.author_id
	)
	SELECT
		author_distributions.author_id::bigint,
		author_distributions.distribution_total::int
	FROM
		author_distributions
	WHERE
		CASE
			WHEN
				run_authors_earnings_report.min_amount_earned != 0 AND
				run_authors_earnings_report.max_amount_earned != 0
			THEN
				author_distributions.distribution_total BETWEEN
					run_authors_earnings_report.min_amount_earned AND
					run_authors_earnings_report.max_amount_earned
			WHEN
				 run_authors_earnings_report.min_amount_earned != 0
			THEN
				author_distributions.distribution_total >= run_authors_earnings_report.min_amount_earned
			WHEN
				 run_authors_earnings_report.max_amount_earned != 0
			THEN
				author_distributions.distribution_total <= run_authors_earnings_report.max_amount_earned
			ELSE
				TRUE
		END;
$$;

-- Mark old earnings report as deprecated.
COMMENT ON FUNCTION
	subscriptions.run_authors_earnings_report()
IS
	'DEPRECATED';

-- Add new author leaderboard function based on earnings.
CREATE FUNCTION
	stats.get_top_author_leaderboard(
		min_amount_earned int,
		max_amount_earned int
	)
RETURNS
	TABLE (
		author_id bigint,
		author_name text,
		author_slug text,
		author_contact_status core.author_contact_status,
		user_account_id bigint,
		user_account_name text,
		donation_recipient_id bigint,
		donation_recipient_name text,
		minutes_read integer,
		top_article_id bigint,
		amount_earned integer,
		amount_paid integer
	)
LANGUAGE
	sql
STABLE
AS $$
	WITH earnings_report AS (
		SELECT
			earnings_report.*
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := get_top_author_leaderboard.min_amount_earned,
				max_amount_earned := get_top_author_leaderboard.max_amount_earned
			) AS earnings_report (
				author_id,
				amount_earned
			)
	),
	author_with_earnings AS (
		SELECT
			author.id AS author_id,
			author.name AS author_name,
			author.slug AS author_slug,
			author.contact_status AS author_contact_status,
			user_account.id AS user_account_id,
			user_account.name AS user_account_name,
			earnings_report.amount_earned
		FROM
			earnings_report
			JOIN
				core.author ON
					earnings_report.author_id = author.id
			LEFT JOIN
				core.author_user_account_assignment AS user_account_assignment ON
					author.id = user_account_assignment.author_id
			LEFT JOIN
				core.user_account ON
					user_account_assignment.user_account_id = user_account.id
	),
	author_reading_time AS (
		SELECT
			author_with_earnings.author_id,
			core.estimate_reading_time(
				word_count := sum(article.word_count)
			) AS total_minutes_read
		FROM
			author_with_earnings
			JOIN
				core.article_author ON
					author_with_earnings.author_id = article_author.author_id
			JOIN
				core.user_article ON
					article_author.article_id = user_article.article_id AND
					user_article.date_completed IS NOT NULL
			JOIN
				core.article ON
					user_article.article_id = article.id
		GROUP BY
			author_with_earnings.author_id
	),
	author_top_article AS (
		SELECT
			DISTINCT ON (
				article_author.author_id
			)
			article_author.author_id,
			article.id AS top_article_id
		FROM
			author_with_earnings
			JOIN
				core.article_author ON
					author_with_earnings.author_id = article_author.author_id
			JOIN
				core.article ON
					article_author.article_id = article.id
		ORDER BY
			article_author.author_id,
			article.top_score DESC,
			article.id DESC
	),
	author_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(author_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.payout_account ON
					author_with_earnings.user_account_id = payout_account.user_account_id
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
		GROUP BY
			author_with_earnings.author_id
	)
	SELECT
		author_with_earnings.author_id,
		author_with_earnings.author_name,
		author_with_earnings.author_slug,
		author_with_earnings.author_contact_status,
		author_with_earnings.user_account_id,
		author_with_earnings.user_account_name,
		donation_recipient.id,
		donation_recipient.name,
		author_reading_time.total_minutes_read::int,
		author_top_article.top_article_id,
		author_with_earnings.amount_earned,
		author_payouts.payout_total::int
	FROM
		author_with_earnings
		JOIN
			author_reading_time ON
				author_with_earnings.author_id = author_reading_time.author_id
		JOIN
			author_top_article ON
				author_with_earnings.author_id = author_top_article.author_id
		LEFT JOIN
			author_payouts ON
				author_with_earnings.author_id = author_payouts.author_id
		LEFT JOIN
			core.donation_account ON
				author_with_earnings.author_id = donation_account.author_id OR
				author_with_earnings.user_account_id = donation_account.user_account_id
		LEFT JOIN
			core.donation_recipient ON
				donation_account.donation_recipient_id = donation_recipient.id
$$;

-- Add new function for WRM syncing.
CREATE FUNCTION
	authors.run_wrm_sync_report(
		min_amount_earned int,
		max_amount_earned int
	)
RETURNS
	TABLE (
		author_name text,
		author_slug text,
		author_contact_status core.author_contact_status,
		user_account_name text,
		user_account_email text,
		amount_earned int,
		amount_paid int,
		amount_donated int
	)
LANGUAGE
	sql
STABLE
AS $$
	WITH earnings_report AS (
		SELECT
			earnings_report.*
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := run_wrm_sync_report.min_amount_earned,
				max_amount_earned := run_wrm_sync_report.max_amount_earned
			) AS earnings_report (
				author_id,
				amount_earned
			)
	),
	author_with_earnings AS (
		SELECT
			author.id AS author_id,
			author.name AS author_name,
			author.slug AS author_slug,
			author.contact_status AS author_contact_status,
			user_account.id AS user_account_id,
			user_account.name AS user_account_name,
			user_account.email AS user_account_email,
			earnings_report.amount_earned
		FROM
			earnings_report
			JOIN
				core.author ON
					earnings_report.author_id = author.id
			LEFT JOIN
				core.author_user_account_assignment AS user_account_assignment ON
					author.id = user_account_assignment.author_id
			LEFT JOIN
				core.user_account ON
					user_account_assignment.user_account_id = user_account.id
	),
	author_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(author_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.payout_account ON
					author_with_earnings.user_account_id = payout_account.user_account_id
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
		GROUP BY
			author_with_earnings.author_id
	),
	donation_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(donation_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.donation_account ON
					author_with_earnings.author_id = donation_account.author_id OR
					author_with_earnings.user_account_id = donation_account.user_account_id
			JOIN
				core.donation_payout ON
					donation_account.id = donation_payout.donation_account_id
		GROUP BY
			author_with_earnings.author_id
	)
	SELECT
		author_with_earnings.author_name,
		author_with_earnings.author_slug,
		author_with_earnings.author_contact_status,
		author_with_earnings.user_account_name,
		author_with_earnings.user_account_email,
		author_with_earnings.amount_earned,
		coalesce(author_payouts.payout_total::int, 0),
		coalesce(donation_payouts.payout_total::int, 0)
	FROM
		author_with_earnings
		LEFT JOIN
			author_payouts ON
				author_with_earnings.author_id = author_payouts.author_id
		LEFT JOIN
			donation_payouts ON
				author_with_earnings.author_id = donation_payouts.author_id
$$;

-- Add article_api.get_articles overload without variadic param.
CREATE FUNCTION
	article_api.get_articles(
		article_ids bigint[],
		user_account_id bigint
	)
RETURNS
	SETOF article_api.article
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		*
	FROM
		article_api.get_articles(get_articles.user_account_id, VARIADIC get_articles.article_ids);
$$;

