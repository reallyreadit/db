CREATE FUNCTION user_account_api.confirm_email_address(email_confirmation_id bigint) RETURNS boolean
LANGUAGE plpgsql AS $func$
DECLARE
	rows_updated int;
BEGIN
	UPDATE email_confirmation SET date_confirmed = utc_now() WHERE id = email_confirmation_id AND date_confirmed IS NULL;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	RETURN rows_updated = 1;
END;
$func$;