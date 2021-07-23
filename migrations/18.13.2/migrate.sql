/*
	Add top_source to wrm sync report.
*/

DROP FUNCTION
	authors.run_wrm_sync_report(
		min_amount_earned integer,
		max_amount_earned integer
	);

CREATE FUNCTION authors.run_wrm_sync_report(
	min_amount_earned integer,
	max_amount_earned integer
)
RETURNS
	TABLE (
		author_name text,
		author_slug text,
		author_contact_status core.author_contact_status,
		top_source text,
		user_account_name text,
		user_account_email text,
		amount_earned integer,
		amount_paid integer,
		amount_donated integer
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
	top_source AS (
		SELECT
			DISTINCT ON (
				author_source_stats.author_id
			)
			author_source_stats.author_id,
			author_source_stats.source_name
		FROM
			(
				SELECT
					author_with_earnings.author_id,
					source.name AS source_name,
					count(*) AS article_count
				FROM
					author_with_earnings
					JOIN
						core.article_author ON
							author_with_earnings.author_id = article_author.author_id
					JOIN
						core.article ON
							article_author.article_id = article.id
					JOIN
						core.source ON
							article.source_id = source.id
				GROUP BY
					author_with_earnings.author_id,
					source.id
			) AS author_source_stats
		ORDER BY
			author_source_stats.author_id,
			author_source_stats.article_count DESC
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
		trim(top_source.source_name),
		author_with_earnings.user_account_name,
		author_with_earnings.user_account_email,
		author_with_earnings.amount_earned,
		coalesce(author_payouts.payout_total::int, 0),
		coalesce(donation_payouts.payout_total::int, 0)
	FROM
		author_with_earnings
		JOIN
			top_source ON
				author_with_earnings.author_id = top_source.author_id
		LEFT JOIN
			author_payouts ON
				author_with_earnings.author_id = author_payouts.author_id
		LEFT JOIN
			donation_payouts ON
				author_with_earnings.author_id = donation_payouts.author_id
$$;