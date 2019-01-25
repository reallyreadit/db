CREATE VIEW challenge_api.challenge_response AS
SELECT
	challenge_response.id,
	challenge_response.challenge_id,
	challenge_response.user_account_id,
	challenge_response.date,
	challenge_response.action,
	challenge_response.time_zone_id,
	time_zone.name AS time_zone_name
FROM
	challenge_response
	LEFT JOIN time_zone ON time_zone.id = challenge_response.time_zone_id;