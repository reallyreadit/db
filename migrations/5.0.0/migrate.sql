-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- drop the user_articles_pages view that references user_page
DROP VIEW article_api.user_article_pages;

-- refactor user_page to user_article
DROP INDEX user_page_page_id_idx;

ALTER TABLE core.user_page
DROP CONSTRAINT user_page_page_id_fkey;

UPDATE core.user_page
SET page_id = page.article_id
FROM page
WHERE page.id = user_page.page_id;

ALTER TABLE core.user_page
RENAME COLUMN page_id TO article_id;

ALTER TABLE core.user_page
ADD CONSTRAINT user_article_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article (id);

CREATE INDEX user_article_article_id_idx ON core.user_page (article_id);

ALTER TABLE core.user_page
RENAME TO user_article;

-- refactor functions dependent on user_article_pages
CREATE OR REPLACE FUNCTION article_api.get_article_history(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
	WITH history_article AS (
		SELECT
			greatest(user_article.date_created, user_article.last_modified, star.date_starred) AS history_date,
			coalesce(user_article.article_id, star.article_id) AS article_id
		FROM
			(
				SELECT
					date_created,
					last_modified,
					article_id
				FROM user_article
				WHERE user_account_id = get_article_history.user_account_id
			) AS user_article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE user_account_id = get_article_history.user_account_id
			) AS star ON star.article_id = user_article.article_id
	    	JOIN article ON (
				article.id = user_article.article_id OR
				article.id = star.article_id
			)
	    WHERE core.matches_article_length(
			article.word_count,
			min_length,
			max_length
		)
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM history_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM history_article
			ORDER BY history_date DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE OR REPLACE FUNCTION article_api.get_articles(user_account_id bigint, VARIADIC article_ids bigint[]) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name AS source,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1] AS url,
		coalesce(article_authors.names, '{}') AS authors,
		coalesce(article_tags.names, '{}') AS tags,
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		user_article.date_created,
		coalesce(
		   article_api.get_percent_complete(
		      user_article.readable_word_count,
		      user_article.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score AS rating_score
	FROM
		article
		JOIN article_api.article_pages ON (
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (article_ids)
		)
		JOIN source ON source.id = article.source_id
		LEFT JOIN article_api.article_authors ON (
			article_authors.article_id = article.id AND
			article_authors.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_tags ON (
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (article_ids)
		)
		LEFT JOIN user_article ON (
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id AND
			user_article.article_id = ANY (article_ids)
		)
		LEFT JOIN star ON (
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		)
		LEFT JOIN article_api.user_article_rating ON (
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (article_ids)
		)
	ORDER BY array_position(article_ids, article.id)
$$;
CREATE OR REPLACE FUNCTION article_api.score_articles() RETURNS void
    LANGUAGE sql
    AS $$
	WITH score AS (
		SELECT
			article.id AS article_id,
			(
				(
					coalesce(comments.score, 0) +
					(coalesce(reads.score, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS hot,
			(
				(
					coalesce(comments.count, 0) +
					(coalesce(reads.count, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS top
		FROM
			(
			   SELECT DISTINCT article_id AS id
				FROM comment
				WHERE date_created > utc_now() - '1 month'::interval
				UNION
				SELECT DISTINCT article_id AS id
				FROM user_article
				WHERE date_completed > utc_now() - '1 month'::interval
			) AS scorable_article
			JOIN article ON article.id = scorable_article.id
			LEFT JOIN (
				SELECT
					count(*) AS count,
					sum(
						CASE
						   WHEN age < '18 hours' THEN 400
							WHEN age < '36 hours' THEN 200
							WHEN age < '72 hours' THEN 150
							WHEN age < '1 week' THEN 100
							WHEN age < '2 weeks' THEN 50
							WHEN age < '1 month' THEN 5
							ELSE 1
						END
					) AS score,
					article_id
				FROM (
					SELECT
						article_id,
						utc_now() - date_created AS age
					FROM comment
				) AS comment
				GROUP BY article_id
			) AS comments ON comments.article_id = article.id
			LEFT JOIN (
				SELECT
					count(*) AS count,
					sum(
						CASE
						   WHEN age < '18 hours' THEN 350
							WHEN age < '36 hours' THEN 175
							WHEN age < '72 hours' THEN 125
							WHEN age < '1 week' THEN 75
							WHEN age < '2 weeks' THEN 25
							WHEN age < '1 month' THEN 5
							ELSE 1
						END
					) AS score,
					article_id
				FROM (
					SELECT
						article_id,
						utc_now() - date_completed AS age
					FROM user_article
					WHERE date_completed IS NOT NULL
				) AS read
				GROUP BY article_id
			) AS reads ON reads.article_id = article.id
	)
	UPDATE article
	SET
		hot_score = score.hot,
		top_score = score.top
	FROM score
	WHERE score.article_id = article.id;
$$;

-- refactor functions dependent on user_page
CREATE OR REPLACE FUNCTION analytics.get_key_metrics(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(day timestamp without time zone, user_accounts_app_count bigint, user_accounts_browser_count bigint, user_accounts_unknown_count bigint, reads_app_count bigint, reads_browser_count bigint, reads_unknown_count bigint, comments_app_count bigint, comments_browser_count bigint, comments_unknown_count bigint)
    LANGUAGE sql
    AS $$
	WITH range AS (
		SELECT
			date AS day,
			date + '1 day'::interval AS next_day
		FROM generate_series(
		    get_key_metrics.start_date,
		    get_key_metrics.end_date,
		    '1 day'::interval
		) AS series (date)
	)
	SELECT
		range.day,
		coalesce(user_accounts.app_count, 0) AS user_accounts_app_count,
		coalesce(user_accounts.browser_count, 0) AS user_accounts_browser_count,
		coalesce(user_accounts.unknown_count, 0) AS user_accounts_unknown_count,
		coalesce(reads.app_count, 0) AS reads_app_count,
		coalesce(reads.browser_count, 0) AS reads_browser_count,
		coalesce(reads.unknown_count, 0) AS reads_unknown_count,
		coalesce(comments.app_count, 0) AS comments_app_count,
		coalesce(comments.browser_count, 0) AS comments_browser_count,
		coalesce(comments.unknown_count, 0) AS comments_unknown_count
	FROM
		range
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_account
				JOIN range ON user_account.date_created >= range.day AND user_account.date_created < range.next_day
			GROUP BY range.day
		) AS user_accounts ON user_accounts.day = range.day
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_article
				JOIN range ON user_article.date_completed >= range.day AND user_article.date_completed < range.next_day
			GROUP BY range.day
		) AS reads ON reads.day = range.day
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE
					analytics->'client'->>'mode' = 'App' OR
					analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (WHERE
				    analytics->'client'->>'mode' = 'Browser' OR
				    analytics->'client'->>'type' = 'web/extension'
				) AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				comment
				JOIN range ON comment.date_created >= range.day AND comment.date_created < range.next_day
			GROUP BY range.day
		) AS comments ON comments.day = range.day
	ORDER BY range.day DESC;
$$;
DROP FUNCTION article_api.create_user_page(page_id bigint, user_account_id bigint, readable_word_count integer, analytics text);
CREATE FUNCTION article_api.create_user_article(article_id bigint, user_account_id bigint, readable_word_count integer, analytics text) RETURNS core.user_article
    LANGUAGE sql
    AS $$
	INSERT INTO user_article (
		article_id,
		user_account_id,
		read_state,
		readable_word_count,
		analytics
	)
	VALUES (
		create_user_article.article_id,
		create_user_article.user_account_id,
		ARRAY[(SELECT -create_user_article.readable_word_count)],
		create_user_article.readable_word_count,
	    create_user_article.analytics::json
	)
	RETURNING *;
$$;
DROP FUNCTION article_api.get_user_page(page_id bigint, user_account_id bigint);
CREATE FUNCTION article_api.get_user_article(article_id bigint, user_account_id bigint) RETURNS SETOF core.user_article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_article
	WHERE (
		article_id = get_user_article.article_id AND
		user_account_id = get_user_article.user_account_id
	);
$$;
DROP FUNCTION article_api.update_user_page(user_page_id bigint, readable_word_count integer, read_state integer[]);
CREATE FUNCTION article_api.update_user_article(user_article_id bigint, readable_word_count integer, read_state integer[]) RETURNS core.user_article
    LANGUAGE sql
    AS $$
	UPDATE user_article
	SET
		readable_word_count = update_user_article.readable_word_count,
		read_state = update_user_article.read_state
	WHERE user_article.id = update_user_article.user_article_id
	RETURNING *;
$$;
CREATE OR REPLACE FUNCTION community_reads.get_most_read(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
    WITH most_read AS (
		SELECT
			listed_community_read.id,
			count(*) AS read_count
		FROM
			community_reads.listed_community_read
			JOIN user_article ON user_article.article_id = listed_community_read.id
		WHERE
			since_date IS NOT NULL AND
			user_article.date_completed >= since_date AND
		    core.matches_article_length(
				listed_community_read.word_count,
				min_length,
				max_length
			)
		GROUP BY
			listed_community_read.id
		UNION ALL
		SELECT
			id,
			read_count
		FROM community_reads.listed_community_read
		WHERE
			since_date IS NULL AND
			read_count > 0 AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM most_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM most_read
			ORDER BY read_count DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE OR REPLACE FUNCTION stats_api.get_read_count_leaderboard(max_count integer) RETURNS TABLE(name text, read_count bigint)
    LANGUAGE sql STABLE
    AS $$
	SELECT
		user_account.name,
		count(*) AS read_count
	FROM
		user_article
		JOIN user_account ON user_article.user_account_id = user_account.id
	WHERE
		user_article.date_completed IS NOT NULL
	GROUP BY
		user_account.id
	ORDER BY
		read_count DESC
	LIMIT
		get_read_count_leaderboard.max_count;
$$;
CREATE OR REPLACE FUNCTION stats_api.get_user_stats(user_account_id bigint) RETURNS TABLE(read_count bigint, read_count_rank bigint, streak bigint, streak_rank bigint, user_count bigint)
    LANGUAGE sql STABLE
    AS $$
	WITH read_count_ranking AS (
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
$$;

-- create function to look up user_article by id
CREATE FUNCTION article_api.get_user_article(user_article_id bigint) RETURNS SETOF core.user_article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_article
	WHERE id = get_user_article.user_article_id;
$$;

-- create user_article_progress in order to store the history of reading activity
CREATE TABLE core.user_article_progress (
	id bigserial PRIMARY KEY,
	user_account_id bigint NOT NULL REFERENCES user_account (id),
	article_id bigint NOT NULL REFERENCES article (id),
	period timestamp NOT NULL,
	words_read int NOT NULL,
	client_type text,
	UNIQUE (user_account_id, article_id, period)
);

-- update article_api.update_read_progress to use user_article and store periodic progress
DROP FUNCTION article_api.update_read_progress(user_page_id bigint, read_state integer[], analytics text);
CREATE FUNCTION article_api.update_read_progress(user_article_id bigint, read_state integer[], analytics text) RETURNS core.user_article
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
   	-- utc timestamp
   	utc_now CONSTANT timestamp NOT NULL := utc_now();
   	-- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT sum(n)
		FROM unnest(read_state) AS n
		WHERE n > 0
	);
	-- local user_article
	current_user_article user_article;
	-- progress since last commit
	words_read_since_last_commit int;
BEGIN
    -- read and lock the existing user_article
	SELECT *
	INTO locals.current_user_article
	FROM user_article
	WHERE user_article.id = update_read_progress.user_article_id
	FOR UPDATE;
	-- only update if more words have been read
	IF locals.words_read > locals.current_user_article.words_read
	THEN
	   	-- calculate the words read since the last commit
	   	words_read_since_last_commit = locals.words_read - current_user_article.words_read;
		-- update the progress
	   	INSERT INTO user_article_progress
			(user_account_id, article_id, period, words_read, client_type)
	   	VALUES
	   	(
	   		locals.current_user_article.user_account_id,
	   	 	locals.current_user_article.article_id,
				(
					date_trunc('hour', locals.utc_now) +
					make_interval(mins => floor(extract('minute' FROM locals.utc_now) / 15)::int * 15)
				),
	   		words_read_since_last_commit,
	   		update_read_progress.analytics::json->'client'->'type'
		)
		ON CONFLICT
		   (user_account_id, article_id, period)
		DO UPDATE
			SET words_read = user_article_progress.words_read + words_read_since_last_commit;
	  	-- update the user_article
		UPDATE user_article
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = locals.utc_now,
			analytics = update_read_progress.analytics::json
		WHERE user_article.id = update_read_progress.user_article_id
		RETURNING *
		INTO locals.current_user_article;
		-- check if this update completed the page
		IF
			locals.current_user_article.date_completed IS NULL AND
			(
				SELECT article_api.get_percent_complete(
					locals.current_user_article.readable_word_count,
					locals.words_read
				) >= 90
			)
		THEN
			-- set date_completed
			UPDATE user_article
			SET date_completed = user_article.last_modified
			WHERE user_article.id = update_read_progress.user_article_id
			RETURNING *
			INTO locals.current_user_article;
			-- update the cached article read count
			UPDATE article
			SET read_count = read_count + 1
			WHERE id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_article;
END;
$$;

-- create user_article_progress records for existing reads
INSERT INTO user_article_progress
	(user_account_id, article_id, period, words_read, client_type)
SELECT
	user_account_id,
	article_id,
	last_modified,
	words_read,
    analytics->'client'->'type'
FROM
	user_article
WHERE
    words_read > 0;

-- create new make_timestamptz_at_time_zone function
CREATE FUNCTION core.make_timestamptz_at_time_zone(
	input_timestamp timestamptz,
	time_zone_name text
)
RETURNS timestamptz
IMMUTABLE
LANGUAGE SQL
AS $$
	SELECT make_timestamptz(
		extract(YEAR FROM input_timestamp)::int,
		extract(MONTH FROM input_timestamp)::int,
		extract(DAY FROM input_timestamp)::int,
		extract(HOUR FROM input_timestamp)::int,
		extract(MINUTE FROM input_timestamp)::int,
		extract(SECOND FROM input_timestamp),
		time_zone_name
	);
$$;

-- create new local_to_utc_timestamp function
CREATE FUNCTION core.local_to_utc_timestamp(
	local_timestamp timestamptz,
	time_zone_name text
)
RETURNS timestamp
IMMUTABLE
LANGUAGE SQL
AS $$
	SELECT make_timestamptz_at_time_zone(local_timestamp, time_zone_name) AT TIME ZONE 'UTC';
$$;

-- create new utc_to_local_timestamp function
CREATE FUNCTION core.utc_to_local_timestamp(
	utc_timestamp timestamptz,
	time_zone_name text
)
RETURNS timestamp
IMMUTABLE
LANGUAGE SQL
AS $$
	SELECT make_timestamptz_at_time_zone(utc_timestamp, 'UTC') AT TIME ZONE time_zone_name;
$$;

-- refactor generate_local_to_utc_date_series to generate_local_timestamp_to_utc_range_series
DROP FUNCTION core.generate_local_to_utc_date_series(start date, stop date, day_step_count integer, time_zone_name text);
CREATE FUNCTION core.generate_local_timestamp_to_utc_range_series(
	start timestamptz,
	stop timestamptz,
	step interval,
	time_zone_name text
)
RETURNS TABLE(
    local_timestamp timestamptz,
    utc_range tsrange
)
LANGUAGE SQL
IMMUTABLE
AS $$
	SELECT
		local_timestamp,
		tsrange(
			local_to_utc_timestamp(local_timestamp, time_zone_name),
			local_to_utc_timestamp(local_timestamp + step, time_zone_name)
		) AS utc_range
	FROM
    	generate_series(start, stop, step) AS local_timestamp;
$$;

-- refactor get_current_streak to use user_article and generate_local_to_utc_timestamp_series
CREATE OR REPLACE FUNCTION stats_api.get_current_streak(user_account_id bigint) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
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
			FROM generate_local_timestamp_to_utc_range_series(
				cast(local_now((SELECT name FROM user_time_zone)) - '1 day'::interval AS date),
				cast(local_now((SELECT name FROM user_time_zone)) AS date),
				'1 day'::interval,
				(SELECT name FROM user_time_zone)
			)
		),
		streak_start_daily_read_count AS (
			SELECT
				streak_start_day.local_timestamp,
				streak_start_day.utc_range,
				count(*) FILTER (WHERE date_completed IS NOT NULL) AS read_count
			FROM
				streak_start_day
				LEFT JOIN (
					SELECT
						user_article.date_completed
					FROM
						user_article
					WHERE
						user_article.user_account_id = get_current_streak.user_account_id AND
						user_article.date_completed <@ tsrange(
							lower((SELECT utc_range FROM streak_start_day ORDER BY local_timestamp LIMIT 1)),
							upper((SELECT utc_range FROM streak_start_day ORDER BY local_timestamp DESC LIMIT 1))
						)
				) AS user_article_group ON streak_start_day.utc_range @> user_article_group.date_completed
			GROUP BY
				streak_start_day.local_timestamp, streak_start_day.utc_range
		),
		streak_start_qualified_day AS (
			SELECT
				local_timestamp,
				utc_range,
				CASE WHEN
					local_timestamp = first_value(local_timestamp) OVER local_day_desc AND
					lead(read_count) OVER local_day_desc > 0
					THEN TRUE
					ELSE read_count > 0
				END AS is_qualifying_day
			FROM
				streak_start_daily_read_count
			WINDOW
				local_day_desc AS (ORDER BY local_timestamp DESC)
		)
		SELECT
			local_timestamp,
			utc_range
		FROM streak_start_qualified_day
		WHERE is_qualifying_day
		UNION ALL
		(
			WITH next_day AS (
				SELECT
					cast(local_timestamp - '1 day'::interval AS date) AS local_day,
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
				user_article
			WHERE
				user_article.user_account_id = get_current_streak.user_account_id AND
				user_article.date_completed <@ (SELECT utc_range FROM next_day)
		)
	)
	SELECT
		count(DISTINCT local_timestamp)
	FROM
		streak_day;
$$;

-- create estimate_reading_time
CREATE FUNCTION estimate_reading_time(word_count numeric)
RETURNS int
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT greatest(0, coalesce(word_count, 0) / 184)::int;
$$;

-- refactor estimate_article_length to use estimate_reading_time
CREATE OR REPLACE FUNCTION core.estimate_article_length(word_count integer) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT greatest(1, estimate_reading_time(word_count))::int;
$$;

-- create get_daily_reading_time_totals
CREATE FUNCTION stats_api.get_daily_reading_time_totals(
	user_account_id bigint,
	number_of_days int
)
RETURNS TABLE (
    date date,
    minutes_reading int,
    minutes_reading_to_completion int
)
LANGUAGE SQL
STABLE
AS $$
    WITH user_time_zone AS (
		SELECT name
		FROM time_zone
		WHERE
			id = (
				SELECT time_zone_id
				FROM user_account
				WHERE id = user_account_id
			)
	),
	user_local_day AS (
		SELECT local_now((SELECT name FROM user_time_zone))::date AS date
	)
	SELECT
		day.local_timestamp::date AS date,
		estimate_reading_time(sum(user_article_progress.words_read)) AS minutes_reading,
		estimate_reading_time(
			sum(user_article_progress.words_read) FILTER (WHERE user_article.date_completed IS NOT NULL)
		) AS minutes_reading_to_completion
	FROM
		generate_local_timestamp_to_utc_range_series(
		   start => ((SELECT date FROM user_local_day) - make_interval(days => number_of_days))::date,
		   stop => (SELECT date FROM user_local_day),
		   step => '1 day'::interval,
		   time_zone_name => (SELECT name FROM user_time_zone)
		) AS day
		LEFT JOIN user_article_progress
			ON (
			   user_article_progress.user_account_id = get_daily_reading_time_totals.user_account_id AND
			   user_article_progress.period <@ day.utc_range
			)
		LEFT JOIN user_article
			ON (
				user_article.user_account_id = get_daily_reading_time_totals.user_account_id AND
				user_article.article_id = user_article_progress.article_id
			)
	GROUP BY
		day.local_timestamp
    ORDER BY
    	date;
$$;

-- create get_monthly_reading_time_totals
CREATE FUNCTION stats_api.get_monthly_reading_time_totals(
	user_account_id bigint,
	number_of_months int
)
RETURNS TABLE (
    date date,
    minutes_reading int,
    minutes_reading_to_completion int
)
LANGUAGE SQL
STABLE
AS $$
	WITH target_user AS (
		SELECT
			date_created,
			time_zone_id
		FROM user_account
		WHERE id = user_account_id
	),
	user_time_zone AS (
		SELECT name
		FROM time_zone
		WHERE id = (SELECT time_zone_id FROM target_user)
	),
	user_local_month AS (
		SELECT date_trunc('month', local_now((SELECT name FROM user_time_zone)))::date AS date
	)
	SELECT
		month.local_timestamp::date AS date,
		estimate_reading_time(sum(user_article_progress.words_read)) AS minutes_reading,
		estimate_reading_time(
			sum(user_article_progress.words_read) FILTER (WHERE user_article.date_completed IS NOT NULL)
		) AS minutes_reading_to_completion
	FROM
		generate_local_timestamp_to_utc_range_series(
			start => (
			    CASE WHEN number_of_months IS NOT NULL
			    	THEN (SELECT date FROM user_local_month) - make_interval(months => number_of_months)
			        ELSE (
			            SELECT date_trunc(
			                'month',
			                utc_to_local_timestamp(
			                    (SELECT date_created FROM target_user),
			                    (SELECT name FROM user_time_zone)
			                )
			            )
			        )
		    	END
			),
			stop => (SELECT date FROM user_local_month),
			step => '1 month'::interval,
			time_zone_name => (SELECT name FROM user_time_zone)
		) AS month
		LEFT JOIN user_article_progress
			ON (
			   user_article_progress.user_account_id = get_monthly_reading_time_totals.user_account_id AND
			   user_article_progress.period <@ month.utc_range
			)
		LEFT JOIN user_article
			ON (
				user_article.user_account_id = get_monthly_reading_time_totals.user_account_id AND
				user_article.article_id = user_article_progress.article_id
			)
	GROUP BY
		month.local_timestamp
    ORDER BY
    	date;
$$;