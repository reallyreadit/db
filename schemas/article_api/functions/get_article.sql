CREATE FUNCTION article_api.get_article(
	article_id bigint
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_articles(
		article_id
	);
$func$;