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
	WITH contender AS (
		SELECT
			lcr.user_account_id
		FROM
			challenge_api.latest_challenge_response lcr
			LEFT JOIN challenge_award ca ON
				lcr.challenge_id = ca.challenge_id AND
				lcr.user_account_id = ca.user_account_id
		WHERE
			lcr.challenge_id = get_challenge_contenders.challenge_id AND
			lcr.action = 'enroll' AND
			ca.id IS NULL
	)
	SELECT
		ua.name,
		score.*
	FROM
		contender c
		JOIN user_account ua ON c.user_account_id = ua.id
		JOIN LATERAL challenge_api.get_challenge_score(1, ua.id) score ON TRUE
	WHERE score.day > 0
	ORDER BY score.level DESC, score.day, ua.name;
$func$;