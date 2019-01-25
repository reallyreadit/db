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
						)
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
				user_page.date_completed <@ (SELECT utc_range FROM next_day)
		)
	)
	SELECT
		count(DISTINCT local_day)
	FROM
		streak_day;
$func$;