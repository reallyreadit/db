CREATE TABLE challenge_award (
	id bigserial PRIMARY KEY,
	challenge_id bigint NOT NULL REFERENCES challenge (id),
	user_account_id bigint NOT NULL REFERENCES user_account (id),
	date_awarded timestamp NOT NULL DEFAULT utc_now(),
	date_fulfilled timestamp,
	reference varchar(1024)
);