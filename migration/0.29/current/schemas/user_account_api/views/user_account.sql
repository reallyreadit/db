CREATE VIEW user_account_api.user_account AS SELECT
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
	ec.date_confirmed IS NOT NULL AS is_email_confirmed
	FROM user_account
	LEFT JOIN email_confirmation ec ON ec.user_account_id = user_account.id
	LEFT JOIN email_confirmation ec1 ON ec1.user_account_id = user_account.id AND ec1.date_created > ec.date_created
	WHERE ec1.id IS NULL;