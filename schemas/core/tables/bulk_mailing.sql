CREATE TABLE bulk_mailing (
	id 					uuid		PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_sent			timestamp	NOT NULL	DEFAULT utc_now(),
	subject				text		NOT NULL,
	body				text		NOT NULL,
	list				text		NOT NULL,
	user_account_id		uuid		NOT NULL	REFERENCES user_account
);