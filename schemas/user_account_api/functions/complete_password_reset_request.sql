CREATE FUNCTION user_account_api.complete_password_reset_request(
	password_reset_request_id uuid
) RETURNS boolean
LANGUAGE plpgsql AS $func$
DECLARE
	rows_updated int;
BEGIN
	UPDATE password_reset_request
		SET date_completed = utc_now()
		WHERE id = password_reset_request_id AND date_completed IS NULL;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	RETURN rows_updated = 1;
END;
$func$;