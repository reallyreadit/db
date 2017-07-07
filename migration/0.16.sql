CREATE TABLE password_reset_request (
	id 				uuid			PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_created	timestamp		NOT NULL	DEFAULT utc_now(),
	user_account_id	uuid			NOT NULL	REFERENCES user_account,
	email_address	text			NOT NULL,
	date_completed	timestamp
);
CREATE FUNCTION user_account_api.create_password_reset_request(
	user_account_id uuid
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	INSERT INTO password_reset_request (user_account_id, email_address)
		VALUES (user_account_id, (SELECT email FROM user_account WHERE id = user_account_id))
		RETURNING *;
$func$;
CREATE FUNCTION user_account_api.get_password_reset_request(
	password_reset_request_id uuid
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	SELECT * FROM password_reset_request WHERE id = password_reset_request_id;
$func$;
CREATE FUNCTION user_account_api.get_latest_password_reset_request(
	user_account_id uuid
) RETURNS SETOF password_reset_request
LANGUAGE SQL AS $func$
	SELECT * FROM password_reset_request
		WHERE user_account_id = get_latest_password_reset_request.user_account_id
		ORDER BY date_created DESC
		LIMIT 1;
$func$;
CREATE FUNCTION user_account_api.complete_password_reset_request(
	password_reset_request_id uuid
) RETURNS boolean
LANGUAGE plpgsql AS $func$
DECLARE
	rows_updated int;
BEGIN
	UPDATE password_reset_request
		SET date_completed = utc_now()
		WHERE id = password_reset_request_id AND date_completed IS NULL;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	RETURN rows_updated = 1;
END;
$func$;