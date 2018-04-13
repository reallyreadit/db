CREATE TABLE article_author (
	article_id	uuid	NOT NULL	REFERENCES article,
	author_id	uuid	NOT NULL	REFERENCES author,
	PRIMARY KEY(article_id, author_id)
);