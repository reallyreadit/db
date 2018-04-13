CREATE TABLE article (
	id 				uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	title			varchar(512)	NOT NULL,
	slug			varchar(256)	NOT NULL	UNIQUE,
	source_id		uuid			NOT NULL	REFERENCES source,
	date_published	timestamp,
	date_modified	timestamp,
	section			varchar(256),
	description		text,
	aotd_timestamp	timestamp,
	score			int				NOT NULL 	DEFAULT 0
);