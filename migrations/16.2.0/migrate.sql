-- add community read column to article
ALTER TABLE
    core.article
ADD COLUMN
    community_read_timestamp timestamp;

-- set initial community_read_timestamp values
WITH dated_community_read AS (
    SELECT
        article.id AS article_id,
        least(
            second_read.date_completed,
            min(rating.timestamp),
            min(comment.date_created),
            min(silent_post.date_created)
        ) AS community_read_timestamp
    FROM
        core.article
        LEFT JOIN (
            SELECT
                user_article.article_id,
                user_article.date_completed,
                row_number() OVER (
                    PARTITION BY
                        user_article.article_id
                    ORDER BY
                        user_article.date_completed
                ) AS read_number
            FROM
                core.user_article
            WHERE
                user_article.date_completed IS NOT NULL
        ) AS second_read ON
            second_read.article_id = article.id AND
            second_read.read_number = 2
        LEFT JOIN core.rating ON
            rating.article_id = article.id
        LEFT JOIN core.comment ON
            comment.article_id = article.id
        LEFT JOIN core.silent_post ON
            silent_post.article_id = article.id
    GROUP BY
        article.id,
        second_read.date_completed
    HAVING
        count(second_read.*) > 0 OR
        count(rating.*) > 0 OR
        count(comment.*) > 0 OR
        count(silent_post.*) > 0
)
UPDATE
    core.article
SET
    community_read_timestamp = dated_community_read.community_read_timestamp
FROM
    dated_community_read
WHERE
    article.id = dated_community_read.article_id;

-- add index to community_read_timestamp
CREATE INDEX
    article_community_read_timestamp_idx
ON
    core.article (community_read_timestamp DESC);

-- update api functions to set community_read_timestamp values
CREATE OR REPLACE FUNCTION article_api.update_read_progress(
    user_article_id bigint,
    read_state integer[],
    analytics text
)
RETURNS core.user_article
LANGUAGE plpgsql
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
		    unnest(update_read_progress.read_state) AS n
		WHERE
		    n > 0
	);
	-- local user_article
	current_user_article user_article;
	-- progress since last commit
	words_read_since_last_commit int;
BEGIN
    -- read and lock the existing user_article
	SELECT
	    *
	INTO
	    locals.current_user_article
	FROM
	    core.user_article
	WHERE
	    user_article.id = update_read_progress.user_article_id
	FOR UPDATE;
	-- only update if more words have been read
	IF locals.words_read > locals.current_user_article.words_read THEN
	   	-- calculate the words read since the last commit
	   	locals.words_read_since_last_commit = locals.words_read - locals.current_user_article.words_read;
		-- update the progress
	   	INSERT INTO
	   	    core.user_article_progress (
	   	        user_account_id,
	   	        article_id,
	   	        period,
	   	        words_read,
	   	        client_type
	   	    )
	   	VALUES (
	   		locals.current_user_article.user_account_id,
	   	 	locals.current_user_article.article_id,
            (
                date_trunc('hour', locals.utc_now) +
                make_interval(mins => floor(extract('minute' FROM locals.utc_now) / 15)::int * 15)
            ),
	   		locals.words_read_since_last_commit,
	   		update_read_progress.analytics::json->'client'->'type'
		)
		ON CONFLICT (
		    user_account_id,
		    article_id,
		    period
		)
		DO UPDATE SET
		    words_read = user_article_progress.words_read + locals.words_read_since_last_commit;
	  	-- update the user_article
		UPDATE
		    core.user_article
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = locals.utc_now,
			analytics = update_read_progress.analytics::json
		WHERE
		    user_article.id = update_read_progress.user_article_id
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
			    core.user_article
			SET
			    date_completed = user_article.last_modified
			WHERE
			    user_article.id = update_read_progress.user_article_id
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
                )
			WHERE
			    article.id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_article;
END;
$$;

CREATE OR REPLACE FUNCTION article_api.rate_article(
    article_id bigint,
    user_account_id bigint,
    score core.rating_score
)
RETURNS SETOF core.rating
LANGUAGE plpgsql
STRICT
AS $$
<<locals>>
DECLARE
    new_rating core.rating;
BEGIN
    -- insert the new rating
    INSERT INTO
		core.rating (
			score,
			article_id,
			user_account_id
		)
	VALUES (
		rate_article.score,
		rate_article.article_id,
		rate_article.user_account_id
	)
	RETURNING
		*
	INTO
		locals.new_rating;
    -- cache the updated article rating stats and set the community_read_timestamp if necessary
    UPDATE
		core.article
	SET
		average_rating_score = current_rating_stats.average_rating_score,
		rating_count = current_rating_stats.rating_count,
	    community_read_timestamp = (
	        CASE WHEN
	            article.community_read_timestamp IS NULL
	        THEN
	            core.utc_now()
	        ELSE
	            article.community_read_timestamp
	        END
        )
    FROM
        (
            SELECT
                current_rating.article_id,
                avg(current_rating.score) AS average_rating_score,
                count(*) AS rating_count
            FROM
                article_api.user_article_rating AS current_rating
            WHERE
                current_rating.article_id = rate_article.article_id
            GROUP BY
                current_rating.article_id
        ) AS current_rating_stats
	WHERE
		article.id = current_rating_stats.article_id;
    -- return the new rating
    RETURN NEXT locals.new_rating;
END;
$$;

CREATE OR REPLACE FUNCTION social.create_comment(
    text text,
    article_id bigint,
    parent_comment_id bigint,
    user_account_id bigint,
    analytics text
)
RETURNS SETOF social.comment
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    comment_id bigint;
BEGIN
    -- create the new comment
    INSERT INTO
		core.comment (
			text,
			article_id,
			parent_comment_id,
			user_account_id,
			analytics
		)
	VALUES (
		create_comment.text,
		create_comment.article_id,
		create_comment.parent_comment_id,
		create_comment.user_account_id,
		create_comment.analytics::json
	)
	RETURNING
		id
	INTO
	    locals.comment_id;
    -- update cached article columns and set community_read_timestamp if necessary
    UPDATE
		core.article
	SET
		comment_count = article.comment_count + 1,
		first_poster_id = (
			CASE WHEN
				article.first_poster_id IS NULL AND
				create_comment.parent_comment_id IS NULL
			THEN
				create_comment.user_account_id
			ELSE
				article.first_poster_id
			END
		),
	    community_read_timestamp = (
	        CASE WHEN
	            article.community_read_timestamp IS NULL
	        THEN
	            core.utc_now()
	        ELSE
	            article.community_read_timestamp
	        END
        )
	WHERE
		article.id = create_comment.article_id;
    -- return the new comment from the view
    RETURN QUERY
	SELECT
	    *
	FROM
		social.comment
	WHERE
	    comment.id = locals.comment_id;
END;
$$;

CREATE OR REPLACE FUNCTION social.create_silent_post(
    user_account_id bigint,
    article_id bigint,
    analytics text
)
RETURNS SETOF core.silent_post
LANGUAGE plpgsql
AS $$
BEGIN
    -- update cached article columns and set community_read_timestamp if necessary
    UPDATE
        core.article
    SET
        silent_post_count = article.silent_post_count + 1,
        first_poster_id = (
            CASE WHEN
                article.first_poster_id IS NULL
            THEN
                create_silent_post.user_account_id
            ELSE
                article.first_poster_id
            END
        ),
        community_read_timestamp = (
            CASE WHEN
                article.community_read_timestamp IS NULL
            THEN
                core.utc_now()
            ELSE
                article.community_read_timestamp
            END
        )
    WHERE
        article.id = create_silent_post.article_id;
    -- insert and return silent_post
    RETURN QUERY
    INSERT INTO
        core.silent_post (
    		article_id,
    	 	user_account_id,
    	 	analytics
    	)
    VALUES (
		create_silent_post.article_id,
		create_silent_post.user_account_id,
		create_silent_post.analytics::jsonb
	)
	RETURNING
	    *;
END;
$$;

-- update community_read view to use new column
CREATE OR REPLACE VIEW community_reads.community_read AS
SELECT
    article.id,
    article.aotd_timestamp,
    article.word_count,
    article.hot_score,
    article.top_score,
    article.comment_count,
    article.read_count,
    article.average_rating_score,
    article.date_published,
    article.source_id,
    article.community_read_timestamp
FROM
    core.article
WHERE
    article.community_read_timestamp IS NOT NULL;

-- add api function to get new community reads
CREATE FUNCTION community_reads.get_new_aotd_contenders(
    user_account_id bigint,
    page_number integer,
    page_size integer,
    min_length integer,
    max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
AS $$
    WITH aotd_contender AS (
        SELECT
            community_read.id,
            community_read.community_read_timestamp
        FROM
        	community_reads.community_read
        WHERE
        	community_read.aotd_timestamp IS NULL AND
			core.matches_article_length(
				community_read.word_count,
			    get_new_aotd_contenders.min_length,
			    get_new_aotd_contenders.max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        aotd_contender
		) AS total_count
    FROM
		article_api.get_articles(
			get_new_aotd_contenders.user_account_id,
			VARIADIC ARRAY(
				SELECT
					aotd_contender.id
				FROM
					aotd_contender
				ORDER BY
					aotd_contender.community_read_timestamp DESC
				OFFSET
					(get_new_aotd_contenders.page_number - 1) * get_new_aotd_contenders.page_size
				LIMIT
					get_new_aotd_contenders.page_size
			)
		) AS articles;
$$;

-- clean up unused api functions and indexes
DROP FUNCTION community_reads.get_highest_rated(
    user_account_id bigint,
    page_number integer,
    page_size integer,
    since_date timestamp,
    min_length integer,
    max_length integer
);

DROP FUNCTION community_reads.get_most_commented(
    user_account_id bigint,
    page_number integer,
    page_size integer,
    since_date timestamp,
    min_length integer,
    max_length integer
);

DROP FUNCTION community_reads.get_most_read(
    user_account_id bigint,
    page_number integer,
    page_size integer,
    since_date timestamp,
    min_length integer,
    max_length integer
);

DROP INDEX article_average_rating_score_idx;

DROP INDEX article_comment_count_idx;

DROP INDEX article_read_count_idx;

DROP INDEX article_silent_post_count_idx;

-- update article statistics for new index
ANALYZE core.article;