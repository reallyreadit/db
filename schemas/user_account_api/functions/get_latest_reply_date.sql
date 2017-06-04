CREATE FUNCTION user_account_api.get_latest_reply_date(user_account_id uuid) RETURNS timestamp
LANGUAGE SQL AS $func$
	SELECT MAX(reply.date_created) FROM comment reply
		JOIN comment parent ON reply.parent_comment_id = parent.id
		JOIN user_account ON parent.user_account_id = user_account.id
		WHERE user_account.id = get_latest_reply_date.user_account_id;
$func$;