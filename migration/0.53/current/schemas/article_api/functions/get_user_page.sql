CREATE FUNCTION article_api.get_user_page(
	page_id bigint,
	user_account_id bigint
)
RETURNS SETOF user_page
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM user_page
	WHERE (
		page_id = get_user_page.page_id AND
		user_account_id = get_user_page.user_account_id
	);
$func$;