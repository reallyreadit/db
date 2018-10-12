CREATE FUNCTION user_account_api.update_contact_preferences(
	user_account_id bigint,
	receive_website_updates boolean,
	receive_suggested_readings boolean
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $func$
BEGIN
	UPDATE user_account
	SET
		receive_website_updates = update_contact_preferences.receive_website_updates,
		receive_suggested_readings = update_contact_preferences.receive_suggested_readings
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$func$;