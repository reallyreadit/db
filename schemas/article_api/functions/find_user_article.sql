CREATE FUNCTION article_api.find_user_article(
	slug text,
	user_account_id uuid DEFAULT NULL
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT * FROM article_api.list_user_articles(user_account_id) WHERE slug = find_user_article.slug;
$func$;