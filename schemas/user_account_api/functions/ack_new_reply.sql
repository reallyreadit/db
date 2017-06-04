CREATE FUNCTION user_account_api.ack_new_reply(user_account_id uuid) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE user_account SET last_new_reply_ack = utc_now() WHERE id = user_account_id;
$func$;