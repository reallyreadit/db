CREATE FUNCTION challenge_api.get_latest_challenge_response(
	challenge_id bigint,
	user_account_id bigint
)
RETURNS SETOF challenge_api.challenge_response
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM challenge_api.latest_challenge_response lcr
	WHERE
		lcr.challenge_id = get_latest_challenge_response.challenge_id AND
		lcr.user_account_id = get_latest_challenge_response.user_account_id;
$func$;