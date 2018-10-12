CREATE FUNCTION article_api.list_hot_topics(
	page_number int,
	page_size int
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		articles.*,
		(SELECT count(*) FROM article_api.hot_topic) AS total_count
	FROM article_api.get_articles(
		VARIADIC ARRAY(
			SELECT id
			FROM article_api.hot_topic
			ORDER BY score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$func$;