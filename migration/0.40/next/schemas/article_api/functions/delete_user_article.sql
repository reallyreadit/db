CREATE FUNCTION article_api.delete_user_article(
	article_id bigint,
	user_account_id bigint
)
RETURNS VOID
LANGUAGE SQL
AS $func$
	DELETE FROM user_page
	WHERE (
		page_id IN (
			SELECT id
			FROM page
			WHERE page.article_id = delete_user_article.article_id
		) AND
		user_page.user_account_id = delete_user_article.user_account_id
	);
$func$;