CREATE FUNCTION article_api.get_aotd()
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_articles(
		(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT 1
		)
	);
$func$;