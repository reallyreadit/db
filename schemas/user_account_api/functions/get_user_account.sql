CREATE FUNCTION user_account_api.get_user_account(user_account_id uuid) RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT * FROM user_account_api.user_account WHERE id = user_account_id;
$func$;