CREATE TABLE article_tag (
	article_id	bigint	NOT NULL	REFERENCES article,
	tag_id		bigint	NOT NULL	REFERENCES tag,
	PRIMARY KEY(article_id, tag_id)
);