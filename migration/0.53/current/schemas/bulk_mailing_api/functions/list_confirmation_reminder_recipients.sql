CREATE FUNCTION bulk_mailing_api.list_confirmation_reminder_recipients()
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $func$
	SELECT
	DISTINCT ON (user_account.id)
		user_account.*
	FROM
		bulk_mailing
		JOIN bulk_mailing_recipient recipient ON recipient.bulk_mailing_id = bulk_mailing.id
		JOIN user_account_api.user_account ON user_account.id = recipient.user_account_id
	WHERE
		bulk_mailing.list = 'ConfirmationReminder';
$func$;