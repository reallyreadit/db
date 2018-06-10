CREATE TABLE source_rule (
	id 			bigserial			PRIMARY KEY,
	hostname	varchar(256)		NOT NULL,
	path		varchar(256)		NOT NULL,
	priority	int					NOT NULL	DEFAULT 0,
	action		source_rule_action	NOT NULL
);