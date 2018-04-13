CREATE TABLE source (
	id 				uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	name			varchar(256),
	url				varchar(256)	NOT NULL,
	hostname		varchar(256)	NOT NULL 	UNIQUE,
	slug			varchar(256)	NOT NULL 	UNIQUE,
	parser	text
);