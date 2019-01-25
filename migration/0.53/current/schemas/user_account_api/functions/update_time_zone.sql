CREATE FUNCTION user_account_api.update_time_zone(
	user_account_id bigint,
	time_zone_id bigint
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $func$
BEGIN
	UPDATE user_account
	SET time_zone_id = update_time_zone.time_zone_id
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$func$;