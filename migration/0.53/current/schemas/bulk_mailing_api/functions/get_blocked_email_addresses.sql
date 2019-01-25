CREATE FUNCTION bulk_mailing_api.get_blocked_email_addresses()
RETURNS SETOF text
LANGUAGE SQL
STABLE
AS $func$
	SELECT DISTINCT lower(recipient->>'email_address')
	FROM (
		SELECT jsonb_array_elements(bounce->'bounced_recipients')
		FROM email_notification
		UNION ALL
		SELECT jsonb_array_elements(complaint->'complained_recipients')
		FROM email_notification
	) AS row (recipient);
$func$;