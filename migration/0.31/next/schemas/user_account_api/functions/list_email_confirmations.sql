CREATE FUNCTION user_account_api.list_email_confirmations(
	user_account_id bigint
) RETURNS SETOF email_confirmation
LANGUAGE SQL AS $func$
	SELECT
		id,
		date_created,
		user_account_id,
		email_address,
		date_confirmed
	FROM
		email_confirmation
	WHERE
		user_account_id = list_email_confirmations.user_account_id
	ORDER BY date_created DESC;
$func$;