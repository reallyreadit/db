CREATE VIEW challenge_api.latest_challenge_response AS
SELECT
	cr_left.id,
	cr_left.challenge_id,
	cr_left.user_account_id,
	cr_left.date,
	cr_left.action,
	cr_left.time_zone_id,
	cr_left.time_zone_name
FROM
	challenge_api.challenge_response AS cr_left
	LEFT JOIN challenge_response AS cr_right ON (
		cr_right.challenge_id = cr_left.challenge_id AND
		cr_right.user_account_id = cr_left.user_account_id AND
		cr_right.date > cr_left.date
	)
WHERE cr_right.id IS NULL;