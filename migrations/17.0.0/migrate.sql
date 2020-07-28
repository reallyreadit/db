-- existing feed/notification query functions are deprecated
-- social.get_posts_from_followees
-- social.get_posts_from_inbox

-- create new query function for posts from followees and loopbacks
CREATE FUNCTION social.get_notification_posts(
    user_id bigint,
    page_number int,
    page_size int
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH notification_post AS (
	    -- followee post
	    SELECT
	    	followee_post.article_id,
	        followee_post.user_account_id,
	        followee_post.date_created,
	        followee_post.comment_id,
	        followee_post.comment_text,
	        followee_post.comment_addenda,
	        followee_post.silent_post_id,
	        followee_post.date_deleted
	    FROM
	    	social.post AS followee_post
	    	JOIN social.active_following ON
	    	    active_following.followee_user_account_id = followee_post.user_account_id AND
	    	    active_following.follower_user_account_id = get_notification_posts.user_id AND
	    	    followee_post.date_deleted IS NULL
	    UNION ALL
	    -- loopback comment
	    SELECT
	        loopback.article_id,
	        loopback.user_account_id,
	        loopback.date_created,
	        loopback.id AS comment_id,
	        loopback.text AS comment_text,
	        loopback.addenda AS comment_addenda,
	        NULL::bigint AS silent_post_id,
	        loopback.date_deleted
	    FROM
	        social.comment AS loopback
	        JOIN core.user_article AS completed_article ON
	            completed_article.article_id = loopback.article_id AND
	            completed_article.date_completed < loopback.date_created AND
	            loopback.parent_comment_id IS NULL AND
	            loopback.user_account_id != completed_article.user_account_id AND
	            loopback.date_deleted IS NULL AND
	            completed_article.user_account_id = get_notification_posts.user_id
	        LEFT JOIN social.active_following ON
	            active_following.followee_user_account_id = loopback.user_account_id AND
	            active_following.follower_user_account_id = completed_article.user_account_id
	    WHERE
	        active_following.id IS NULL
	),
	paginated_post AS (
	    SELECT
	    	notification_post.*
	    FROM
	    	notification_post
	    ORDER BY
			notification_post.date_created DESC
		OFFSET
			(get_notification_posts.page_number - 1) * get_notification_posts.page_size
		LIMIT
			get_notification_posts.page_size
	)
    SELECT
		article.*,
		paginated_post.date_created,
		user_account.name,
		paginated_post.comment_id,
		paginated_post.comment_text,
        paginated_post.comment_addenda,
        paginated_post.silent_post_id,
        paginated_post.date_deleted,
		(
			alert.comment_id IS NOT NULL OR
			alert.silent_post_id IS NOT NULL
		) AS has_alert,
		(
		    SELECT
		    	count(notification_post.*)
		    FROM
		        notification_post
		) AS total_count
	FROM
		article_api.get_articles(
			get_notification_posts.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT paginated_post.article_id
				FROM
				    paginated_post
			)
		) AS article
		JOIN paginated_post ON
		    paginated_post.article_id = article.id
		JOIN user_account ON
		    user_account.id = paginated_post.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id,
		        data.silent_post_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt AS receipt ON
		    	    receipt.event_id = event.id AND
		    	    event.type IN ('post', 'loopback') AND
		    	    receipt.user_account_id = get_notification_posts.user_id AND
                    receipt.date_alert_cleared IS NULL
		    	JOIN notification_data AS data ON
		    	    data.event_id = event.id AND
		    	    (
                        data.comment_id IN (
                            SELECT
                                paginated_post.comment_id
                            FROM
                                paginated_post
                        ) OR
                        data.silent_post_id IN (
                            SELECT
                                paginated_post.silent_post_id
                            FROM
                                paginated_post
                        )
                    )
		) AS alert ON (
		    alert.comment_id = paginated_post.comment_id OR
		    alert.silent_post_id = paginated_post.silent_post_id
		)
    ORDER BY
    	paginated_post.date_created DESC
$$;

-- create new query function for replies
CREATE FUNCTION social.get_reply_posts(
    user_id bigint,
    page_number int,
    page_size int
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH reply AS (
	    SELECT
	    	reply.id,
	        reply.date_created,
	        reply.text,
	        reply.addenda,
	        reply.article_id,
	        reply.user_account_id,
	        reply.date_deleted
	    FROM
	    	core.comment AS parent
	    	JOIN social.comment AS reply ON
	    	    reply.parent_comment_id = parent.id AND
                parent.user_account_id = get_reply_posts.user_id AND
                reply.user_account_id != get_reply_posts.user_id AND
                reply.date_deleted IS NULL
	),
	paginated_reply AS (
	    SELECT
	    	reply.*
	    FROM
	    	reply
	    ORDER BY
			reply.date_created DESC
		OFFSET
			(get_reply_posts.page_number - 1) * get_reply_posts.page_size
		LIMIT
			get_reply_posts.page_size
	)
    SELECT
		article.*,
		paginated_reply.date_created,
		user_account.name,
		paginated_reply.id,
		paginated_reply.text,
        paginated_reply.addenda,
        NULL::bigint,
        paginated_reply.date_deleted,
        alert.comment_id IS NOT NULL,
		(
		    SELECT
		    	count(reply.*)
		    FROM
		        reply
		) AS total_count
	FROM
		article_api.get_articles(
			get_reply_posts.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT paginated_reply.article_id
				FROM
				    paginated_reply
			)
		) AS article
		JOIN paginated_reply ON
		    paginated_reply.article_id = article.id
		JOIN user_account ON
		    user_account.id = paginated_reply.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt AS receipt ON
		    	    receipt.event_id = event.id AND
		    	    event.type = 'reply' AND
                    receipt.user_account_id = get_reply_posts.user_id AND
                    receipt.date_alert_cleared IS NULL
		    	JOIN notification_data AS data ON
		    	    data.event_id = event.id AND
		    	    data.comment_id IN (
                        SELECT
                            paginated_reply.id
                        FROM
                            paginated_reply
                    )
		) AS alert ON
		    alert.comment_id = paginated_reply.id
    ORDER BY
    	paginated_reply.date_created DESC
$$;

-- add slug to tag
-- remove unique name constraint before normalizing
ALTER TABLE
    core.tag
DROP CONSTRAINT
    tag_name_key;
-- split comma-separated tags
-- step 1: create new individual tags from comma-separated tags and assign to articles
WITH comma_tag AS (
    SELECT
        tag.id AS original_tag_id,
        nextval('core.tag_id_seq') AS new_tag_id,
        trim(
            unnest(
                regexp_split_to_array(tag.name, ',(?![^(]*\))')
            )
        ) AS new_tag_name
    FROM
        core.tag
    WHERE
        tag.name LIKE '%,%,%'
),
new_tag AS (
    INSERT INTO
        core.tag(
            id,
            name
        )
    SELECT
        comma_tag.new_tag_id,
        comma_tag.new_tag_name
    FROM
        comma_tag
    RETURNING
        id,
        name
)
INSERT INTO
    core.article_tag (
        article_id,
        tag_id
    )
SELECT
    article_tag.article_id,
    comma_tag.new_tag_id
FROM
    comma_tag
    JOIN article_tag ON
        article_tag.tag_id = comma_tag.original_tag_id;
-- step 2: delete article_tags referencing comma tags (delete orphaned tag later on using index)
DELETE FROM
    core.article_tag
USING
    (
        SELECT
            tag.id
        FROM
            core.tag
        WHERE
            tag.name LIKE '%,%,%'
    ) AS comma_tag
WHERE
    article_tag.tag_id = comma_tag.id;
-- remove tag/topic prefix
UPDATE
    core.tag
SET
    name = regexp_replace(tag.name, '^\W*t(ag|opic)\W*', '', 'i')
WHERE
    tag.name ~* '^\W*t(ag|opic)(?!\s*\w)';
-- below cleanup process is mostly copied from author cleanup in 16.0.0 migration
-- stage 1: cleanup of existing tag names
-- step 1: replace general whitespace chars with SP
UPDATE
    core.tag
SET
    name = regexp_replace(
        tag.name,
        '[\u0009-\u000D\u0085\u00A0\u2000-\u200A\u2028\u2029\u202F\u205F]',
        ' ',
        'g'
    )
WHERE
    tag.name ~ '[\u0009-\u000D\u0085\u00A0\u2000-\u200A\u2028\u2029\u202F\u205F]';
-- step 2: remove control and joiner chars
UPDATE
    core.tag
SET
    name = regexp_replace(
        tag.name,
        '[\u0000-\u001F\u007F\u0080-\u009F\u200B-\u200D\u2060\uFEFF]',
        '',
        'g'
    )
WHERE
    tag.name ~ '[\u0000-\u001F\u007F\u0080-\u009F\u200B-\u200D\u2060\uFEFF]';
-- step 3: replace punctuation connector chars with SP
UPDATE
    core.tag
SET
    name = regexp_replace(
        tag.name,
        '[\u005F\u203F\u2040\u2054\uFE33\uFE34\uFE4D\uFE4E\uFE4F\uFF3F]',
        ' ',
        'g'
    )
WHERE
    tag.name ~ '[\u005F\u203F\u2040\u2054\uFE33\uFE34\uFE4D\uFE4E\uFE4F\uFF3F]';
-- step 4: merge contiguous whitespace
UPDATE
    core.tag
SET
    name = regexp_replace(
        tag.name,
        '\s+',
        ' ',
        'g'
    )
WHERE
    tag.name ~ '\s{2,}';
-- step 5: trim whitespace
UPDATE
    core.tag
SET
    name = trim(tag.name)
WHERE
    tag.name ~ '^\s' OR
    tag.name ~ '\s$';
-- step 6: delete if name doesn't contain at least one word char (delete orphaned tag later on using index)
DELETE FROM
    core.article_tag
WHERE
    article_tag.tag_id IN (
        SELECT
            tag.id
        FROM
            core.tag
        WHERE
            tag.name ~ '^(\W|_)*$'
    );

-- stage 2: assign slug
-- step 1: add slug column to tag table
ALTER TABLE
    core.tag
ADD COLUMN
    slug text;
-- step 2: assign slug
UPDATE
    core.tag
SET
    slug = lower(
        trim(
            '-' FROM regexp_replace(
                tag.name,
                '(\W|_)+',
                '-',
                'g'
            )
        )
    )
WHERE
    TRUE;

-- stage 3: merge tags based on slug
-- step 1: create temporary reference view
CREATE TEMPORARY VIEW merged_tag AS
SELECT DISTINCT ON (tag.slug)
    tag.id,
    tag.slug
FROM
    core.tag
    JOIN (
        SELECT
            tag.slug
        FROM
            core.tag
        GROUP BY
            tag.slug
        HAVING
            count(*) > 1
    ) AS duplicate_tag ON
        tag.slug = duplicate_tag.slug
ORDER BY
    tag.slug,
    -- prefer the shortest name in order to cut down on noise
    length(tag.name);
-- step 2: delete redundant article_tags
WITH slugged_article_tag AS (
    SELECT
        article_tag.article_id,
        article_tag.tag_id,
        tag.slug AS tag_slug
    FROM
        core.article_tag
        JOIN core.tag ON
            tag.id = article_tag.tag_id
),
duplicate AS (
    SELECT
        slugged_article_tag.article_id,
        merged_tag.id AS primary_tag_id,
        slugged_article_tag.tag_slug
    FROM
        slugged_article_tag
        JOIN merged_tag ON
            merged_tag.slug = slugged_article_tag.tag_slug
    GROUP BY
        slugged_article_tag.article_id,
        slugged_article_tag.tag_slug,
        merged_tag.id
    HAVING
        count(*) > 1
)
DELETE FROM
    core.article_tag
WHERE
    (article_id, tag_id) IN (
        SELECT
            slugged_article_tag.article_id,
            slugged_article_tag.tag_id
        FROM
            slugged_article_tag
            JOIN duplicate ON
                duplicate.article_id = slugged_article_tag.article_id AND
                duplicate.tag_slug = slugged_article_tag.tag_slug
        WHERE
            slugged_article_tag.tag_id != duplicate.primary_tag_id
    );
-- step 3: merge tags
WITH duplicate_article_tag AS (
    SELECT
        article_tag.article_id,
        article_tag.tag_id,
        merged_tag.id AS merged_tag_id
    FROM
        core.article_tag
        JOIN core.tag ON
            tag.id = article_tag.tag_id
        JOIN merged_tag ON
            merged_tag.slug = tag.slug AND
            merged_tag.id != article_tag.tag_id
)
UPDATE
    core.article_tag
SET
    tag_id = duplicate_article_tag.merged_tag_id
FROM
    duplicate_article_tag
WHERE
    article_tag.article_id = duplicate_article_tag.article_id AND
    article_tag.tag_id = duplicate_article_tag.tag_id;
-- step 4: drop reference view
DROP VIEW merged_tag;
-- step 5: delete orphaned tags (keep index for future tag deletions)
CREATE INDEX
    article_tag_tag_id_idx ON
        core.article_tag (tag_id);

WITH orphaned_tag AS (
    SELECT
        tag.id
    FROM
        core.tag
        LEFT JOIN core.article_tag ON
            article_tag.tag_id = tag.id
    WHERE
        article_tag.article_id IS NULL
)
DELETE FROM
    core.tag
USING
    orphaned_tag
WHERE
    tag.id = orphaned_tag.id;

-- stage 4: enforce slug is unique and not null
ALTER TABLE
    core.tag
ALTER COLUMN
    slug SET NOT NULL;

ALTER TABLE
    core.tag
ADD CONSTRAINT
    tag_slug_key UNIQUE (slug);

-- create new tag merge api function
CREATE FUNCTION
    article_api.merge_tags(
        target_slug text,
        VARIADIC source_slugs text[]
    )
RETURNS bigint[]
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    tagged_article_ids bigint[];
BEGIN
    -- delete all source and target article_tags in order to prevent duplicates
    WITH deleted_article_tag AS (
        DELETE FROM
            core.article_tag
        USING
            (
                SELECT
                    tag.id
                FROM
                    core.tag
                WHERE
                    tag.slug = ANY (merge_tags.source_slugs) OR
                    tag.slug = merge_tags.target_slug
            ) AS merge_tag
        WHERE
            article_tag.tag_id = merge_tag.id
        RETURNING
            article_tag.article_id
    )
    SELECT
        array_agg(DISTINCT deleted_article_tag.article_id)
    FROM
        deleted_article_tag
    INTO
        locals.tagged_article_ids;
    -- insert article_tags for target tag
    INSERT INTO
        core.article_tag (
            article_id,
            tag_id
        )
    SELECT
        tagged_article.id,
        (
            SELECT
                tag.id
            FROM
                core.tag
            WHERE
                tag.slug = merge_tags.target_slug
        )
    FROM
        unnest(locals.tagged_article_ids) AS tagged_article (id);
    -- delete source tags
    DELETE FROM
        core.tag
    WHERE
        tag.slug = ANY (merge_tags.source_slugs);
    -- return articles
    RETURN
        locals.tagged_article_ids;
END;
$$;

-- update tag reconciliation
CREATE TYPE article_api.tag_metadata AS (
    name text,
    slug text
);

DROP FUNCTION article_api.create_article(
    title text,
    slug text,
    source_id bigint,
    date_published timestamp,
    date_modified timestamp,
    section text,
    description text,
    authors article_api.author_metadata[],
    tags text[]
);

CREATE FUNCTION article_api.create_article(
    title text,
    slug text,
    source_id bigint,
    date_published timestamp,
    date_modified timestamp,
    section text,
    description text,
    authors article_api.author_metadata[],
    tags article_api.tag_metadata[]
)
RETURNS bigint
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
	article_id bigint;
    current_author article_api.author_metadata;
	current_author_id bigint;
	current_tag article_api.tag_metadata;
	current_tag_id bigint;
BEGIN
	INSERT INTO
	    core.article (
            title,
            slug,
            source_id,
            date_published,
            date_modified,
            section,
            description
        )
	VALUES (
	    create_article.title,
	    create_article.slug,
	    create_article.source_id,
	    create_article.date_published,
	    create_article.date_modified,
	    create_article.section,
	    create_article.description
	)
	RETURNING
	    id
	INTO
	    locals.article_id;
	FOREACH locals.current_author IN ARRAY create_article.authors LOOP
		SELECT
		    author.id
		INTO
		    locals.current_author_id
		FROM
		    core.author
		WHERE
		    author.slug = locals.current_author.slug
		FOR UPDATE;
		IF locals.current_author_id IS NULL THEN
			INSERT INTO
			    core.author (
                    name,
                    url,
                    slug
                )
			VALUES (
			    locals.current_author.name,
			    locals.current_author.url,
			    locals.current_author.slug
			)
			RETURNING
			    id
			INTO
			    locals.current_author_id;
		END IF;
		INSERT INTO
		    core.article_author (
                article_id,
                author_id
            )
		VALUES (
		    locals.article_id,
		    locals.current_author_id
		);
	END LOOP;
	FOREACH locals.current_tag IN ARRAY create_article.tags LOOP
		SELECT
		    tag.id
		INTO
		    locals.current_tag_id
		FROM
		    core.tag
		WHERE
		    tag.slug = locals.current_tag.slug
		FOR UPDATE;
		IF locals.current_tag_id IS NULL THEN
			INSERT INTO
			    core.tag (
			        name,
			        slug
			    )
			VALUES (
			    locals.current_tag.name,
			    locals.current_tag.slug
			)
			RETURNING
			    id
			INTO
			    locals.current_tag_id;
		END IF;
		INSERT INTO
		    core.article_tag (
		        article_id,
		        tag_id
		    )
		VALUES (
		    locals.article_id,
		    locals.current_tag_id
		);
	END LOOP;
	RETURN
	    locals.article_id;
END;
$$;

-- create search options api function
CREATE FUNCTION community_reads.get_search_options()
RETURNS TABLE (
    category text,
    name text,
    slug text,
    score bigint
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        'author',
        top_author.name,
        top_author.slug,
        top_author.score
    FROM
        stats.get_top_author_leaderboard(
            max_rank => 50,
            since_date => core.utc_now() - '30 days'::interval
        ) AS top_author
    UNION ALL
    (
        SELECT
            'tag',
            tag.name,
            tag.slug,
            count(*)
        FROM
            core.tag
            JOIN core.article_tag ON
                article_tag.tag_id = tag.id
            JOIN community_reads.community_read ON
                community_read.id = article_tag.article_id
            JOIN core.user_article ON
                user_article.article_id = community_read.id AND
                user_article.date_completed IS NOT NULL
        GROUP BY
            tag.id
        ORDER BY
            count(*) DESC
        LIMIT
            50
    )
    UNION ALL
    (
        SELECT
            'source',
            source.name,
            source.slug,
            count(*)
        FROM
            core.source
            JOIN community_reads.community_read ON
                community_read.source_id = source.id
            JOIN core.user_article ON
                user_article.article_id = community_read.id AND
                user_article.date_completed IS NOT NULL
        GROUP BY
            source.id
        ORDER BY
            count(*) DESC
        LIMIT
            50
    );
$$;

-- add new timestamp columns to article
ALTER TABLE
    core.article
ADD COLUMN
    latest_read_timestamp timestamp;

ALTER TABLE
    core.article
ADD COLUMN
    latest_post_timestamp timestamp;

-- set initial values
UPDATE
    core.article
SET
    latest_read_timestamp = latest_read.date_completed
FROM
    (
        SELECT DISTINCT ON (
                user_article.article_id
            )
            user_article.article_id,
            user_article.date_completed
        FROM
            core.user_article
        WHERE
            user_article.date_completed IS NOT NULL
        ORDER BY
            user_article.article_id,
            user_article.date_completed DESC
    ) AS latest_read
WHERE
    article.id = latest_read.article_id;

UPDATE
    core.article
SET
    latest_post_timestamp = latest_post.date_created
FROM
    (
        SELECT DISTINCT ON (
                post.article_id
            )
            post.article_id,
            post.date_created
        FROM
            social.post
        ORDER BY
            post.article_id,
            post.date_created DESC
    ) AS latest_post
WHERE
    article.id = latest_post.article_id;

-- update api functions to update timestamps
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
                ),
			    latest_read_timestamp = locals.utc_now
			WHERE
			    article.id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_article;
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
        ),
	    latest_post_timestamp = (
	        CASE WHEN
				create_comment.parent_comment_id IS NULL
			THEN
				core.utc_now()
			ELSE
				article.latest_post_timestamp
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
        ),
        latest_post_timestamp = core.utc_now()
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
    article.community_read_timestamp,
    article.latest_read_timestamp,
    article.latest_post_timestamp
FROM
    core.article
WHERE
    article.community_read_timestamp IS NOT NULL;

-- create search api function
CREATE FUNCTION community_reads.search_articles(
    user_account_id bigint,
    page_number int,
    page_size int,
    source_slugs text[],
    author_slugs text[],
    tag_slugs text[],
    min_length int,
    max_length int
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH filtered_article AS (
        SELECT DISTINCT ON (
                community_read.id
            )
            community_read.id,
            community_read.latest_read_timestamp,
            community_read.latest_post_timestamp
        FROM
            community_reads.community_read
            JOIN core.source ON
                source.id = community_read.source_id
            LEFT JOIN core.article_author ON
                article_author.article_id = community_read.id
            LEFT JOIN core.author ON
                author.id = article_author.author_id
            LEFT JOIN core.article_tag ON
                article_tag.article_id = community_read.id
            LEFT JOIN core.tag ON
                tag.id = article_tag.tag_id
        WHERE
            CASE WHEN array_length(search_articles.source_slugs, 1) > 0
                THEN
                    source.slug = ANY (search_articles.source_slugs)
                ELSE
                    TRUE
            END AND
            CASE WHEN array_length(search_articles.author_slugs, 1) > 0
                THEN
                    author.slug = ANY (search_articles.author_slugs)
                ELSE
                    TRUE
            END AND
            CASE WHEN array_length(search_articles.tag_slugs, 1) > 0
                THEN
                    tag.slug = ANY (search_articles.tag_slugs)
                ELSE
                    TRUE
            END AND
			core.matches_article_length(
				community_read.word_count,
			    search_articles.min_length,
			    search_articles.max_length
			)
        ORDER BY
            community_read.id
    )
    SELECT
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        filtered_article
		)
    FROM
		article_api.get_articles(
			search_articles.user_account_id,
			VARIADIC ARRAY(
				SELECT
					filtered_article.id
				FROM
					filtered_article
				ORDER BY
					filtered_article.latest_post_timestamp DESC NULLS LAST,
				    filtered_article.latest_read_timestamp DESC,
				    filtered_article.id DESC
				OFFSET
					(search_articles.page_number - 1) * search_articles.page_size
				LIMIT
					search_articles.page_size
			)
		) AS articles;
$$;