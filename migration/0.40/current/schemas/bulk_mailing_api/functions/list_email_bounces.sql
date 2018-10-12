CREATE FUNCTION bulk_mailing_api.list_email_bounces() RETURNS SETOF email_bounce
LANGUAGE SQL AS $func$
	SELECT
		id,
		date_received,
		address,
		message,
		bulk_mailing_id
	FROM email_bounce;
$func$;