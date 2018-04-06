DROP FUNCTION user_account_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipient_ids uuid[]
);
DROP FUNCTION user_account_api.list_bulk_mailings();
ALTER TABLE bulk_mailing_recipient ADD COLUMN is_successful boolean NOT NULL;
CREATE SCHEMA bulk_mailing_api;
CREATE TYPE bulk_mailing_api.create_bulk_mailing_recipient AS (
	user_account_id	uuid,
	is_successful	boolean
);
CREATE FUNCTION bulk_mailing_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipients bulk_mailing_api.create_bulk_mailing_recipient[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	bulk_mailing_id	uuid;
	recipient		bulk_mailing_api.create_bulk_mailing_recipient;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOREACH recipient IN ARRAY recipients
	LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id, is_successful)
			VALUES (bulk_mailing_id, recipient.user_account_id, recipient.is_successful);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$func$;
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