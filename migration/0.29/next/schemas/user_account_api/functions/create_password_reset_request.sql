CREATE FUNCTION user_account_api.create_password_reset_request(
	user_account_id bigint
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	INSERT INTO password_reset_request (user_account_id, email_address)
		VALUES (user_account_id, (SELECT email FROM user_account WHERE id = user_account_id))
		RETURNING *;
$func$;