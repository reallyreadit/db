CREATE FUNCTION bulk_mailing_api.list_bulk_mailings() RETURNS TABLE(
	id uuid,
	date_sent timestamp,
	subject text,
	body text,
	list text,
	user_account text,
	recipient_count bigint,
	error_count bigint
)
LANGUAGE SQL AS $func$
	SELECT
		bulk_mailing.id,
		bulk_mailing.date_sent,
		bulk_mailing.subject,
		bulk_mailing.body,
		bulk_mailing.list,
		user_account.name AS user_account,
		count(*) AS recipient_count,
		count(*) FILTER (WHERE NOT bulk_mailing_recipient.is_successful) AS error_count
		FROM bulk_mailing
		JOIN user_account ON bulk_mailing.user_account_id = user_account.id
		JOIN bulk_mailing_recipient ON bulk_mailing.id = bulk_mailing_recipient.bulk_mailing_id
		GROUP BY bulk_mailing.id, user_account.id;
$func$;