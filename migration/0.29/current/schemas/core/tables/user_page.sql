CREATE TABLE user_page (
	id 					uuid				PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	page_id				uuid				NOT NULL	REFERENCES page,
	user_account_id		uuid				NOT NULL 	REFERENCES user_account,
	date_created		timestamp			NOT NULL	DEFAULT utc_now(),
	last_modified		timestamp,
	read_state			int[]				NOT NULL,
	words_read			int					NOT NULL	DEFAULT 0
);