CREATE FUNCTION article_api.list_user_community_reads(
	user_account_id bigint,
	page_number int,
	page_size int,
	sort text
)
RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		articles.*,
		(SELECT count(*) FROM article_api.community_read) AS total_count
	FROM article_api.get_user_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article_api.community_read
			ORDER BY CASE sort
				WHEN 'hot' THEN hot_score
			    WHEN 'top' THEN top_score
			END DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$func$;