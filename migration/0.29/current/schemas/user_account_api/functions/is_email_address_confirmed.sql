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