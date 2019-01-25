CREATE FUNCTION stats_api.get_current_streak_leaderboard(
	user_account_id bigint,
	max_count int
)
RETURNS TABLE (
	name text,
	streak bigint
)
LANGUAGE SQL
STABLE
AS $func$
	SELECT
		name,
		streak
	FROM
		(
			SELECT
				id,
				name,
				streak
			FROM
				stats_api.current_streak
			WHERE
				id != coalesce(get_current_streak_leaderboard.user_account_id, 0)
			UNION ALL
			SELECT
				user_account.id,
				user_account.name,
				streak
			FROM
				user_account
				JOIN stats_api.get_current_streak(user_account.id) AS streak ON TRUE
			WHERE
				user_account.id = coalesce(get_current_streak_leaderboard.user_account_id, 0) AND
				streak > 0
		) AS updated_current_streak
	ORDER BY
		streak DESC,
		id
	LIMIT get_current_streak_leaderboard.max_count;
$func$;