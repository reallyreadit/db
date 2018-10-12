CREATE FUNCTION article_api.find_user_article(
	slug text,
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT *
	FROM article_api.user_article
	WHERE
		slug = find_user_article.slug AND
		user_account_id = find_user_article.user_account_id;
$func$;