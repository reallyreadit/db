CREATE FUNCTION user_account_api.change_email_address(
	user_account_id bigint,
	email text
) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE user_account
		SET email = change_email_address.email
		WHERE id = user_account_id;
$func$;