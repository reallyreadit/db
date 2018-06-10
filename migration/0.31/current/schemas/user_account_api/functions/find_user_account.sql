CREATE FUNCTION user_account_api.find_user_account(email text) RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE lower(email) = lower(find_user_account.email);
$func$;