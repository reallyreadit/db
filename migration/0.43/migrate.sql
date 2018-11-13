DROP FUNCTION stats_api.get_user_weekly_read_stats(
	user_account_id bigint
);
DROP FUNCTION stats_api.get_weekly_read_count_leaderboard(
	max_count int
);
DROP FUNCTION stats_api.get_weekly_word_count_leaderboard(
	max_count int
);

CREATE FUNCTION stats_api.get_user_read_stats(
	user_account_id bigint
)
RETURNS TABLE (
	user_account_id bigint,
	user_count bigint,
	read_count bigint,
	read_count_rank bigint
)
LANGUAGE SQL
STABLE
AS $func$
	WITH ranking AS (
		SELECT
			user_account_id,
			(
				SELECT count(*)
				FROM user_account
			) AS user_count,
			count(*) AS read_count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS read_count_rank
		FROM
			user_page
		WHERE
			date_completed IS NOT NULL
		GROUP BY
			user_account_id
	)
	SELECT *
	FROM ranking
	WHERE user_account_id = get_user_read_stats.user_account_id;
$func$;

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