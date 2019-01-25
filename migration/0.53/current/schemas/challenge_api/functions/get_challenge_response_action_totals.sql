CREATE FUNCTION challenge_api.get_challenge_response_action_totals(
	challenge_id bigint
)
RETURNS TABLE (
	action challenge_response_action,
	count bigint
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		action,
		count(*)
	FROM challenge_response
	WHERE challenge_id = get_challenge_response_action_totals.challenge_id
	GROUP BY action
	ORDER BY action;
$func$;
