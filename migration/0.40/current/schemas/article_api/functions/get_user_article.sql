CREATE FUNCTION article_api.get_user_article(
	article_id bigint,
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT *
	FROM article_api.user_article
	WHERE
		id = article_id AND
		user_account_id = get_user_article.user_account_id;
$func$;