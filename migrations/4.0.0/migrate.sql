-- add new analytics columns
ALTER TABLE user_account
ADD COLUMN analytics jsonb;

ALTER TABLE user_page
ADD COLUMN analytics jsonb;

ALTER TABLE comment
ADD COLUMN analytics jsonb;

-- update functions to save analytics data
DROP FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint
);
CREATE FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint,
	analytics text
)
RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql
AS $$
DECLARE
	user_account_id bigint;
BEGIN
	INSERT INTO
	    user_account (name, email, password_hash, password_salt, time_zone_id, analytics)
	VALUES
		(trim(name), trim(email), password_hash, password_salt, time_zone_id, analytics::json)
	RETURNING id INTO user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;

DROP FUNCTION article_api.create_user_page(
	page_id bigint,
	user_account_id bigint,
	readable_word_count integer
);
CREATE FUNCTION article_api.create_user_page(
	page_id bigint,
	user_account_id bigint,
	readable_word_count integer,
	analytics text
)
RETURNS core.user_page
LANGUAGE sql
AS $$
	INSERT INTO user_page (
		page_id,
		user_account_id,
		read_state,
		readable_word_count,
		analytics
	)
	VALUES (
		create_user_page.page_id,
		create_user_page.user_account_id,
		ARRAY[(SELECT -create_user_page.readable_word_count)],
		create_user_page.readable_word_count,
	    create_user_page.analytics::json
	)
	RETURNING *;
$$;

DROP FUNCTION article_api.update_read_progress(
	user_page_id bigint,
	read_state integer[]
);
CREATE FUNCTION article_api.update_read_progress(
	user_page_id bigint,
	read_state integer[],
	analytics text
)
RETURNS core.user_page
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
   -- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT sum(n)
		FROM unnest(read_state) AS n
		WHERE n > 0
	);
    -- local user_page
	current_user_page user_page;
BEGIN
    -- read and lock the existing user_page
    SELECT *
    INTO locals.current_user_page
	FROM user_page
	WHERE user_page.id = update_read_progress.user_page_id
	FOR UPDATE;
	-- only update if more words have been read
	IF words_read > locals.current_user_page.words_read
	THEN
		-- update the progress
		UPDATE user_page
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = utc_now(),
		    analytics = update_read_progress.analytics::json
		WHERE user_page.id = update_read_progress.user_page_id
		RETURNING *
		INTO locals.current_user_page;
		-- check if this update completed the page
		IF
			locals.current_user_page.date_completed IS NULL AND
			(
				SELECT article_api.get_percent_complete(
					locals.current_user_page.readable_word_count,
					locals.words_read
				) >= 90
			)
		THEN
			-- set date_completed
			UPDATE user_page
			SET date_completed = user_page.last_modified
			WHERE user_page.id = update_read_progress.user_page_id
			RETURNING *
			INTO locals.current_user_page;
			-- update the cached article read count
			UPDATE article
			SET read_count = read_count + 1
			WHERE id = (
					SELECT article_id
					FROM page
					WHERE id = locals.current_user_page.page_id
				);
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_page;
END;
$$;

DROP FUNCTION article_api.create_comment(
	text text,
	article_id bigint,
	parent_comment_id bigint,
	user_account_id bigint
);
CREATE FUNCTION article_api.create_comment(
	text text,
	article_id bigint,
	parent_comment_id bigint,
	user_account_id bigint,
	analytics text
)
RETURNS SETOF article_api.user_comment
LANGUAGE plpgsql
AS $$
DECLARE
	comment_id bigint;
BEGIN
	-- insert the new comment, saving the id
	INSERT INTO comment
        (text, article_id, parent_comment_id, user_account_id, analytics)
	VALUES
    	(text, article_id, parent_comment_id, user_account_id, analytics::json)
	RETURNING id INTO comment_id;
	-- update the cached article comment count
	UPDATE article
	SET comment_count = comment_count + 1
	WHERE id = article_id;
	-- return the user_comment
	RETURN QUERY
	SELECT *
	FROM article_api.user_comment
	WHERE id = comment_id;
END;
$$;

-- create new analytics schema
CREATE SCHEMA analytics;

CREATE FUNCTION analytics.get_key_metrics(
	start_date timestamp,
	end_date timestamp
)
RETURNS TABLE (
    day timestamp,
    user_accounts_app_count bigint,
    user_accounts_browser_count bigint,
    user_accounts_unknown_count bigint,
    reads_app_count bigint,
    reads_browser_count bigint,
    reads_unknown_count bigint,
    comments_app_count bigint,
    comments_browser_count bigint,
    comments_unknown_count bigint
)
LANGUAGE SQL
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
				user_page
				JOIN range ON user_page.date_completed >= range.day AND user_page.date_completed < range.next_day
			GROUP BY range.day
		) AS reads ON reads.day = range.day
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE
					analytics->'client'->>'mode' = 'App' OR
					analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				comment
				JOIN range ON comment.date_created >= range.day AND comment.date_created < range.next_day
			GROUP BY range.day
		) AS comments ON comments.day = range.day
	ORDER BY range.day DESC;
$$;