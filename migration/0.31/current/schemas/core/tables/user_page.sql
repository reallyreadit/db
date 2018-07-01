CREATE TABLE user_page (
	id 					bigserial			PRIMARY KEY,
	page_id				bigint				NOT NULL	REFERENCES page,
	user_account_id		bigint				NOT NULL 	REFERENCES user_account,
	date_created		timestamp			NOT NULL	DEFAULT utc_now(),
	last_modified		timestamp,
	read_state			int[]				NOT NULL,
	words_read			int					NOT NULL	DEFAULT 0
);