CREATE FUNCTION user_account_api.get_user_account_using_old_id(
	user_account_id uuid
)
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $func$
	SELECT user_account.*
	FROM user_account_api.user_account
	JOIN id_migration.user_account AS lookup ON (
		lookup.new_id = user_account.id AND
		lookup.old_id = get_user_account_using_old_id.user_account_id
	);
$func$;