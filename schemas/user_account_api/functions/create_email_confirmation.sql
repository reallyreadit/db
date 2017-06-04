CREATE FUNCTION user_account_api.create_email_confirmation(user_account_id uuid) RETURNS SETOF email_confirmation
LANGUAGE SQL AS $func$
	INSERT INTO email_confirmation (user_account_id, email_address)
		VALUES (user_account_id, (SELECT email FROM user_account WHERE id = user_account_id))
		RETURNING *;
$func$;