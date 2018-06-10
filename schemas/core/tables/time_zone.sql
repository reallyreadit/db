CREATE TABLE time_zone (
	id bigint PRIMARY KEY,
	name time_zone_name NOT NULL,
	display_name varchar(256) NOT NULL,
	territory varchar(3) NOT NULL,
	base_utc_offset interval HOUR TO SECOND NOT NULL,
	UNIQUE (name, territory)
);