-- add date_orientation_completed to confirm orientation
ALTER TABLE
    core.user_account
ADD COLUMN
    date_orientation_completed timestamp;

-- set all existing users as having completed orientation
UPDATE
    core.user_account
SET
    date_orientation_completed = date_created
WHERE
    TRUE;

-- create new function to mark orientation as completed
CREATE FUNCTION
    user_account_api.register_orientation_completion(
        user_account_id bigint
    )
RETURNS SETOF
    core.user_account
LANGUAGE
    sql
AS $$
    UPDATE
        core.user_account
    SET
        date_orientation_completed = core.utc_now()
    WHERE
        user_account.id = register_orientation_completion.user_account_id AND
        user_account.date_orientation_completed IS NULL
    RETURNING
        *;
$$;

-- add new tables for provisional reading activity
CREATE TABLE
    core.provisional_user_account (
        id bigserial PRIMARY KEY,
        date_created timestamp NOT NULL DEFAULT core.utc_now(),
        date_merged timestamp,
        merged_user_account_id bigint REFERENCES core.user_account (id),
        creation_analytics jsonb
    );

ALTER TABLE
    core.provisional_user_account
ADD CONSTRAINT
    provisional_user_account_merge_check
CHECK (
    (
        date_merged IS NULL AND
        merged_user_account_id IS NULL
    ) OR
    (
        date_merged IS NOT NULL AND
        merged_user_account_id IS NOT NULL
    )
);

CREATE TABLE
    core.provisional_user_article (
        article_id bigint NOT NULL REFERENCES core.article (id),
        provisional_user_account_id bigint NOT NULL REFERENCES core.provisional_user_account (id),
        date_created timestamp NOT NULL DEFAULT core.utc_now(),
        last_modified timestamp,
        read_state int[] NOT NULL,
        words_read int NOT NULL DEFAULT 0,
        date_completed timestamp,
        readable_word_count int NOT NULL,
        analytics jsonb,
        PRIMARY KEY (
            article_id,
            provisional_user_account_id
        )
    );

CREATE TABLE
    core.provisional_user_article_progress (
        provisional_user_account_id bigint NOT NULL REFERENCES core.provisional_user_account (id),
        article_id bigint NOT NULL REFERENCES core.article (id),
        period timestamp NOT NULL,
        words_read int NOT NULL,
        client_type text,
        PRIMARY KEY (
            provisional_user_account_id,
            article_id,
            period
        )
    );

-- create new function to create provisional user accounts
CREATE FUNCTION
    user_account_api.create_provisional_user_account(
        analytics text
    )
RETURNS SETOF
    core.provisional_user_account
LANGUAGE
    sql
AS $$
    INSERT INTO
        core.provisional_user_account (
            creation_analytics
        )
    VALUES (
        create_provisional_user_account.analytics::jsonb
    )
    RETURNING
        *;
$$;

-- create parallel functions for provisional reading activity
CREATE FUNCTION
    article_api.create_provisional_user_article(
        article_id bigint,
        provisional_user_account_id bigint,
        readable_word_count integer,
        analytics text
    )
RETURNS
    core.provisional_user_article
LANGUAGE
    sql
AS $$
	INSERT INTO
	    core.provisional_user_article (
            article_id,
            provisional_user_account_id,
            read_state,
            readable_word_count,
            analytics
        )
	VALUES (
		create_provisional_user_article.article_id,
		create_provisional_user_article.provisional_user_account_id,
		ARRAY[-create_provisional_user_article.readable_word_count],
		create_provisional_user_article.readable_word_count,
	    create_provisional_user_article.analytics::jsonb
	)
	RETURNING
	    *;
$$;

CREATE FUNCTION
    article_api.get_provisional_user_article(
        article_id bigint,
        provisional_user_account_id bigint
    )
RETURNS SETOF
    core.provisional_user_article
LANGUAGE
    sql
STABLE
AS $$
	SELECT
	    *
	FROM
	    core.provisional_user_article AS user_article
	WHERE
		user_article.article_id = get_provisional_user_article.article_id AND
		user_article.provisional_user_account_id = get_provisional_user_article.provisional_user_account_id;
$$;

CREATE FUNCTION
    article_api.update_provisional_read_progress(
        provisional_user_account_id bigint,
        article_id bigint,
        read_state int[],
        analytics text
    )
RETURNS
    core.provisional_user_article
LANGUAGE
    plpgsql
AS $$
<<locals>>
DECLARE
   	-- utc timestamp
   	utc_now CONSTANT timestamp NOT NULL := utc_now();
   	-- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT
		    sum(n)
		FROM
		    unnest(update_provisional_read_progress.read_state) AS n
		WHERE
		    n > 0
	);
	-- local user_article
	current_user_article core.provisional_user_article;
	-- progress since last commit
	words_read_since_last_commit int;
BEGIN
    -- read and lock the existing provisional_user_article
	SELECT
	    *
	INTO
	    locals.current_user_article
	FROM
	    core.provisional_user_article
	WHERE
	    provisional_user_article.provisional_user_account_id = update_provisional_read_progress.provisional_user_account_id AND
        provisional_user_article.article_id = update_provisional_read_progress.article_id
	FOR UPDATE;
	-- only update if more words have been read
	IF locals.words_read > locals.current_user_article.words_read THEN
	   	-- calculate the words read since the last commit
	   	locals.words_read_since_last_commit = locals.words_read - locals.current_user_article.words_read;
		-- update the progress
	   	INSERT INTO
	   	    core.provisional_user_article_progress (
	   	        provisional_user_account_id,
	   	        article_id,
	   	        period,
	   	        words_read,
	   	        client_type
	   	    )
	   	VALUES (
	   		locals.current_user_article.provisional_user_account_id,
	   	 	locals.current_user_article.article_id,
            (
                date_trunc('hour', locals.utc_now) +
                make_interval(mins => floor(extract('minute' FROM locals.utc_now) / 15)::int * 15)
            ),
	   		locals.words_read_since_last_commit,
	   		update_provisional_read_progress.analytics::json->'client'->'type'
		)
		ON CONFLICT
		    ON CONSTRAINT
		        provisional_user_article_progress_pkey
		DO UPDATE SET
		    words_read = provisional_user_article_progress.words_read + locals.words_read_since_last_commit;
	  	-- update the provisional_user_article
		UPDATE
		    core.provisional_user_article
		SET
			read_state = update_provisional_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = locals.utc_now,
			analytics = update_provisional_read_progress.analytics::jsonb
		WHERE
		    provisional_user_article.provisional_user_account_id = update_provisional_read_progress.provisional_user_account_id AND
            provisional_user_article.article_id = update_provisional_read_progress.article_id
		RETURNING
		    *
		INTO
		    locals.current_user_article;
		-- check if this update completed the page
		IF
			locals.current_user_article.date_completed IS NULL AND
			article_api.get_percent_complete(locals.current_user_article.readable_word_count, locals.words_read) >= 90
		THEN
			-- set date_completed
			UPDATE
			    core.provisional_user_article
			SET
			    date_completed = provisional_user_article.last_modified
			WHERE
			    provisional_user_article.provisional_user_account_id = update_provisional_read_progress.provisional_user_account_id AND
                provisional_user_article.article_id = update_provisional_read_progress.article_id
			RETURNING
			    *
			INTO
			    locals.current_user_article;
			-- update the cached article read count and set community_read_timestamp if necessary
			UPDATE
			    core.article
			SET
			    read_count = article.read_count + 1,
			    community_read_timestamp = (
			        CASE WHEN
			            article.community_read_timestamp IS NULL AND
			            article.read_count = 1
			        THEN
			            locals.utc_now
			        ELSE
			            article.community_read_timestamp
			        END
                ),
			    latest_read_timestamp = locals.utc_now
			WHERE
			    article.id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN
	    locals.current_user_article;
END;
$$;

CREATE FUNCTION
    article_api.get_article_for_provisional_user(
        article_id bigint,
        provisional_user_account_id bigint
    )
RETURNS SETOF
    article_api.article
LANGUAGE
    sql
STABLE
AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1],
		coalesce(article_authors.names, '{}'),
		coalesce(article_tags.names, '{}'),
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		provisional_user_article.date_created,
	    coalesce(
           article_api.get_percent_complete(
              provisional_user_article.readable_word_count,
              provisional_user_article.words_read
           ),
           0
        ),
	    provisional_user_article.date_completed IS NOT NULL,
		NULL::timestamp,
		article.average_rating_score,
		NULL::core.rating_score,
	    ARRAY[]::timestamp[],
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank
	FROM
		core.article
		JOIN
		    article_api.article_pages ON
                article_pages.article_id = article.id
		JOIN
		    core.source ON
		        source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names
		    FROM
		        core.article_author
		        JOIN
		            core.author ON
		                author.id = article_author.author_id
		    WHERE
		        article_author.article_id = get_article_for_provisional_user.article_id
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN
		    article_api.article_tags ON
                article_tags.article_id = article.id
		LEFT JOIN
		    core.provisional_user_article ON
		        provisional_user_article.article_id = article.id AND
                provisional_user_article.provisional_user_account_id = get_article_for_provisional_user.provisional_user_account_id
		LEFT JOIN
		    core.user_account AS first_poster ON
		        first_poster.id = article.first_poster_id
	WHERE
        article.id = get_article_for_provisional_user.article_id;
$$;

-- create function to merge provisional account with non-provisional account
CREATE FUNCTION
    user_account_api.merge_provisional_user_account(
        provisional_user_account_id bigint,
        user_account_id bigint
    )
RETURNS SETOF
    core.provisional_user_account
LANGUAGE
    plpgsql
AS $$
BEGIN
    -- check to make sure the provisional account hasn't already been merged
    IF
        (
            SELECT
                provisional_user_account.merged_user_account_id
            FROM
                core.provisional_user_account
            WHERE
                provisional_user_account.id = merge_provisional_user_account.provisional_user_account_id
            FOR UPDATE
        )
        IS NOT NULL
    THEN
        RAISE EXCEPTION
            'Account has already been merged.'
        USING
            ERRCODE = 'RU001';
    END IF;
    -- merge user articles
    INSERT INTO
        core.user_article (
            article_id,
            user_account_id,
            date_created,
            last_modified,
            read_state,
            words_read,
            date_completed,
            readable_word_count,
            analytics
        )
    SELECT
        provisional_user_article.article_id,
        merge_provisional_user_account.user_account_id,
        provisional_user_article.date_created,
        provisional_user_article.last_modified,
        provisional_user_article.read_state,
        provisional_user_article.words_read,
        provisional_user_article.date_completed,
        provisional_user_article.readable_word_count,
        provisional_user_article.analytics
    FROM
        core.provisional_user_article
        LEFT JOIN
            core.user_article AS conflicting_user_article ON
                conflicting_user_article.article_id = provisional_user_article.article_id AND
                conflicting_user_article.user_account_id = merge_provisional_user_account.user_account_id
    WHERE
        provisional_user_article.provisional_user_account_id = merge_provisional_user_account.provisional_user_account_id AND
        conflicting_user_article.id IS NULL;
    -- merge user article progress
    INSERT INTO
        core.user_article_progress (
            user_account_id,
            article_id,
            period,
            words_read,
            client_type
        )
    SELECT
        merge_provisional_user_account.user_account_id,
        provisional_user_article_progress.article_id,
        provisional_user_article_progress.period,
        provisional_user_article_progress.words_read,
        provisional_user_article_progress.client_type
    FROM
        core.provisional_user_article_progress
        LEFT JOIN
            core.user_article_progress AS conflicting_progress ON
                conflicting_progress.user_account_id = merge_provisional_user_account.user_account_id AND
                conflicting_progress.article_id = provisional_user_article_progress.article_id
    WHERE
        provisional_user_article_progress.provisional_user_account_id = merge_provisional_user_account.provisional_user_account_id AND
        conflicting_progress.id IS NULL;
    -- update and return provisional account
    RETURN QUERY
    UPDATE
        core.provisional_user_account
    SET
        date_merged = core.utc_now(),
        merged_user_account_id = merge_provisional_user_account.user_account_id
    WHERE
        provisional_user_account.id = merge_provisional_user_account.provisional_user_account_id AND
        provisional_user_account.merged_user_account_id IS NULL
    RETURNING
        *;
END;
$$;