SELECT
	name,
	email,
	receive_reply_email_notifications,
	receive_reply_desktop_notifications,
	date_created,
	role,
	receive_website_updates,
	receive_suggested_readings,
	is_email_confirmed,
	time_zone_id,
	time_zone_name
FROM user_account_api.user_account ORDER BY date_created DESC;