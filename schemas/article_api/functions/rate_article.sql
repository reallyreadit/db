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