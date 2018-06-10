CREATE FUNCTION user_account_api.update_notification_preferences(
	user_account_id bigint,
	receive_reply_email_notifications boolean,
	receive_reply_desktop_notifications boolean
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $func$
BEGIN
	UPDATE user_account
	SET
		receive_reply_email_notifications = update_notification_preferences.receive_reply_email_notifications,
		receive_reply_desktop_notifications = update_notification_preferences.receive_reply_desktop_notifications
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$func$;