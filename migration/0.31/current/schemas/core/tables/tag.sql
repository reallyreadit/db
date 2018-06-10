CREATE TABLE tag (
	id 		bigserial	PRIMARY KEY,
	name	text		NOT NULL	UNIQUE
);