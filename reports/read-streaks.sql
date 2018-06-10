WITH daily_counts AS (
	SELECT
		user_account.name AS user_account_name,
		range.local_day,
		count(read.*) FILTER (WHERE words_read > 184 * 5) AS read_count
	FROM
		user_account
		CROSS JOIN generate_local_to_utc_date_series(
			cast(local_now('America/New_York') - '9 days'::interval AS date),
			cast(local_now('America/New_York') AS date),
			1,
			'America/New_York'
		) AS range
		LEFT JOIN article_api.user_article_read AS read ON
			read.user_account_id = user_account.id AND
			range.utc_range @> read.date_completed
	GROUP BY
		user_account.name,
		range.local_day
),
lagged_daily_counts AS (
	SELECT
		user_account_name,
		local_day,
		read_count,
		lag(read_count, 1, read_count)
			OVER (
				PARTITION BY user_account_name
				ORDER BY local_day DESC
			) AS lag_read_count
	FROM daily_counts
),
streaks AS (
	SELECT
		user_account_name,
		local_day,
		read_count,
		lag_read_count,
		sum(
			CASE WHEN least(lag_read_count, 1) = least(read_count, 1)
				THEN 0
				ELSE 1
			END
		) OVER (
			PARTITION BY user_account_name
			ORDER BY local_day DESC
		) AS streak_id
	FROM lagged_daily_counts
),
streak_groups AS (
	SELECT
		user_account_name,
		min(local_day) AS start_date,
		max(local_day) AS end_date,
		max(local_day) - min(local_day) AS day_count,
		sum(read_count) AS total_reads
	FROM streaks
	GROUP BY
		user_account_name,
		streak_id
)
SELECT
	*
FROM streak_groups
WHERE total_reads > 0
ORDER BY day_count DESC
LIMIT 10;