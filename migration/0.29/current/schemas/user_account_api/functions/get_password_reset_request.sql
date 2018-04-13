CREATE FUNCTION user_account_api.get_password_reset_request(
	password_reset_request_id uuid
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	SELECT * FROM password_reset_request WHERE id = password_reset_request_id;
$func$;