CREATE TABLE source (
	id 				bigserial		PRIMARY KEY,
	name			varchar(256),
	url				varchar(256)	NOT NULL,
	hostname		varchar(256)	NOT NULL 	UNIQUE,
	slug			varchar(256)	NOT NULL 	UNIQUE,
	parser	text
);