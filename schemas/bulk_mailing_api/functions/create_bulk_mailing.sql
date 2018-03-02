CREATE FUNCTION bulk_mailing_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipient_ids uuid[],
	recipient_results boolean[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	bulk_mailing_id uuid;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOR i IN 1..coalesce(array_length(recipient_ids, 1), 0) LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id, is_successful)
			VALUES (bulk_mailing_id, recipient_ids[i], recipient_results[i]);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$func$;