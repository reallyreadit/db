CREATE FUNCTION article_api.find_user_article(
	slug text,
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_user_articles(
		user_account_id,
		(SELECT id FROM article WHERE slug = find_user_article.slug)
	);
$func$;