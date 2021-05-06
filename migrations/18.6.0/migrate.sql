-- Create function to find articles read by subscribed readers that are missing metadata.
CREATE FUNCTION
	analytics.get_articles_requiring_author_assignments()
RETURNS
	SETOF article_api.article
LANGUAGE
	sql
STABLE
AS $$
	WITH authorless_subscriber_article AS (
		SELECT
			article.id,
			article.word_count
		FROM
			core.subscription_period AS period
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id AND
					period.date_refunded IS NULL
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id AND
					account.environment = 'production'::core.subscription_environment
			JOIN
				core.user_article ON
					account.user_account_id = user_article.user_account_id AND
					period.begin_date <= user_article.date_completed AND
					period.renewal_grace_period_end_date > user_article.date_completed
			JOIN
				core.article ON
					user_article.article_id = article.id
			LEFT JOIN
				core.article_author ON
					user_article.article_id = article_author.article_id AND
					article_author.date_unassigned IS NULL
		WHERE
			article_author.article_id IS NULL
	)
	SELECT
		article_api_article.*
	FROM
		article_api.get_articles(
			user_account_id := NULL,
			VARIADIC article_ids := ARRAY(
				SELECT DISTINCT
					authorless_subscriber_article.id
				FROM
					authorless_subscriber_article
			)
		) AS article_api_article
	ORDER BY
		article_api_article.word_count DESC;
$$;

-- Update get_articles_by_source_slug to sort NULLS LAST.
CREATE OR REPLACE FUNCTION
	article_api.get_articles_by_source_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
)
RETURNS
	SETOF article_api.article_page_result
LANGUAGE
	sql
STABLE
AS $$
	WITH publisher_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published
		FROM
			core.article
		WHERE
			article.source_id = (
				SELECT
					source.id
				FROM
					core.source
				WHERE
					source.slug = get_articles_by_source_slug.slug
			) AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_source_slug.min_length,
				max_length := get_articles_by_source_slug.max_length
			)
	)
	SELECT
		articles.*,
		(
			SELECT
				count(*)
			FROM
				publisher_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
				SELECT
					publisher_article.id
				FROM
					publisher_article
				ORDER BY
					publisher_article.date_published DESC NULLS LAST
				OFFSET
					(get_articles_by_source_slug.page_number - 1) * get_articles_by_source_slug.page_size
				LIMIT
					get_articles_by_source_slug.page_size
			)
		) AS articles;
$$;

-- Drop unused deprecated functions.
DROP FUNCTION
	community_reads.get_articles_by_author_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	);

DROP FUNCTION
	community_reads.get_articles_by_source_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	);