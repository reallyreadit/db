CREATE FUNCTION bulk_mailing_api.create_email_notification(
	notification_type text,
    mail text,
	bounce text,
	complaint text
)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO email_notification
        (notification_type, mail, bounce, complaint)
    VALUES
		(notification_type, mail::json, bounce::json, complaint::json);
$func$;