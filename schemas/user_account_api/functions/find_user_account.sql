CREATE FUNCTION user_account_api.find_user_account(email text) RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT * FROM user_account_api.user_account WHERE email = find_user_account.email;
$func$;