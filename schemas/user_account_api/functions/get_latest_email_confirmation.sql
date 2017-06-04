CREATE FUNCTION user_account_api.get_latest_email_confirmation(user_account_id uuid) RETURNS SETOF email_confirmation
LANGUAGE SQL AS $func$
	SELECT * FROM email_confirmation
		WHERE user_account_id = get_latest_email_confirmation.user_account_id
		ORDER BY date_created DESC
		LIMIT 1;
$func$;