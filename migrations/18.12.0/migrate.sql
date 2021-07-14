/*
	Add table and update functions for writer payouts. Also update get_articles_by_author_slug sort.
*/

CREATE TABLE
	core.author_payout (
		id text,
		CONSTRAINT
			author_payout_pkey
		PRIMARY KEY (
			id
		),
		date_created timestamp NOT NULL,
		payout_account_id text NOT NULL,
		CONSTRAINT
			author_payout_payout_account_id_fkey
		FOREIGN KEY (
			payout_account_id
		)
		REFERENCES
			core.payout_account (id),
		amount int NOT NULL
	);

CREATE FUNCTION
	subscriptions.create_author_payout(
		id text,
		date_created timestamp,
		payout_account_id text,
		amount int
	)
RETURNS
	SETOF core.author_payout
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.author_payout (
			id,
			date_created,
			payout_account_id,
			amount
		)
	VALUES (
		create_author_payout.id,
		create_author_payout.date_created,
		create_author_payout.payout_account_id,
		create_author_payout.amount
	)
	ON CONFLICT (
		id
	)
	DO NOTHING
	RETURNING
		*;
$$;

CREATE OR REPLACE FUNCTION
	subscriptions.run_payout_totals_report()
RETURNS
	SETOF subscriptions.payout_totals_report
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		(
			SELECT
				sum(author_payout.amount)::int
			FROM
				core.author_payout
		),
		(
			SELECT
				sum(donation_payout.amount)::int
			FROM
				core.donation_payout
		);
$$;

CREATE FUNCTION
	subscriptions.run_payout_totals_report_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF subscriptions.payout_totals_report
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		(
			SELECT
				sum(payout.amount)::int
			FROM
				core.author_payout AS payout
				JOIN
					core.payout_account AS account ON
						payout.payout_account_id = account.id
			WHERE
				account.user_account_id = run_payout_totals_report_for_user_account.user_account_id
		),
		(
			SELECT
				sum(payout.amount)::int
			FROM
				core.donation_payout AS payout
				JOIN
					core.donation_account AS account ON
						payout.donation_account_id = account.id
			WHERE
				account.user_account_id = run_payout_totals_report_for_user_account.user_account_id
		);
$$;

CREATE OR REPLACE FUNCTION
	article_api.get_articles_by_author_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS SETOF
	article_api.article_page_result
LANGUAGE
	sql
STABLE
AS $$
	WITH author_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published,
			article.top_score
		FROM
			core.article
			JOIN
				core.article_author ON
					article.id = article_author.article_id
			JOIN
				core.author ON
					article_author.author_id = author.id
		WHERE
			author.slug = get_articles_by_author_slug.slug AND
			article_author.date_unassigned IS NULL AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_author_slug.min_length,
				max_length := get_articles_by_author_slug.max_length
			)
	)
	SELECT
		articles.*,
		(
			SELECT
				count(*)
			FROM
				author_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
				SELECT
					author_article.id
				FROM
					author_article
				ORDER BY
					author_article.top_score DESC,
					author_article.date_published DESC NULLS LAST,
					author_article.id DESC
				OFFSET
					(get_articles_by_author_slug.page_number - 1) * get_articles_by_author_slug.page_size
				LIMIT
					get_articles_by_author_slug.page_size
			)
		) AS articles;
$$;