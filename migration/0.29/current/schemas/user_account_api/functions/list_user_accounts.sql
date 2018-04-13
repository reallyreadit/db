CREATE FUNCTION user_account_api.list_user_accounts() RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT
		id,
		name,
		email,
		password_hash,
		password_salt,
		receive_reply_email_notifications,
		receive_reply_desktop_notifications,
		last_new_reply_ack,
		last_new_reply_desktop_notification,
		date_created,
		role,
		receive_website_updates,
		receive_suggested_readings,
		is_email_confirmed
		FROM user_account_api.user_account;
$func$;