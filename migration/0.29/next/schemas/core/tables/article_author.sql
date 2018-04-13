CREATE TABLE article_author (
	article_id	bigint	NOT NULL	REFERENCES article,
	author_id	bigint	NOT NULL	REFERENCES author,
	PRIMARY KEY(article_id, author_id)
);