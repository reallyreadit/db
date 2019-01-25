CREATE FUNCTION stats_api.get_read_count_leaderboard(
	max_count int
)
RETURNS TABLE (
	name text,
	read_count bigint
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		user_account.name,
		count(*) AS read_count
	FROM
		user_page
		JOIN user_account ON user_page.user_account_id = user_account.id
	WHERE
		user_page.date_completed IS NOT NULL
	GROUP BY
		user_account.id
	ORDER BY
		read_count DESC
	LIMIT
		get_read_count_leaderboard.max_count;
$func$;