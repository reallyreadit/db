CREATE FUNCTION article_api.get_user_article(
	article_id bigint,
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_user_articles(
		user_account_id,
		article_id
	);
$func$;