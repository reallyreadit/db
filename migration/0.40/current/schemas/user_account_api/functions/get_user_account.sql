CREATE FUNCTION user_account_api.get_user_account(
	user_account_id bigint
)
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
$func$;