CREATE TABLE source_rule (
	id 			uuid				PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	hostname	varchar(256)		NOT NULL,
	path		varchar(256)		NOT NULL,
	priority	int					NOT NULL	DEFAULT 0,
	action		source_rule_action	NOT NULL
);