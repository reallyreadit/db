CREATE FUNCTION user_account_api.create_user_account(
	name 			text,
	email 			text,
	password_hash	bytea,
	password_salt	bytea
) RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql AS $func$
DECLARE
	user_account_id uuid;
BEGIN
	INSERT INTO user_account (name, email, password_hash, password_salt)
		VALUES (trim(name), trim(email), password_hash, password_salt)
		RETURNING id INTO user_account_id;
	RETURN QUERY SELECT
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
		FROM user_account_api.user_account WHERE id = user_account_id;
END;
$func$;