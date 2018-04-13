CREATE TABLE article_tag (
	article_id	uuid	NOT NULL	REFERENCES article,
	tag_id		uuid	NOT NULL	REFERENCES tag,
	PRIMARY KEY(article_id, tag_id)
);