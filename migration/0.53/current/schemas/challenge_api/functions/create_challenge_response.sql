CREATE FUNCTION challenge_api.create_challenge_response(
	challenge_id bigint,
	user_account_id bigint,
	action challenge_response_action,
	time_zone_id bigint
)
RETURNS SETOF challenge_api.challenge_response
LANGUAGE plpgsql
AS $func$
DECLARE
	challenge_response_id bigint;
BEGIN
	INSERT INTO challenge_response (
		challenge_id,
		user_account_id,
		action,
		time_zone_id
	)
	VALUES (
		create_challenge_response.challenge_id,
		create_challenge_response.user_account_id,
		create_challenge_response.action,
		create_challenge_response.time_zone_id
	)
	RETURNING id INTO challenge_response_id;
	RETURN QUERY
	SELECT *
	FROM challenge_api.challenge_response
	WHERE id = challenge_response_id;
END;
$func$;