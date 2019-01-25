CREATE TABLE challenge_response (
	id bigserial PRIMARY KEY,
	challenge_id bigint NOT NULL REFERENCES challenge (id),
	user_account_id bigint NOT NULL REFERENCES user_account (id),
	date timestamp NOT NULL DEFAULT utc_now(),
	action challenge_response_action NOT NULL,
	time_zone_id bigint REFERENCES time_zone (id)
);