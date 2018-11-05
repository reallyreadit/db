CREATE FUNCTION stats_api.get_weekly_word_count_leaderboard(
	max_count int
)
RETURNS TABLE (
	name text,
	word_count bigint
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		user_account.name,
		sum(words_read) AS word_count
	FROM
		user_page
		JOIN user_account ON user_page.user_account_id = user_account.id
	WHERE
		user_page.date_completed > (utc_now() - '1 week'::interval)
	GROUP BY
		user_account.id
	ORDER BY
		word_count DESC
	LIMIT
		get_weekly_word_count_leaderboard.max_count;
$func$;