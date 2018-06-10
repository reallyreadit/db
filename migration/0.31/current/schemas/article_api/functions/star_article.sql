CREATE FUNCTION article_api.star_article(
	user_account_id bigint,
	article_id bigint
) RETURNS void
LANGUAGE SQL AS $func$
	INSERT INTO star (user_account_id, article_id) VALUES (user_account_id, article_id);
$func$;