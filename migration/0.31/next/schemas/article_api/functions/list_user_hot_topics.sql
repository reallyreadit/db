CREATE FUNCTION article_api.list_user_hot_topics(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL AS $func$
	SELECT
		*,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_user_hot_topics.user_account_id AND
		(comment_count > 0 OR read_count > 1) AND
		(aotd_timestamp IS NULL OR aotd_timestamp != (SELECT max(aotd_timestamp) FROM article))
	ORDER BY score DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;