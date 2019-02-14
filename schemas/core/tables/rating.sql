CREATE TABLE rating (
	id bigserial PRIMARY KEY,
	timestamp timestamp NOT NULL DEFAULT utc_now(),
	score rating_score NOT NULL,
	article_id bigint NOT NULL REFERENCES article (id),
	user_account_id bigint NOT NULL REFERENCES user_account (id)
);