CREATE FUNCTION create_session(user_account_id uuid) RETURNS session
LANGUAGE plpgsql AS $func$
DECLARE
	session_key			bytea := pgcrypto.gen_random_bytes(16);
	session_begin_date	timestamp;
	session_end_date	timestamp;
	ex_constraint		text;
BEGIN
	INSERT INTO session (id, user_account_id) VALUES (session_key, user_account_id)
		RETURNING begin_date, end_date INTO session_begin_date, session_end_date;
	RETURN ROW(session_key, user_account_id, session_begin_date, session_end_date);
	EXCEPTION WHEN unique_violation THEN
		GET STACKED DIAGNOSTICS ex_constraint = CONSTRAINT_NAME;
		IF ex_constraint = 'session_pkey' THEN
			RETURN create_session(user_account_id);
		END IF;
END
$func$;