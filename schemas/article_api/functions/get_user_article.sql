CREATE FUNCTION article_api.get_user_article(
	article_id uuid,
	user_account_id uuid
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT * FROM article_api.list_user_articles(user_account_id) WHERE id = article_id;
$func$;