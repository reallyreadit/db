CREATE FUNCTION user_account_api.change_password(
	user_account_id uuid,
	password_hash bytea,
	password_salt bytea
) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE user_account
		SET
			password_hash = change_password.password_hash,
			password_salt = change_password.password_salt
		WHERE id = user_account_id;
$func$;