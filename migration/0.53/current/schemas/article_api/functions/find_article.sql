CREATE FUNCTION article_api.find_article(
	slug text
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_articles(
		(SELECT id FROM article WHERE slug = find_article.slug)
	);
$func$;