CREATE TABLE page (
	id 					bigserial		PRIMARY KEY,
	article_id			bigint			NOT NULL	REFERENCES article,
	number				int				NOT NULL,
	word_count			int				NOT NULL,
	readable_word_count	int				NOT NULL,
	url					varchar(256)	NOT NULL
);