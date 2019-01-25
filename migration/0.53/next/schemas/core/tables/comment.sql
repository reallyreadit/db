CREATE TABLE comment (
	id 					bigserial		PRIMARY KEY,
	date_created		timestamp		NOT NULL	DEFAULT utc_now(),
	text				text			NOT NULL,
	article_id			bigint			NOT NULL	REFERENCES article,
	user_account_id		bigint			NOT NULL	REFERENCES user_account,
	parent_comment_id	bigint 						REFERENCES comment,
	date_read			timestamp
);
CREATE INDEX comment_article_id_idx ON comment(article_id);