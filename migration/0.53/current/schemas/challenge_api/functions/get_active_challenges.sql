CREATE FUNCTION challenge_api.get_active_challenges()
RETURNS SETOF challenge_api.challenge
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM challenge_api.challenge
	WHERE tsrange(start_date, end_date) @> utc_now();
$func$;