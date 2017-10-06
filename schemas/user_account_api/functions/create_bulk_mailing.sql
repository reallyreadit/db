CREATE FUNCTION user_account_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipient_ids uuid[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	bulk_mailing_id	uuid;
	recipient_id	uuid;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOREACH recipient_id IN ARRAY recipient_ids
	LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id)
			VALUES (bulk_mailing_id, recipient_id);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$func$;