CREATE OR REPLACE FUNCTION challenge_api.get_challenge_winners(
	challenge_id bigint
)
RETURNS TABLE (
	name text,
	email text,
	date_awarded timestamp
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		ua.name,
		ua.email,
		ca.date_awarded
	FROM
		challenge_award ca
		JOIN user_account ua ON ca.user_account_id = ua.id
	WHERE ca.challenge_id = get_challenge_winners.challenge_id
	ORDER BY ca.date_awarded;
$func$;