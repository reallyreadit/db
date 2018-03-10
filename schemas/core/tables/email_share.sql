CREATE TABLE email_share (
	id bigserial PRIMARY KEY,
	date_sent timestamp NOT NULL,
	article_id uuid NOT NULL REFERENCES article,
	user_account_id uuid NOT NULL REFERENCES user_account,
	message varchar(10000)
);