CREATE VIEW challenge_api.challenge AS
SELECT
	challenge.id,
	challenge.name,
	challenge.start_date,
	challenge.end_date,
	challenge.award_limit,
	count(challenge_award.*) AS award_count
FROM
	challenge
	LEFT JOIN challenge_award ON challenge_award.challenge_id = challenge.ID
GROUP BY
	challenge.id;