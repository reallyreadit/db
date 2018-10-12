CREATE FUNCTION user_account_api.create_user_account(
	name 			text,
	email 			text,
	password_hash	bytea,
	password_salt	bytea
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $func$
DECLARE
	user_account_id bigint;
BEGIN
	INSERT INTO user_account (name, email, password_hash, password_salt)
		VALUES (trim(name), trim(email), password_hash, password_salt)
		RETURNING id INTO user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$func$;