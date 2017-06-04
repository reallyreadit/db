CREATE TABLE comment (
	id 					uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_created		timestamp		NOT NULL	DEFAULT utc_now(),
	text				text			NOT NULL,
	article_id			uuid			NOT NULL	REFERENCES article,
	user_account_id		uuid			NOT NULL	REFERENCES user_account,
	parent_comment_id	uuid 						REFERENCES comment,
	date_read			timestamp
);