CREATE FUNCTION stats_api.get_user_stats(
	user_account_id bigint
)
RETURNS TABLE (
	read_count bigint,
	read_count_rank bigint,
	streak bigint,
	streak_rank bigint,
	user_count bigint
)
LANGUAGE SQL
STABLE
AS $func$
	WITH read_count_ranking AS (
		SELECT
			user_account_id,
			count(*) AS count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS rank
		FROM
			user_page
		WHERE
			date_completed IS NOT NULL
		GROUP BY
			user_account_id
	),
	streak_ranking AS (
		SELECT
			id AS user_account_id,
			streak,
			dense_rank() OVER (ORDER BY streak DESC) AS rank
		FROM
			(
				SELECT
					id,
					streak
				FROM
					stats_api.current_streak
				WHERE
					id != get_user_stats.user_account_id
				UNION ALL
				SELECT *
				FROM
					(
						SELECT
							get_user_stats.user_account_id AS id,
							stats_api.get_current_streak(
								get_user_stats.user_account_id
							) AS streak
					) AS current_streak
				WHERE
					streak > 0
			) AS updated_current_streak
	)
	SELECT
		read_count_ranking.count AS read_count,
		read_count_ranking.rank AS read_count_rank,
		streak_ranking.streak,
		streak_ranking.rank AS streak_rank,
		(
			SELECT count(*)
			FROM user_account
		) AS user_count
	FROM
		read_count_ranking
		LEFT JOIN streak_ranking
			ON read_count_ranking.user_account_id = streak_ranking.user_account_id
	WHERE
		read_count_ranking.user_account_id = get_user_stats.user_account_id;
$func$;