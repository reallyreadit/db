CREATE FUNCTION article_api.create_email_share(
	date_sent timestamp,
	article_id bigint,
	user_account_id bigint,
	message text,
	recipient_addresses text[],
	recipient_ids bigint[],
	recipient_results boolean[]
) RETURNS bigint
LANGUAGE plpgsql AS $func$
DECLARE
	email_share_id bigint;
BEGIN
	INSERT INTO email_share (date_sent, article_id, user_account_id, message)
		VALUES (date_sent, article_id, user_account_id, message)
		RETURNING id INTO email_share_id;
	FOR i IN 1..coalesce(array_length(recipient_addresses, 1), 0) LOOP
		INSERT INTO email_share_recipient
				(email_share_id, email_address, user_account_id, is_successful)
			VALUES (
				email_share_id,
				recipient_addresses[i],
				nullif(recipient_ids[i], 0),
				recipient_results[i]
			);
	END LOOP;
	RETURN email_share_id;
END;
$func$;