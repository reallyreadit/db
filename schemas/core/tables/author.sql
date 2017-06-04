CREATE TABLE author (
	id 		uuid	PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	name	text	NOT NULL,
	url		text
);