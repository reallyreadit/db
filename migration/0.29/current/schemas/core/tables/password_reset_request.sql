CREATE TABLE password_reset_request (
	id 				uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_created	timestamp		NOT NULL	DEFAULT utc_now(),
	user_account_id	uuid			NOT NULL	REFERENCES user_account,
	email_address	text			NOT NULL,
	date_completed	timestamp
);