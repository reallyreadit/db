CREATE FUNCTION article_api.get_user_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name AS source,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1] AS url,
		coalesce(article_authors.names, '{}') AS authors,
		coalesce(article_tags.names, '{}') AS tags,
		article_pages.word_count,
		coalesce(article_comment_count.count, 0) AS comment_count,
		coalesce(article_read_count.count, 0) AS read_count,
		user_article_pages.date_created,
		coalesce(
		   article_api.get_percent_complete(
		      user_article_pages.readable_word_count,
		      user_article_pages.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article_pages.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred
	FROM
		article
		JOIN article_api.article_pages ON (
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (article_ids)
		)
		JOIN source ON source.id = article.source_id
		LEFT JOIN article_api.article_authors ON (
			article_authors.article_id = article.id AND
			article_authors.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_tags ON (
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_comment_count ON (
			article_comment_count.article_id = article.id AND
			article_comment_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_read_count ON (
			article_read_count.article_id = article.id AND
			article_read_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.user_article_pages ON (
		   user_article_pages.user_account_id = get_user_articles.user_account_id AND
			user_article_pages.article_id = article.id AND
			user_article_pages.article_id = ANY (article_ids)
		)
		LEFT JOIN star ON (
			star.user_account_id = get_user_articles.user_account_id AND
			star.article_id = article.id
		)
	ORDER BY array_position(article_ids, article.id)
$func$;