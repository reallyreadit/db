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
DROP FUNCTION user_account_api.get_latest_email_confirmation(user_account_id uuid);
CREATE FUNCTION user_account_api.get_latest_unconfirmed_email_confirmation(
	user_account_id uuid
) RETURNS SETOF email_confirmation
LANGUAGE SQL AS $func$
	SELECT * FROM email_confirmation
		WHERE
			user_account_id = get_latest_unconfirmed_email_confirmation.user_account_id AND
			date_confirmed IS NULL
		ORDER BY date_created DESC
		LIMIT 1;
$func$;
CREATE FUNCTION user_account_api.is_email_address_confirmed(
	user_account_id uuid,
	email text
) RETURNS boolean
LANGUAGE SQL AS $func$
	SELECT EXISTS(
		SELECT 1 FROM email_confirmation WHERE
			user_account_id = is_email_address_confirmed.user_account_id AND
			lower(email_address) = lower(email) AND
			date_confirmed IS NOT NULL
	);
$func$;
CREATE FUNCTION user_account_api.change_email_address(
	user_account_id uuid,
	email text
) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE user_account
		SET email = change_email_address.email
		WHERE id = user_account_id;
$func$;