CREATE FUNCTION end_session(session_key bytea) RETURNS void
LANGUAGE SQL AS $func$
	UPDATE session SET end_date = utc_now() WHERE session.id = session_key;
$func$