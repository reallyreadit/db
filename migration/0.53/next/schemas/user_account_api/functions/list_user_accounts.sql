CREATE FUNCTION user_account_api.list_user_accounts()
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM user_account_api.user_account;
$func$;