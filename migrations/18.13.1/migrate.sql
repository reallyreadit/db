/*
	Fix issue with unknown call to author_api.get_articles using NULL first parameter.
*/

CREATE OR REPLACE FUNCTION
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
			LEFT JOIN
				core.author ON
					article_author.author_id = author.id
		WHERE
			article_author.article_id IS NULL OR
			author.slug IN ('condé-nast', 'nature-editorial') OR
			(
				author.name ILIKE '%,%' AND
				author.name NOT ILIKE '%, Inc.'
			) OR
			author.name ILIKE '% and %'
	)
	SELECT
		article_api_article.*
	FROM
		article_api.get_articles(
			NULL::bigint,
			VARIADIC ARRAY(
				SELECT DISTINCT
					authorless_subscriber_article.id
				FROM
					authorless_subscriber_article
			)
		) AS article_api_article
	ORDER BY
		article_api_article.word_count DESC;
$$;