CREATE INDEX ON user_page (user_account_id);

CREATE FUNCTION stats_api.get_current_streak(
	user_account_id bigint
)
RETURNS bigint
LANGUAGE SQL
STABLE
AS $func$
	WITH RECURSIVE user_time_zone AS (
		SELECT name
		FROM time_zone
		WHERE
			id = (
				SELECT time_zone_id
				FROM user_account
				WHERE id = get_current_streak.user_account_id
			)
	),
	streak_day AS (
		WITH streak_start_day AS (
			SELECT *
			FROM generate_local_to_utc_date_series(
				cast(local_now((SELECT name FROM user_time_zone)) - '1 day'::interval AS date),
				cast(local_now((SELECT name FROM user_time_zone)) AS date),
				1,
				(SELECT name FROM user_time_zone)
			)
		),
		streak_start_daily_read_count AS (
			SELECT
				streak_start_day.local_day,
				streak_start_day.utc_range,
				count(*) FILTER (WHERE date_completed IS NOT NULL) AS read_count
			FROM
				streak_start_day
				LEFT JOIN (
					SELECT
						user_page.date_completed
					FROM
						user_page
						JOIN page ON user_page.page_id = page.id
					WHERE
						user_page.user_account_id = get_current_streak.user_account_id AND
						user_page.date_completed <@ tsrange(
							lower((SELECT utc_range FROM streak_start_day ORDER BY local_day LIMIT 1)),
							upper((SELECT utc_range FROM streak_start_day ORDER BY local_day DESC LIMIT 1))
						) AND
						page.word_count >= (184 * 5)
				) AS user_page ON streak_start_day.utc_range @> user_page.date_completed
			GROUP BY
				streak_start_day.local_day, streak_start_day.utc_range
		),
		streak_start_qualified_day AS (
			SELECT
				local_day,
				utc_range,
				CASE WHEN
					local_day = first_value(local_day) OVER local_day_desc AND
					lead(read_count) OVER local_day_desc > 0
					THEN TRUE
					ELSE read_count > 0
				END AS is_qualifying_day
			FROM
				streak_start_daily_read_count
			WINDOW
				local_day_desc AS (ORDER BY local_day DESC)
		)
		SELECT
			local_day,
			utc_range
		FROM streak_start_qualified_day
		WHERE is_qualifying_day
		UNION ALL
		(
			WITH next_day AS (
				SELECT
					cast(local_day - '1 day'::interval AS date) AS local_day,
					tsrange(
						lower(utc_range) - '1 day'::interval,
						upper(utc_range) - '1 day'::interval
					) AS utc_range
				FROM streak_day
				ORDER BY local_day
				LIMIT 1
			)
			SELECT
				(SELECT local_day FROM next_day),
				(SELECT utc_range FROM next_day)
			FROM
				user_page
				JOIN page ON user_page.page_id = page.id
			WHERE
				user_page.user_account_id = get_current_streak.user_account_id AND
				user_page.date_completed <@ (SELECT utc_range FROM next_day) AND
				page.word_count >= (184 * 5)
		)
	)
	SELECT
		count(DISTINCT local_day)
	FROM
		streak_day;
$func$;

CREATE MATERIALIZED VIEW stats_api.current_streak AS
SELECT
	id,
	name,
	streak
FROM
	user_account
	JOIN LATERAL stats_api.get_current_streak(id) AS streak
		ON user_account.time_zone_id IS NOT NULL
WHERE
	streak > 0;

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

DROP FUNCTION stats_api.get_user_read_stats(
	user_account_id bigint
);

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