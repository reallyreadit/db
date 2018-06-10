CREATE TABLE password_reset_request (
	id 				bigserial		PRIMARY KEY,
	date_created	timestamp		NOT NULL	DEFAULT utc_now(),
	user_account_id	bigint			NOT NULL	REFERENCES user_account,
	email_address	text			NOT NULL,
	date_completed	timestamp
);