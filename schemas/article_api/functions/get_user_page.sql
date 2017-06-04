CREATE FUNCTION article_api.get_user_page(page_id uuid, user_account_id uuid) RETURNS SETOF user_page
LANGUAGE SQL AS $func$
	SELECT * FROM user_page WHERE
		page_id = get_user_page.page_id AND
		user_account_id = get_user_page.user_account_id;
$func$;