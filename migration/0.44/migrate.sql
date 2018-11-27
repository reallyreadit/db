-- migrate pizza challenge time zone info
WITH latest_time_zone_selection AS (
	SELECT
		cr1.user_account_id,
		cr1.time_zone_id
	FROM
		challenge_response AS cr1
		LEFT JOIN challenge_response AS cr2
			ON (
				cr1.user_account_id = cr2.user_account_id AND
				cr1.challenge_id = cr2.challenge_id AND
				cr2.date > cr1.date
			)
		WHERE cr2.id IS NULL
)
UPDATE user_account
SET time_zone_id = selection.time_zone_id
FROM latest_time_zone_selection AS selection
WHERE user_account.id = selection.user_account_id;

-- new create_user_account function
DROP FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea
);
CREATE FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $func$
DECLARE
	user_account_id bigint;
BEGIN
	INSERT INTO user_account (name, email, password_hash, password_salt, time_zone_id)
		VALUES (trim(name), trim(email), password_hash, password_salt, time_zone_id)
		RETURNING id INTO user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$func$;