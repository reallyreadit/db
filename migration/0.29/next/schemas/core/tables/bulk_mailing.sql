CREATE TABLE bulk_mailing (
	id 					bigserial	PRIMARY KEY,
	date_sent			timestamp	NOT NULL	DEFAULT utc_now(),
	subject				text		NOT NULL,
	body				text		NOT NULL,
	list				text		NOT NULL,
	user_account_id		bigint		NOT NULL	REFERENCES user_account
);