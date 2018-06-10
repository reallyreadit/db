CREATE TABLE star (
	user_account_id	bigint		NOT NULL	REFERENCES user_account,
	article_id		bigint		NOT NULL	REFERENCES article,
	date_starred	timestamp	NOT NULL	DEFAULT utc_now(),
	PRIMARY KEY(user_account_id, article_id)
);