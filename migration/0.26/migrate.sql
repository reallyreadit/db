CREATE TABLE email_share (
	id bigserial PRIMARY KEY,
	date_sent timestamp NOT NULL,
	article_id uuid NOT NULL REFERENCES article,
	user_account_id uuid NOT NULL REFERENCES user_account,
	message varchar(10000)
);
CREATE TABLE email_share_recipient (
	id bigserial PRIMARY KEY,
	email_share_id bigint NOT NULL REFERENCES email_share,
	email_address varchar(256) NOT NULL,
	user_account_id uuid REFERENCES user_account,
	is_successful boolean NOT NULL
);
CREATE FUNCTION article_api.create_email_share(
	date_sent timestamp,
	article_id uuid,
	user_account_id uuid,
	message text,
	recipient_addresses text[],
	recipient_ids uuid[],
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
				nullif(recipient_ids[i], '00000000-0000-0000-0000-000000000000'),
				recipient_results[i]
			);
	END LOOP;
	RETURN email_share_id;
END;
$func$;