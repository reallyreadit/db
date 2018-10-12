CREATE FUNCTION article_api.unstar_article(
	user_account_id bigint,
	article_id bigint
) RETURNS void
LANGUAGE SQL AS $func$
	DELETE FROM star WHERE
		user_account_id = unstar_article.user_account_id AND
		article_id = unstar_article.article_id;
$func$;