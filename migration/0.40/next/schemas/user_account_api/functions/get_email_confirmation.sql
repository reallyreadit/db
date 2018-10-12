CREATE FUNCTION user_account_api.get_email_confirmation(email_confirmation_id bigint) RETURNS SETOF email_confirmation
LANGUAGE SQL AS $func$
	SELECT * FROM email_confirmation WHERE id = email_confirmation_id;
$func$;