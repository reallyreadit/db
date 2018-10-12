CREATE TABLE challenge (
	id bigserial PRIMARY KEY,
	name varchar(256) NOT NULL,
	start_date timestamp NOT NULL,
	end_date timestamp,
	award_limit int NOT NULL
);