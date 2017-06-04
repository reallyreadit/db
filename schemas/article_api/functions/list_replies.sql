CREATE FUNCTION article_api.list_replies(user_account_id uuid) RETURNS SETOF article_api.user_comment
LANGUAGE SQL AS $func$
	SELECT reply.* FROM article_api.user_comment reply
		JOIN comment parent ON reply.parent_comment_id = parent.id
		WHERE parent.user_account_id = list_replies.user_account_id
		ORDER BY reply.date_created DESC;
$func$;