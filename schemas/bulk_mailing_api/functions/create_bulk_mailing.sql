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