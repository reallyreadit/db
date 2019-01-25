CREATE FUNCTION user_account_api.get_latest_unread_reply(user_account_id bigint) RETURNS SETOF article_api.user_comment
LANGUAGE SQL AS $func$
	SELECT reply.* FROM article_api.user_comment reply
		JOIN comment parent ON reply.parent_comment_id = parent.id AND reply.user_account_id != parent.user_account_id
		JOIN user_account ON parent.user_account_id = user_account.id
		WHERE user_account.id = get_latest_unread_reply.user_account_id AND reply.date_read IS NULL
		ORDER BY reply.date_created DESC
		LIMIT 1;
$func$;