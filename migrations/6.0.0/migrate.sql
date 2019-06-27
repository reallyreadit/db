-- rename stats_api schema to stats
ALTER SCHEMA stats_api
RENAME TO stats;

-- create new standard return type for leaderboard functions
CREATE TYPE stats.leaderboard_ranking AS (
	user_name text,
	score int,
	rank int
);

-- create new return type for a user's individual rankings
CREATE TYPE stats.ranking AS (
	score int,
	rank int
);

-- create new return type for a user's current streak
CREATE TYPE stats.streak AS (
	day_count int,
    includes_today boolean
);

-- create new return type for a user's current streak with ranking
CREATE TYPE stats.streak_ranking AS (
	day_count int,
    includes_today boolean,
    rank int
);

-- drop current_streak so we can refactor get_current_streak
DROP MATERIALIZED VIEW stats.current_streak;

-- refactor get_current_streak to use new return type
DROP FUNCTION stats.get_current_streak(
	user_account_id bigint
);
CREATE FUNCTION stats.get_current_streak(
	user_account_id bigint
)
RETURNS stats.streak
LANGUAGE sql
STABLE
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
							lower(utc_range) - '1 day'::interval,
							upper(utc_range) - '1 day'::interval
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

-- recreate optimized current_streak
CREATE MATERIALIZED VIEW stats.current_streak AS (
	SELECT
		user_account.id AS user_account_id,
		user_account.name AS user_name,
		current_streak.day_count AS streak
	FROM
		user_account
		JOIN (
			SELECT
				user_account_id,
				max(date_completed) AS date_completed
			FROM
				user_article
			WHERE
				-- westernmost utc offset (-12 hrs) - 1 day (24 hrs) - potential DST offset (1 hr) = -37 hrs
				date_completed >= (utc_now() - '37 hours'::interval)
			GROUP BY
				user_account_id
		) AS latest_read
			ON latest_read.user_account_id = user_account.id
		JOIN LATERAL stats.get_current_streak(user_account.id) AS current_streak
		   ON user_account.time_zone_id IS NOT NULL
	WHERE
		current_streak.day_count > 0
);

-- recreate get_current_streak_leaderboard to return rank
DROP FUNCTION stats.get_current_streak_leaderboard(
	user_account_id bigint,
	max_count integer
);
CREATE FUNCTION stats.get_current_streak_leaderboard(
	user_account_id bigint,
	max_rank integer
)
RETURNS SETOF stats.leaderboard_ranking
LANGUAGE sql
STABLE
AS $$
    WITH ranking AS (
		SELECT
			user_name,
			streak AS score,
			dense_rank() OVER (ORDER BY streak DESC)::int AS rank
		FROM
			(
				SELECT
					user_account_id,
					user_name,
					streak
				FROM
					stats.current_streak
				WHERE
					user_account_id != coalesce(get_current_streak_leaderboard.user_account_id, 0)
				UNION ALL
				SELECT
					user_account.id AS user_account_id,
					user_account.name AS user_name,
					current_streak.day_count AS streak
				FROM
					user_account
					JOIN LATERAL stats.get_current_streak(user_account.id) AS current_streak
						ON TRUE
				WHERE
					user_account.id = coalesce(get_current_streak_leaderboard.user_account_id, 0) AND
					current_streak.day_count > 0
			) AS updated_current_streak
    )
    SELECT
    	user_name,
        score,
        rank
    FROM
    	ranking
    WHERE
    	rank <= get_current_streak_leaderboard.max_rank
    ORDER BY
    	rank,
        user_name;
$$;

-- recreate get_read_count_leaderboard to accept since_date parameter and return rank
DROP FUNCTION stats.get_read_count_leaderboard(
	max_count integer
);
CREATE FUNCTION stats.get_read_count_leaderboard(
	max_rank integer,
	since_date timestamp
)
RETURNS SETOF stats.leaderboard_ranking
LANGUAGE sql
STABLE
AS $$
    WITH ranking AS (
		SELECT
			user_account.name AS user_name,
			count(*)::int AS score,
			dense_rank() OVER (ORDER BY count(*) DESC)::int AS rank
		FROM
			user_article
			JOIN user_account ON user_article.user_account_id = user_account.id
		WHERE
		    user_article.date_completed >= coalesce(
		        get_read_count_leaderboard.since_date,
				(SELECT min(date_completed) FROM user_article)
			)
		GROUP BY
			user_account.id
    )
    SELECT
    	user_name,
        score,
        rank
    FROM
    	ranking
    WHERE
    	rank <= get_read_count_leaderboard.max_rank
    ORDER BY
    	rank,
        user_name;
$$;

-- create longest recent reads leaderboard
CREATE FUNCTION stats.get_longest_read_leaderboard(
	max_rank integer,
	since_date timestamp
)
RETURNS SETOF stats.leaderboard_ranking
LANGUAGE sql
STABLE
AS $$
    SELECT
        -- for some reason omitting this cast causes a huge performance issue
		user_account.name::text,
		estimate_article_length(
			word_count => top_article.word_count
		),
		top_article.rank::int
	FROM
		(
			SELECT
				article.id,
				article.word_count,
				row_number() OVER (ORDER BY article.word_count DESC) AS rank,
				array_agg(user_article.user_account_id) AS user_account_ids
			FROM
				article
				JOIN user_article
					ON user_article.article_id = article.id
			WHERE
			    user_article.date_completed >= coalesce(
			        get_longest_read_leaderboard.since_date,
			        (SELECT min(date_completed) FROM user_article)
			    )
			GROUP BY
				article.id
			ORDER BY
				article.word_count DESC
			LIMIT
				get_longest_read_leaderboard.max_rank
		) AS top_article
		JOIN user_account
			ON user_account.id = ANY (top_article.user_account_ids)
	ORDER BY
		top_article.rank,
		user_account.name;
$$;

-- create scouts view and leaderboard
CREATE VIEW stats.scouting AS (
	SELECT
		article.id AS article_id,
    	article.aotd_timestamp,
    	rating.user_account_id
	FROM
		article
		JOIN rating
	    	ON rating.article_id = article.id
		LEFT JOIN rating AS earlier_rating
			ON (
				earlier_rating.article_id = rating.article_id AND
				earlier_rating.timestamp < rating.timestamp
			)
	WHERE (
		article.aotd_timestamp IS NOT NULL AND
		earlier_rating.id IS NULL
	)
);

CREATE FUNCTION stats.get_scout_leaderboard(
	max_rank integer,
	since_date timestamp
)
RETURNS SETOF stats.leaderboard_ranking
LANGUAGE sql
STABLE
AS $$
    WITH ranking AS (
		SELECT
			user_account.name AS user_name,
			count(*)::int AS score,
			dense_rank() OVER (ORDER BY count(*) DESC)::int AS rank
		FROM
			stats.scouting
			JOIN user_account
				ON user_account.id = scouting.user_account_id
		WHERE
		    scouting.aotd_timestamp >= coalesce(
		        get_scout_leaderboard.since_date,
				(SELECT min(aotd_timestamp) FROM stats.scouting)
			)
		GROUP BY
			user_account.id
    )
    SELECT
    	user_name,
        score,
        rank
    FROM
    	ranking
    WHERE
    	rank <= get_scout_leaderboard.max_rank
    ORDER BY
    	rank,
        user_name;
$$;

-- create scribes view and leaderboard
CREATE VIEW stats.scribe_comment AS (
	SELECT
		comment.id,
		comment.date_created,
		comment.user_account_id
	FROM
		comment
		LEFT JOIN comment AS reply
			ON reply.parent_comment_id = comment.id
	WHERE (
		comment.parent_comment_id IS NOT NULL OR
		reply.user_account_id != comment.user_account_id
	)
);

CREATE FUNCTION stats.get_scribe_leaderboard(
	max_rank integer,
	since_date timestamp
)
RETURNS SETOF stats.leaderboard_ranking
LANGUAGE sql
STABLE
AS $$
    WITH ranking AS (
		SELECT
			user_account.name AS user_name,
			count(*)::int AS score,
			dense_rank() OVER (ORDER BY count(*) DESC)::int AS rank
		FROM
			stats.scribe_comment
			JOIN user_account
				ON user_account.id = scribe_comment.user_account_id
		WHERE
		    scribe_comment.date_created >= coalesce(
				get_scribe_leaderboard.since_date,
		        (SELECT min(date_created) FROM stats.scribe_comment)
			)
		GROUP BY
			user_account.id
    )
    SELECT
    	user_name,
		score,
		rank
    FROM
    	ranking
    WHERE
    	rank <= get_scribe_leaderboard.max_rank
    ORDER BY
    	rank,
        user_name;
$$;

-- refactor get_user_stats into multiple functions
DROP FUNCTION stats.get_user_stats(user_account_id bigint);

CREATE FUNCTION stats.get_user_leaderboard_rankings(
	user_account_id bigint,
	longest_read_since_date timestamp,
	scout_since_date timestamp,
	scribe_since_date timestamp
)
RETURNS TABLE(
   longest_read stats.ranking,
   read_count stats.ranking,
   scout_count stats.ranking,
   scribe_count stats.ranking,
   streak stats.streak_ranking,
   weekly_read_count stats.ranking
)
LANGUAGE sql
STABLE
AS $$
	WITH longest_read_ranking AS (
		SELECT
			user_article.user_account_id,
			estimate_article_length(
				max(article.word_count)
			) AS max_length,
			dense_rank() OVER (ORDER BY max(article.word_count) DESC) AS rank
		FROM
			user_article
			JOIN article
				ON article.id = user_article.article_id
		WHERE
		    user_article.date_completed >= coalesce(
		        longest_read_since_date,
		        (SELECT min(date_completed) FROM user_article)
		    )
		GROUP BY
			user_article.user_account_id
	),
	read_count_ranking AS (
		SELECT
			user_account_id,
			count(*) AS count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS rank
		FROM
			user_article
		WHERE
			date_completed IS NOT NULL
		GROUP BY
			user_account_id
	),
	scout_ranking AS (
		SELECT
			user_account_id,
			count(*) AS count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS rank
		FROM
			stats.scouting
		WHERE
		    aotd_timestamp >= coalesce(
		        scout_since_date,
		        (SELECT min(aotd_timestamp) FROM stats.scouting)
		    )
		GROUP BY
			user_account_id
	),
	scribe_ranking AS (
		SELECT
   			user_account_id,
			count(*) AS count,
   	   		dense_rank() OVER (ORDER BY count(*) DESC) AS rank
      	FROM
      		stats.scribe_comment
      	WHERE
      	    date_created >= coalesce(
      	        scribe_since_date,
      	        (SELECT min(date_created) FROM stats.scribe_comment)
			)
      	GROUP BY
      		user_account_id
	),
	streak_ranking AS (
		SELECT
			user_account_id,
			day_count,
		    includes_today,
			dense_rank() OVER (ORDER BY day_count DESC) AS rank
		FROM
			(
				WITH current_streak AS (
					SELECT
						day_count,
				     	includes_today
					FROM
						stats.get_current_streak(
							get_user_leaderboard_rankings.user_account_id
						)
				)
				SELECT
					user_account_id,
					streak AS day_count,
				    false AS includes_today
				FROM
					stats.current_streak
				WHERE
					user_account_id != get_user_leaderboard_rankings.user_account_id
				UNION ALL
				SELECT
					get_user_leaderboard_rankings.user_account_id,
				    day_count,
				    includes_today
				FROM
					current_streak
			) AS updated_current_streak
	    WHERE
	    	day_count > 0
	),
	weekly_read_count_ranking AS (
		SELECT
			user_account_id,
			count(*) AS count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS rank
		FROM
			user_article
		WHERE
			date_completed >= (utc_now() - '1 week'::interval)
		GROUP BY
			user_account_id
	)
	SELECT
		coalesce(
		    (
				SELECT
					(max_length, rank)::stats.ranking
				FROM
					longest_read_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
		    (0, 0)::stats.ranking
		) AS longest_read,
		coalesce(
	       (
				SELECT
					(count, rank)::stats.ranking
				FROM
					read_count_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
		    (0, 0)::stats.ranking
		) AS read_count,
		coalesce(
		    (
				SELECT
					(count, rank)::stats.ranking
				FROM
					scout_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
		    (0, 0)::stats.ranking
		) AS scout_count,
	   	coalesce(
	   	    (
				SELECT
					(count, rank)::stats.ranking
				FROM
					scribe_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
	   	    (0, 0)::stats.ranking
	   	) AS scribe_count,
		coalesce(
		    (
				SELECT
					(day_count, includes_today, rank)::stats.streak_ranking
				FROM
					streak_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
		    (0, false, 0)::stats.streak_ranking
		) AS streak,
	   	coalesce(
	   	    (
				SELECT
					(count, rank)::stats.ranking
				FROM
					weekly_read_count_ranking
				WHERE
					user_account_id = get_user_leaderboard_rankings.user_account_id
			),
	   	    (0, 0)::stats.ranking
	   	) AS weekly_read_count;
$$;

CREATE FUNCTION stats.get_user_count()
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
	SELECT
		coalesce(count(*), 0)
	FROM
		user_account;
$$;

CREATE FUNCTION stats.get_user_read_count(
	user_account_id bigint
)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
	SELECT
		coalesce(count(*), 0)
   	FROM
   		user_article
   	WHERE (
		user_account_id = get_user_read_count.user_account_id AND
		date_completed IS NOT NULL
	);
$$;