CREATE FUNCTION article_api.list_user_hot_topics(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		articles.*,
		(SELECT count(*) FROM article_api.hot_topic) AS total_count
	FROM article_api.get_user_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article_api.hot_topic
			ORDER BY score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$func$;