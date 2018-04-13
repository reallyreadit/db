CREATE TABLE page (
	id 					uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	article_id			uuid			NOT NULL	REFERENCES article,
	number				int				NOT NULL,
	word_count			int				NOT NULL,
	readable_word_count	int				NOT NULL,
	url					varchar(256)	NOT NULL
);