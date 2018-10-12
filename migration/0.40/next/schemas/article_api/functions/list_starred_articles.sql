CREATE FUNCTION article_api.list_starred_articles(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL
STABLE
AS $func$
	WITH starred_article AS (
		SELECT
			article_id,
			date_starred
		FROM star
		WHERE user_account_id = list_starred_articles.user_account_id
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM starred_article) AS total_count
	FROM article_api.get_user_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM starred_article
			ORDER BY date_starred DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$func$;