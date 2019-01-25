CREATE VIEW user_account_api.user_account AS
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
	latest_email_confirmation.date_confirmed IS NOT NULL AS is_email_confirmed,
	user_account.time_zone_id,
	time_zone.name AS time_zone_name,
	time_zone.display_name AS time_zone_display_name
FROM
	user_account
	LEFT JOIN (
		SELECT
			ec_left.user_account_id,
			ec_left.date_confirmed
		FROM
			email_confirmation AS ec_left
			LEFT JOIN email_confirmation AS ec_right ON (
				ec_right.user_account_id = ec_left.user_account_id AND
				ec_right.date_created > ec_left.date_created
			)
		WHERE ec_right.id IS NULL
	) AS latest_email_confirmation ON latest_email_confirmation.user_account_id = user_account.id
	LEFT JOIN time_zone ON time_zone.id = user_account.time_zone_id;