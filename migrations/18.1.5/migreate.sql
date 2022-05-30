-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- fixed utc range calculation in recursive cte to account for daylight savings changes
CREATE OR REPLACE FUNCTION
   stats.get_current_streak(
   	user_account_id bigint
   )
RETURNS
   stats.streak
LANGUAGE sql STABLE
AS $$
   -- get the name of the user's time zone
	WITH RECURSIVE user_time_zone AS (
		SELECT
			name
		FROM
			time_zone
		WHERE
			id = (
				SELECT
					time_zone_id
				FROM
					user_account
				WHERE
					id = get_current_streak.user_account_id
			)
	),
	-- this is the recursive CTE that selects the contiguous days of a streak
	streak_day AS (
	    -- a streak can start today or be continued from the previous day so both must be considered
	    -- start by selecting the number of articles read yesterday and today
		WITH streak_start_daily_read_count AS (
			SELECT
				streak_start_day.local_timestamp,
				streak_start_day.utc_range,
				count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS read_count
			FROM
				(
					SELECT
						local_timestamp,
					    utc_range
					FROM
						generate_local_timestamp_to_utc_range_series(
							start => (local_now((SELECT name FROM user_time_zone)) - '1 day'::interval)::date,
							stop => local_now((SELECT name FROM user_time_zone))::date,
							step => '1 day'::interval,
							time_zone_name => (SELECT name FROM user_time_zone)
						)
				) AS streak_start_day
				LEFT JOIN user_article
					ON (
						user_article.user_account_id = get_current_streak.user_account_id AND
						user_article.date_completed <@ streak_start_day.utc_range
					)
			GROUP BY
				streak_start_day.local_timestamp,
				streak_start_day.utc_range
		),
		-- determine if either or both days count as a streak day
		streak_start_qualified_day AS (
			SELECT
				local_timestamp,
				utc_range,
				read_count,
				CASE WHEN (
						local_timestamp = first_value(local_timestamp) OVER local_day_desc AND
						lead(read_count) OVER local_day_desc > 0
					)
					THEN TRUE
					ELSE read_count > 0
				END AS is_qualifying_day
			FROM
				streak_start_daily_read_count
			WINDOW
				local_day_desc AS (ORDER BY local_timestamp DESC)
		)
		-- select the days that count as a streak day
		SELECT
			local_timestamp,
			utc_range,
			read_count
		FROM streak_start_qualified_day
		WHERE is_qualifying_day
		-- recursively add additional streak days
		UNION ALL
		(
			SELECT
				next_day.local_timestamp,
				next_day.utc_range,
				count(*) AS read_count
			FROM
			    -- select the prior day and join with any completed articles
				(
					SELECT
						(local_timestamp - '1 day'::interval)::date AS local_timestamp,
						tsrange(
							local_to_utc_timestamp(local_timestamp - '1 day'::interval, (SELECT name FROM user_time_zone)),
							local_to_utc_timestamp(local_timestamp, (SELECT name FROM user_time_zone))
						) AS utc_range
					FROM
						streak_day
					ORDER BY
						local_timestamp
					LIMIT
						1
				) AS next_day
				JOIN user_article
					ON (
						user_article.user_account_id = get_current_streak.user_account_id AND
						user_article.date_completed <@ next_day.utc_range
					)
			GROUP BY
				next_day.local_timestamp,
				next_day.utc_range
		)
	)
	SELECT
		count(nullif(read_count, 0))::int AS day_count,
		coalesce(every(read_count > 0), false) AS includes_today
	FROM
		streak_day;
$$;