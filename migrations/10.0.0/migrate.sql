-- cleanup unused comment objects
DROP FUNCTION article_api.list_replies(
	user_account_id bigint,
	page_number integer,
	page_size integer
);
DROP FUNCTION article_api.read_comment(
	comment_id bigint
);
DROP TYPE article_api.user_comment_page_result;

-- add new comment editing tables
CREATE TABLE core.comment_revision (
  	id bigserial PRIMARY KEY,
  	date_created timestamp NOT NULL DEFAULT core.utc_now(),
  	comment_id bigint NOT NULL REFERENCES core.comment (id),
  	original_text_content text
);

CREATE TABLE core.comment_addendum (
  	id bigserial PRIMARY KEY,
  	date_created timestamp NOT NULL DEFAULT core.utc_now(),
  	comment_id bigint NOT NULL REFERENCES core.comment (id),
  	text_content text
);

-- add new date_deleted column
ALTER TABLE
	core.comment
ADD COLUMN
	date_deleted timestamp;

-- create new social.comment view to replace article_api.user_comment
CREATE TYPE social.comment_addendum AS (
	date_created timestamp,
    text_content text
);
CREATE VIEW social.comment AS (
	SELECT
		comment.id,
		comment.date_created,
		comment.text,
		comment.article_id,
		article.title AS article_title,
		article.slug AS article_slug,
		comment.user_account_id,
		user_account.name AS user_account,
		comment.parent_comment_id,
		coalesce(
			array_agg(
				(
					addendum.date_created,
					addendum.text_content
				)::social.comment_addendum
			) FILTER (WHERE addendum.id IS NOT NULL),
			'{}'
		) AS addenda,
	    comment.date_deleted
	FROM
		core.comment
	JOIN
		core.article
		    ON article.id = comment.article_id
	JOIN
		core.user_account
		    ON user_account.id = comment.user_account_id
	LEFT JOIN
		core.comment_addendum AS addendum
			ON addendum.comment_id = comment.id
	GROUP BY
		comment.id,
	    article.id,
	    user_account.id
);

-- create new edit/delete functions
CREATE FUNCTION social.revise_comment(
	comment_id bigint,
	revised_text text
)
RETURNS SETOF social.comment
LANGUAGE plpgsql
AS $$
BEGIN
	-- create the revision
    INSERT INTO
        core.comment_revision (
            comment_id,
            original_text_content
        )
    SELECT
    	comment.id,
        comment.text
    FROM
        core.comment
    WHERE
    	comment.id = revise_comment.comment_id
    FOR UPDATE;
    -- update the comment
	UPDATE
	    core.comment
	SET
		text = revise_comment.revised_text
	WHERE
		comment.id = revise_comment.comment_id;
    -- return from the view
    RETURN QUERY
    SELECT
    	*
    FROM
    	social.comment
    WHERE
    	id = revise_comment.comment_id;
END;
$$;
CREATE FUNCTION social.create_comment_addendum(
	comment_id bigint,
	text_content text
)
RETURNS SETOF social.comment
LANGUAGE plpgsql
AS $$
BEGIN
	-- create the addendum
	INSERT INTO
        core.comment_addendum (
        	comment_id,
        	text_content
        )
    VALUES (
    	create_comment_addendum.comment_id,
        create_comment_addendum.text_content
    );
	-- return from the view
	RETURN QUERY
    SELECT
    	*
    FROM
    	social.comment
    WHERE
    	id = create_comment_addendum.comment_id;
END;
$$;
CREATE FUNCTION social.delete_comment(
	comment_id bigint
)
RETURNS SETOF social.comment
LANGUAGE plpgsql
AS $$
BEGIN
	-- mark the comment as deleted
	UPDATE
	    core.comment
	SET
		date_deleted = core.utc_now()
	WHERE
		comment.id = delete_comment.comment_id;
	-- return from the view
	RETURN QUERY
    SELECT
    	*
    FROM
    	social.comment
    WHERE
    	id = delete_comment.comment_id;
END;
$$;

-- move/retarget create_, get_ and list_ comment(s)
DROP FUNCTION article_api.create_comment(
	text text,
	article_id bigint,
	parent_comment_id bigint,
	user_account_id bigint,
	analytics text
);
CREATE FUNCTION social.create_comment(
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
		id INTO locals.comment_id;
    -- update cached article columns
    UPDATE
		core.article
	SET
		comment_count = comment_count + 1,
		first_poster_id = (
			CASE WHEN
				first_poster_id IS NULL AND create_comment.parent_comment_id IS NULL
			THEN
				create_comment.user_account_id
			ELSE
				first_poster_id
			END
		)
	WHERE
		id = create_comment.article_id;
    -- return the new comment from the view
    RETURN QUERY
	SELECT
	    *
	FROM
		social.comment
	WHERE
	    id = locals.comment_id;
END;
$$;

DROP FUNCTION article_api.get_comment(
	comment_id bigint
);
CREATE FUNCTION social.get_comment(
	comment_id bigint
)
RETURNS SETOF social.comment
LANGUAGE sql
AS $$
	SELECT
	    *
	FROM
	    social.comment
	WHERE
	    id = get_comment.comment_id;
$$;

DROP FUNCTION article_api.list_comments(
	article_id bigint
);
CREATE FUNCTION social.get_comments(
	article_id bigint
)
RETURNS SETOF social.comment
LANGUAGE sql
AS $$
	SELECT
	    *
	FROM
	    social.comment
	WHERE
	    article_id = get_comments.article_id;
$$;

-- drop notifications and social functions that return comment data
DROP FUNCTION notifications.create_loopback_digest_notifications(
	frequency text
);
DROP FUNCTION notifications.create_post_digest_notifications(
	frequency text
);
DROP FUNCTION notifications.create_reply_digest_notifications(
	frequency text
);
DROP FUNCTION social.get_posts_from_followees(
	user_id bigint,
	page_number integer,
	page_size integer,
	min_length integer,
	max_length integer
);
DROP FUNCTION social.get_posts_from_inbox(
	user_id bigint,
	page_number integer,
	page_size integer
);
DROP FUNCTION social.get_posts_from_user(
	viewer_user_id bigint,
	subject_user_name text,
	page_size integer,
	page_number integer
);

-- drop functions and views that reference social.post view
DROP FUNCTION article_api.get_articles(user_account_id bigint, VARIADIC article_ids bigint[]);
DROP VIEW stats.scouting;

-- drop and recreate the return types for the comment data returning functions above
DROP TYPE notifications.comment_digest_dispatch;
CREATE TYPE notifications.comment_digest_dispatch AS (
	receipt_id bigint,
	user_account_id bigint,
	user_name text,
	email_address text,
	comment_id bigint,
	comment_date_created timestamp without time zone,
	comment_text text,
    comment_addenda social.comment_addendum[],
	comment_author text,
	comment_article_id bigint,
	comment_article_title text
);
DROP TYPE notifications.post_digest_dispatch;
CREATE TYPE notifications.post_digest_dispatch AS (
	receipt_id bigint,
	user_account_id bigint,
	user_name text,
	email_address text,
	post_comment_id bigint,
	post_silent_post_id bigint,
	post_date_created timestamp without time zone,
	post_comment_text text,
    post_comment_addenda social.comment_addendum[],
	post_author text,
	post_article_id bigint,
	post_article_title text
);
DROP TYPE social.article_post_page_result;
CREATE TYPE social.article_post_page_result AS (
	id bigint,
	title text,
	slug text,
	source text,
	date_published timestamp without time zone,
	section text,
	description text,
	aotd_timestamp timestamp without time zone,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	comment_count bigint,
	read_count bigint,
	date_created timestamp without time zone,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp without time zone,
	average_rating_score numeric,
	rating_score core.rating_score,
	dates_posted timestamp without time zone[],
	hot_score integer,
	hot_velocity numeric,
	rating_count integer,
	first_poster text,
	flair core.article_flair,
	post_date_created timestamp without time zone,
	user_name text,
	comment_id bigint,
	comment_text text,
    comment_addenda social.comment_addendum[],
	silent_post_id bigint,
    date_deleted timestamp without time zone,
	has_alert boolean,
	total_count bigint
);

-- drop and recreate social.post view to include comment addenda and date_deleted
DROP VIEW social.post;
CREATE VIEW social.post AS (
	SELECT
		comment.article_id,
		comment.user_account_id,
		comment.date_created,
		comment.id AS comment_id,
		comment.text AS comment_text,
	    comment.addenda AS comment_addenda,
		NULL::bigint AS silent_post_id,
	    comment.date_deleted AS date_deleted
	FROM
		social.comment
	WHERE
		comment.parent_comment_id IS NULL
	UNION ALL
	SELECT
		silent_post.article_id,
		silent_post.user_account_id,
		silent_post.date_created,
		NULL::bigint AS comment_id,
		NULL::text AS comment_text,
	    NULL::social.comment_addendum[] AS comment_addenda,
		silent_post.id AS silent_post_id,
	    NULL::timestamp without time zone AS date_deleted
	FROM
		 core.silent_post
);

-- recreate functions and views that reference social.post view
CREATE FUNCTION article_api.get_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.article
LANGUAGE sql
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
		user_article_rating.score,
	    coalesce(posts.dates, '{}'),
	    article.hot_score,
		0.0,
	    article.rating_count,
	    first_poster.name,
	    article.flair
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
			user_article.article_id = article.id
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
		LEFT JOIN (
			SELECT
				article_id,
				array_agg(date_created) AS dates
		    FROM
		    	social.post
		    WHERE
		    	article_id = ANY (get_articles.article_ids) AND
		        user_account_id = get_articles.user_account_id
			GROUP BY
				article_id
		) AS posts
			ON posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster
			ON first_poster.id = article.first_poster_id
	ORDER BY
	    array_position(article_ids, article.id)
$$;
CREATE VIEW stats.scouting AS (
	SELECT
	    article.id AS article_id,
		article.aotd_timestamp,
		post.user_account_id
	FROM
	    core.article
	JOIN social.post
	    ON post.article_id = article.id
	LEFT JOIN
	    social.post earlier_post
	    ON (
	    	earlier_post.article_id = post.article_id AND
	    	earlier_post.date_created < post.date_created
	    )
	WHERE
	    article.aotd_timestamp IS NOT NULL AND
	    earlier_post.date_created IS NULL
);

-- recreate the above comment data returning notifications functions to exclude deleted comments and include addenda
CREATE FUNCTION notifications.create_loopback_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.comment_digest_dispatch
LANGUAGE sql
AS $$
    WITH loopback AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        loopback.id AS comment_id,
	        loopback.date_created AS date_created,
	        loopback.text AS comment_text,
    	    loopback.addenda AS comment_addenda,
	        loopback_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON (
					recipient.id = preference.user_account_id AND
					preference.loopback_digest_via_email = create_loopback_digest_notifications.frequency::core.notification_event_frequency
				)
			JOIN core.user_article
			    ON (
			        user_article.user_account_id = recipient.id AND
			        user_article.date_completed IS NOT NULL
			    )
			JOIN core.article
			    ON article.id = user_article.article_id
			JOIN social.comment AS loopback
			    ON (
					loopback.article_id = article.id AND
					loopback.user_account_id != recipient.id AND
					loopback.parent_comment_id IS NULL AND
					loopback.date_created >= (
						CASE create_loopback_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
					) AND
					loopback.date_deleted IS NULL
				)
			JOIN core.user_account AS loopback_author
			    ON loopback_author.id = loopback.user_account_id
			LEFT JOIN social.active_following
			    ON (
					active_following.follower_user_account_id = recipient.id AND
					active_following.followee_user_account_id = loopback_author.id
				)
		WHERE
		    active_following.id IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	loopback
	),
    loopback_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_loopback_digest_notifications.frequency
				WHEN 'daily' THEN 'loopback_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'loopback_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				loopback_event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    loopback_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			loopback.comment_id
		FROM
			recipient_event
        	JOIN loopback
        		ON loopback.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        loopback.recipient_id,
        loopback.recipient_name,
        loopback.recipient_email,
        loopback.comment_id,
		loopback.date_created,
		loopback.comment_text,
        loopback.comment_addenda,
		loopback.author,
        loopback.article_id,
        loopback.article_title
    FROM
    	receipt
        JOIN loopback
    		ON loopback.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_post_digest_notifications(frequency text) RETURNS SETOF notifications.post_digest_dispatch
    LANGUAGE sql
    AS $$
    WITH post AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        post.comment_id AS comment_id,
    	    post.silent_post_id AS silent_post_id,
	        post.date_created AS date_created,
	        post.comment_text AS comment_text,
    	    post.comment_addenda AS comment_addenda,
	        post_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN social.active_following
			    ON active_following.follower_user_account_id = preference.user_account_id
			JOIN social.post
			    ON post.user_account_id = active_following.followee_user_account_id
			JOIN core.article
			    ON article.id = post.article_id
	    	JOIN core.user_account AS post_author
	    		ON post_author.id = post.user_account_id
		WHERE
			preference.post_digest_via_email = create_post_digest_notifications.frequency::core.notification_event_frequency AND
		    post.date_created >= (
		        CASE create_post_digest_notifications.frequency
					WHEN 'daily' THEN core.utc_now() - '1 day'::interval
					WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
				END
		    ) AND
		    post.date_deleted IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	post
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	 CASE create_post_digest_notifications.frequency
				WHEN 'daily' THEN 'post_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'post_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
			recipient_event.event_id,
			post.comment_id,
		    post.silent_post_id
		FROM
			recipient_event
        	JOIN post
        		ON post.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        post.recipient_id,
        post.recipient_name,
        post.recipient_email,
        post.comment_id,
        post.silent_post_id,
		post.date_created,
		post.comment_text,
        post.comment_addenda,
		post.author,
        post.article_id,
        post.article_title
    FROM
    	receipt
        JOIN post
    		ON post.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_reply_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.comment_digest_dispatch
LANGUAGE sql
AS $$
    WITH reply AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        reply.id AS comment_id,
	        reply.date_created AS comment_date_created,
	        reply.text AS comment_text,
    	    reply.addenda AS comment_addenda,
	        reply_author.name AS comment_author_name,
    	    article.id AS comment_article_id,
    	    article.title AS comment_article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN core.comment
			    ON comment.user_account_id = preference.user_account_id
	    	JOIN social.comment AS reply
	    		ON (
	    		    reply.parent_comment_id = comment.id AND
	    		    reply.user_account_id != preference.user_account_id AND
	    		    reply.date_created >= (
	    		        CASE create_reply_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
	    		    ) AND
	    		    reply.date_deleted IS NULL
	    		)
			JOIN core.article
			    ON article.id = reply.article_id
	    	JOIN core.user_account AS reply_author
	    		ON reply_author.id = reply.user_account_id
		WHERE
			preference.reply_digest_via_email = create_reply_digest_notifications.frequency::core.notification_event_frequency
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	reply
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_reply_digest_notifications.frequency
				WHEN 'daily' THEN 'reply_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'reply_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			reply.comment_id
		FROM
			recipient_event
        	JOIN reply
        		ON reply.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        reply.recipient_id,
        reply.recipient_name,
        reply.recipient_email,
        reply.comment_id,
		reply.comment_date_created,
		reply.comment_text,
        reply.comment_addenda,
		reply.comment_author_name,
        reply.comment_article_id,
        reply.comment_article_title
    FROM
    	receipt
        JOIN reply
    		ON reply.recipient_id = receipt.user_account_id;
$$;

-- recreate the above comment data returning social functions to exclude deleted comments and include addenda and date_deleted
CREATE FUNCTION social.get_posts_from_followees(
	user_id bigint,
	page_number integer,
	page_size integer,
	min_length integer,
	max_length integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH followee_post AS (
	    SELECT
	    	post.article_id,
	        post.user_account_id,
	        post.date_created,
	        post.comment_id,
	        post.comment_text,
	        post.comment_addenda,
	        post.silent_post_id,
	        post.date_deleted
	    FROM
	    	social.post
	    	JOIN core.article ON article.id = post.article_id
	    	JOIN social.active_following ON active_following.followee_user_account_id = post.user_account_id
	    WHERE
	        post.date_deleted IS NULL AND
	    	active_following.follower_user_account_id = get_posts_from_followees.user_id AND
	        core.matches_article_length(
				article.word_count,
				get_posts_from_followees.min_length,
				get_posts_from_followees.max_length
			)
	),
	paginated_post AS (
	    SELECT
	    	*
	    FROM
	    	followee_post
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_followees.page_number - 1) * get_posts_from_followees.page_size
		LIMIT
			get_posts_from_followees.page_size
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
		    	count(*)
		    FROM
		        followee_post
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_followees.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    paginated_post
			)
		) AS article
		JOIN paginated_post ON paginated_post.article_id = article.id
		JOIN user_account ON user_account.id = paginated_post.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id,
		        data.silent_post_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt ON notification_receipt.event_id = event.id
		    	JOIN notification_data AS data ON data.event_id = event.id
		    WHERE
		    	event.type = 'post' AND
		        notification_receipt.user_account_id = get_posts_from_followees.user_id AND
		        notification_receipt.date_alert_cleared IS NULL AND
		        (
		            data.comment_id IN (
						SELECT
							comment_id
						FROM
							paginated_post
					) OR
		            data.silent_post_id IN (
						SELECT
							silent_post_id
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
CREATE FUNCTION social.get_posts_from_inbox(
	user_id bigint,
	page_number integer,
	page_size integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH inbox_comment AS (
	    SELECT
	    	reply.id,
	        reply.date_created,
	        reply.text,
	        reply.addenda,
	        reply.article_id,
	        reply.user_account_id,
	        reply.date_deleted
	    FROM
	    	core.comment
	    	JOIN social.comment AS reply ON reply.parent_comment_id = comment.id
	    WHERE
	    	comment.user_account_id = get_posts_from_inbox.user_id AND
	        reply.user_account_id != get_posts_from_inbox.user_id AND
	        reply.date_deleted IS NULL
	    UNION ALL
	    SELECT
	    	comment.id,
	        comment.date_created,
	        comment.text,
	        comment.addenda,
	        comment.article_id,
	        comment.user_account_id,
	        comment.date_deleted
	    FROM
	    	core.user_article
	    	JOIN social.comment ON comment.article_id = user_article.article_id
	    WHERE
	    	user_article.user_account_id = get_posts_from_inbox.user_id AND
	    	user_article.date_completed IS NOT NULL AND
	        comment.user_account_id != get_posts_from_inbox.user_id AND
	        comment.parent_comment_id IS NULL AND
	        comment.date_created > user_article.date_completed AND
	        comment.date_deleted IS NULL
	),
	paginated_inbox_comment AS (
	    SELECT
	    	*
	    FROM
	    	inbox_comment
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_inbox.page_number - 1) * get_posts_from_inbox.page_size
		LIMIT
			get_posts_from_inbox.page_size
	)
    SELECT
		article.*,
		paginated_inbox_comment.date_created,
		user_account.name,
		paginated_inbox_comment.id,
		paginated_inbox_comment.text,
        paginated_inbox_comment.addenda,
        NULL::bigint,
        paginated_inbox_comment.date_deleted,
        alert.comment_id IS NOT NULL,
		(
		    SELECT
		    	count(*)
		    FROM
		        inbox_comment
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_inbox.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    paginated_inbox_comment
			)
		) AS article
		JOIN paginated_inbox_comment ON paginated_inbox_comment.article_id = article.id
		JOIN user_account ON user_account.id = paginated_inbox_comment.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt ON notification_receipt.event_id = event.id
		    	JOIN notification_data AS data ON data.event_id = event.id
		    WHERE
		    	(
		    	    event.type = 'reply' OR
		    	    event.type = 'loopback'
		    	) AND
		        notification_receipt.user_account_id = get_posts_from_inbox.user_id AND
		        notification_receipt.date_alert_cleared IS NULL AND
				data.comment_id IN (
					SELECT
						id
					FROM
						paginated_inbox_comment
				)
		) AS alert ON alert.comment_id = paginated_inbox_comment.id
    ORDER BY
    	paginated_inbox_comment.date_created DESC
$$;
CREATE FUNCTION social.get_posts_from_user(
	viewer_user_id bigint,
	subject_user_name text,
	page_size integer,
	page_number integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
    WITH subject_user_account AS (
        SELECT
        	id
        FROM
        	user_account_api.get_user_account_id_by_name(get_posts_from_user.subject_user_name) AS user_account (id)
	),
	user_post AS (
	    SELECT
	    	post.article_id,
	        post.user_account_id,
	        post.date_created,
	        post.comment_id,
	        post.comment_text,
	        post.comment_addenda,
	        post.silent_post_id,
	        post.date_deleted
	    FROM
	    	social.post
	    WHERE
	    	post.user_account_id = (
	    		SELECT
	    		    id
	    		FROM
	    			subject_user_account
	    	) AND
	        post.date_deleted IS NULL
	    ORDER BY
			post.date_created DESC
		OFFSET
			(get_posts_from_user.page_number - 1) * get_posts_from_user.page_size
		LIMIT
			get_posts_from_user.page_size
	)
    SELECT
		article.*,
		user_post.date_created,
		(
		    SELECT
		    	name
		    FROM
		        user_account
		    WHERE
		    	id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		) AS user_name,
		user_post.comment_id,
		user_post.comment_text,
        user_post.comment_addenda,
        user_post.silent_post_id,
        user_post.date_deleted,
        FALSE AS has_alert,
		(
		    SELECT
		    	count(*)
		    FROM
		        social.post
		    WHERE
		    	user_account_id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_user.viewer_user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    user_post
			)
		) AS article
		JOIN user_post ON user_post.article_id = article.id
    ORDER BY
    	user_post.date_created DESC
$$;

-- drop unused view article_api.user_comment
DROP VIEW article_api.user_comment;

-- drop unused date_read column
ALTER TABLE
	core.comment
DROP COLUMN
	date_read;