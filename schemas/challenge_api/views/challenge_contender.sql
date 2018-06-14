CREATE MATERIALIZED VIEW challenge_api.challenge_contender AS
WITH contender AS (
	SELECT
		c.id AS challenge_id,
		lcr.user_account_id
	FROM
		challenge c
		JOIN challenge_api.latest_challenge_response lcr ON
			c.id = lcr.challenge_id
		LEFT JOIN challenge_award ca ON
			c.id = ca.challenge_id AND
			lcr.user_account_id = ca.user_account_id
	WHERE
		tsrange(c.start_date, c.end_date) @> utc_now() AND
		lcr.action = 'enroll' AND
		ca.id IS NULL
)
SELECT
	c.challenge_id,
	ua.name,
	score.*
FROM
	contender c
	JOIN user_account ua ON c.user_account_id = ua.id
	JOIN LATERAL challenge_api.get_challenge_score(c.challenge_id, ua.id) score ON TRUE
WHERE score.day > 0
ORDER BY score.level DESC, score.day, ua.name;