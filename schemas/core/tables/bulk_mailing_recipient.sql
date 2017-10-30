CREATE TABLE bulk_mailing_recipient (
	bulk_mailing_id	uuid	NOT NULL	REFERENCES bulk_mailing,
	user_account_id	uuid	NOT NULL	REFERENCES user_account,
	is_successful	boolean	NOT NULL,
	PRIMARY KEY(bulk_mailing_id, user_account_id)
);