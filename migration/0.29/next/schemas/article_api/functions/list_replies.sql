CREATE FUNCTION article_api.list_replies(
	user_account_id bigint,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_comment_page_result
LANGUAGE SQL AS $func$
	SELECT
		reply.id,
		reply.date_created,
		reply.text,
		reply.article_id,
		reply.article_title,
		reply.article_slug,
		reply.user_account_id,
		reply.user_account,
		reply.parent_comment_id,
		reply.date_read,
		count(*) OVER() AS total_count
	FROM
		article_api.user_comment AS reply
		JOIN comment AS parent ON reply.parent_comment_id = parent.id
	WHERE parent.user_account_id = list_replies.user_account_id
	ORDER BY reply.date_created DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;