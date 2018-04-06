CREATE FUNCTION bulk_mailing_api.list_confirmation_reminder_recipients()
RETURNS SETOF user_account_api.user_account
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
	FROM
		bulk_mailing
		JOIN bulk_mailing_recipient recipient ON recipient.bulk_mailing_id = bulk_mailing.id
		JOIN user_account_api.user_account ON user_account.id = recipient.user_account_id
	WHERE
		bulk_mailing.list = 'ConfirmationReminder'
	GROUP BY
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
		user_account.is_email_confirmed;
$func$;