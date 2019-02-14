CREATE DOMAIN rating_score
AS int
CHECK (
    VALUE >= 1 AND
    VALUE <= 10
);
CREATE TABLE rating (
	id bigserial PRIMARY KEY,
	timestamp timestamp NOT NULL DEFAULT utc_now(),
	score rating_score NOT NULL,
	article_id bigint NOT NULL REFERENCES article (id),
	user_account_id bigint NOT NULL REFERENCES user_account (id)
);
CREATE FUNCTION article_api.rate_article(
	article_id bigint,
	user_account_id bigint,
	score rating_score
)
RETURNS SETOF rating
LANGUAGE SQL
STRICT
AS $$
	INSERT INTO rating (score, article_id, user_account_id)
	VALUES (score, article_id, user_account_id)
	RETURNING *;
$$;