CREATE TABLE email_bounce (
	id 				bigserial	PRIMARY KEY,
	date_received	timestamp	NOT NULL,
	address			text		NOT NULL,
	message			text		NOT NULL,
	bulk_mailing_id	bigint		REFERENCES bulk_mailing
);