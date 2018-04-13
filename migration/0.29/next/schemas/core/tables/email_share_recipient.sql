CREATE TABLE email_share_recipient (
	id bigserial PRIMARY KEY,
	email_share_id bigint NOT NULL REFERENCES email_share,
	email_address varchar(256) NOT NULL,
	user_account_id bigint REFERENCES user_account,
	is_successful boolean NOT NULL
);