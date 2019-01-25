CREATE FUNCTION user_account_api.record_new_reply_desktop_notification(user_account_id bigint) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE user_account SET last_new_reply_desktop_notification = utc_now() WHERE id = user_account_id;
$func$;