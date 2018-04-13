CREATE FUNCTION user_account_api.get_latest_password_reset_request(
	user_account_id uuid
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	SELECT * FROM password_reset_request
		WHERE user_account_id = get_latest_password_reset_request.user_account_id
		ORDER BY date_created DESC
		LIMIT 1;
$func$;