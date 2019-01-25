CREATE FUNCTION challenge_api.get_challenge_contenders(
	challenge_id bigint
)
RETURNS TABLE (
	name text,
	day int,
	level int
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		c.name,
		c.day,
		c.level
	FROM challenge_api.challenge_contender c
	WHERE c.challenge_id = get_challenge_contenders.challenge_id
	ORDER BY c.level DESC, c.day, c.name;;
$func$;