CREATE TABLE article (
	id 				bigserial		PRIMARY KEY,
	title			varchar(512)	NOT NULL,
	slug			varchar(256)	NOT NULL	UNIQUE,
	source_id		bigint			NOT NULL	REFERENCES source,
	date_published	timestamp,
	date_modified	timestamp,
	section			varchar(256),
	description		text,
	aotd_timestamp	timestamp,
	score			int				NOT NULL 	DEFAULT 0
);
CREATE INDEX article_aotd_timestamp_idx ON article (aotd_timestamp DESC NULLS LAST);
CREATE INDEX article_score_idx ON article (score DESC);