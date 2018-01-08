CREATE TABLE email_bounce (
	id 				uuid		PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_received	timestamp	NOT NULL,
	address			text		NOT NULL,
	message			text		NOT NULL,
	bulk_mailing_id	uuid		REFERENCES bulk_mailing
);
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