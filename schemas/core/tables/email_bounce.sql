CREATE TABLE email_bounce (
	id 				uuid		PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_received	timestamp	NOT NULL,
	address			text		NOT NULL,
	message			text		NOT NULL,
	bulk_mailing_id	uuid		REFERENCES bulk_mailing
);