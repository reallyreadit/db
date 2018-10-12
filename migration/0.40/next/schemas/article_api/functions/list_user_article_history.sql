CREATE FUNCTION article_api.list_user_article_history(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL
STABLE
AS $func$
	WITH history_article AS (
		SELECT
			greatest(article.date_created, star.date_starred) AS history_date,
			coalesce(article.article_id, star.article_id) AS article_id
		FROM
			(
				SELECT
					date_created,
					article_id
				FROM article_api.user_article_pages
				WHERE user_account_id = list_user_article_history.user_account_id
			) AS article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE user_account_id = list_user_article_history.user_account_id
			) AS star ON star.article_id = article.article_id
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM history_article) AS total_count
	FROM article_api.get_user_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM history_article
			ORDER BY history_date DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$func$;