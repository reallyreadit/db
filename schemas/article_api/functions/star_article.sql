CREATE FUNCTION article_api.star_article(
	user_account_id uuid,
	article_id uuid
) RETURNS void
LANGUAGE SQL AS $func$
	INSERT INTO star (user_account_id, article_id) VALUES (user_account_id, article_id);
$func$;