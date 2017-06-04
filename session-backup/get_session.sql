CREATE FUNCTION get_session(session_key	bytea) RETURNS SETOF session
LANGUAGE SQL AS $func$
	SELECT id, user_account_id, begin_date, end_date FROM session WHERE session.id = session_key;
$func$;