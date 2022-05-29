-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
	Refactor the way articles and posts are queried.
*/

CREATE SCHEMA
	articles;

CREATE TYPE
	articles.article AS (
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
		rating_count integer,
		first_poster text,
		flair core.article_flair,
		aotd_contender_rank integer,
		article_authors article_api.article_author[],
		image_url text
	);

CREATE VIEW
	articles.article_pages AS
SELECT
	array_agg(page.url ORDER BY page.number) AS urls,
	count(*) AS count,
	sum(page.word_count) AS word_count,
	sum(page.readable_word_count) AS readable_word_count,
	page.article_id
FROM
	core.page
GROUP BY
	page.article_id;

CREATE VIEW
	articles.article_tags AS
SELECT
	array_agg(tag.name) AS names,
	article_tag.article_id
FROM
	core.tag
	JOIN
		core.article_tag ON
			article_tag.tag_id = tag.id
GROUP BY
	article_tag.article_id;

CREATE VIEW
	articles.user_article_rating AS
SELECT
	rating.article_id,
	rating.user_account_id,
	rating.score,
	rating.timestamp
FROM
	core.rating
	LEFT JOIN
		core.rating more_recent_rating ON
			rating.article_id = more_recent_rating.article_id AND
			rating.user_account_id = more_recent_rating.user_account_id AND
			rating.timestamp < more_recent_rating.timestamp
WHERE
	more_recent_rating.id IS NULL;

CREATE VIEW
	articles.primary_article_image AS
SELECT
	DISTINCT ON (
		article_image.article_id
	)
	article_image.article_id,
	article_image.url
FROM
	core.article_image
ORDER BY
	article_image.article_id,
	article_image.date_created DESC;

CREATE FUNCTION
	articles.get_percent_complete(
		readable_word_count numeric,
		words_read numeric
	)
RETURNS
	double precision
LANGUAGE
	sql
IMMUTABLE
AS $$
	SELECT greatest(
	   least(
	      (coalesce(words_read, 0)::double precision / greatest(coalesce(readable_word_count, 0), 1)) * 100,
	      100
	   ),
	   0
	);
$$;

-- move social.post to core.post to make room for article_post_page_result refactoring
CREATE VIEW
	core.post AS
SELECT
	comment.article_id,
	comment.user_account_id,
	comment.date_created,
	comment.id AS comment_id,
	comment.text AS comment_text,
	comment.addenda AS comment_addenda,
	NULL::bigint AS silent_post_id,
	comment.date_deleted
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
	silent_post.date_deleted
FROM
	core.silent_post;

CREATE OR REPLACE FUNCTION
	article_api.get_articles(
		user_account_id bigint,
		VARIADIC article_ids bigint[]
	)
RETURNS
	SETOF article_api.article
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
		user_article.date_created,
	    CASE WHEN article_authors.user_is_author
	        THEN 100
	        ELSE coalesce(
               article_api.get_percent_complete(
                  user_article.readable_word_count,
                  user_article.words_read
               ),
               0
            )
		END AS percent_complete,
	    CASE WHEN article_authors.user_is_author
	        THEN TRUE
	        ELSE user_article.date_completed IS NOT NULL
	    END AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score,
	    coalesce(posts.dates, '{}'),
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank,
	    coalesce(article_authors.authors, '{}')
	FROM
		core.article
		JOIN article_api.article_pages ON
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (get_articles.article_ids)
		JOIN source ON
		    source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        array_agg((author.name, author.slug)::article_api.article_author) AS authors,
		        count(author_user_account_assignment.id) > 0 AS user_is_author
		    FROM
		        core.article_author
		        JOIN core.author ON
		            author.id = article_author.author_id
		        LEFT JOIN author_user_account_assignment ON
		            author_user_account_assignment.author_id = author.id AND
		            author_user_account_assignment.user_account_id = get_articles.user_account_id
		    WHERE
		        article_author.article_id = ANY (get_articles.article_ids) AND
		        article_author.date_unassigned IS NULL
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN article_api.article_tags ON
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (get_articles.article_ids)
		LEFT JOIN core.user_article ON
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id
		LEFT JOIN core.star ON
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		LEFT JOIN article_api.user_article_rating ON
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (get_articles.article_ids)
		LEFT JOIN (
			SELECT
				post.article_id,
				array_agg(post.date_created) AS dates
		    FROM
		    	core.post
		    WHERE
		    	post.article_id = ANY (get_articles.article_ids) AND
		        post.user_account_id = get_articles.user_account_id
			GROUP BY
				post.article_id
		) AS posts ON
		    posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster ON
		    first_poster.id = article.first_poster_id
	ORDER BY
	    array_position(get_articles.article_ids, article.id)
$$;

CREATE OR REPLACE FUNCTION
	notifications.create_post_digest_notifications(
		frequency text
	)
RETURNS
	SETOF notifications.post_digest_dispatch
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
			JOIN core.post
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_post_digest_notifications.frequency
				WHEN 'daily' THEN 'post_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'post_weekly_digest'::core.notification_event_type
			END
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

CREATE OR REPLACE FUNCTION
	social.get_notification_posts(
		user_id bigint,
		page_number integer,
		page_size integer
	)
RETURNS
	SETOF social.article_post_page_result
LANGUAGE sql STABLE
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
	    	core.post AS followee_post
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

CREATE OR REPLACE FUNCTION
	social.get_posts_from_followees(
		user_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	SETOF social.article_post_page_result
LANGUAGE
	sql
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
	    	core.post
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

CREATE OR REPLACE FUNCTION
	social.get_posts_from_user(
		viewer_user_id bigint,
		subject_user_name text,
		page_size integer,
		page_number integer
	)
RETURNS
	SETOF social.article_post_page_result
LANGUAGE
	sql
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
	    	core.post
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
		        core.post
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

CREATE OR REPLACE VIEW
	stats.scouting AS
SELECT
	article.id AS article_id,
	article.aotd_timestamp,
	post.user_account_id
FROM
	core.article
	JOIN
		core.post ON post.article_id = article.id
   LEFT JOIN
   	core.post AS earlier_post ON
   		earlier_post.article_id = post.article_id AND
   		earlier_post.date_created < post.date_created
WHERE
	article.aotd_timestamp IS NOT NULL AND
	earlier_post.date_created IS NULL;

DROP VIEW
	social.post;

-- functions for user article
CREATE FUNCTION
	articles.get_articles(
		article_ids bigint[],
		user_account_id bigint
	)
RETURNS
	SETOF articles.article
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
		user_article.date_created,
		CASE WHEN
			article_authors.user_is_author
		THEN
			100
		ELSE
			coalesce(
				articles.get_percent_complete(
					user_article.readable_word_count,
					user_article.words_read
				),
				0
			)
		END AS percent_complete,
		CASE WHEN
			article_authors.user_is_author
		THEN
			TRUE
		ELSE
			user_article.date_completed IS NOT NULL
		END AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score,
		coalesce(posts.dates, '{}'),
		article.hot_score,
		article.rating_count,
		first_poster.name,
		article.flair,
		article.aotd_contender_rank,
		coalesce(article_authors.authors, '{}'),
		image.url
	FROM
		core.article
		JOIN articles.article_pages ON
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (get_articles.article_ids)
		JOIN source ON
		    source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        array_agg((author.name, author.slug)::article_api.article_author) AS authors,
		        count(author_user_account_assignment.id) > 0 AS user_is_author
		    FROM
		        core.article_author
		        JOIN core.author ON
		            author.id = article_author.author_id
		        LEFT JOIN author_user_account_assignment ON
		            author_user_account_assignment.author_id = author.id AND
		            author_user_account_assignment.user_account_id = get_articles.user_account_id
		    WHERE
		        article_author.article_id = ANY (get_articles.article_ids) AND
		        article_author.date_unassigned IS NULL
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN articles.article_tags ON
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (get_articles.article_ids)
		LEFT JOIN core.user_article ON
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id
		LEFT JOIN core.star ON
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		LEFT JOIN articles.user_article_rating ON
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (get_articles.article_ids)
		LEFT JOIN (
			SELECT
				post.article_id,
				array_agg(post.date_created) AS dates
		    FROM
		    	core.post
		    WHERE
		    	post.article_id = ANY (get_articles.article_ids) AND
		        post.user_account_id = get_articles.user_account_id
			GROUP BY
				post.article_id
		) AS posts ON
		    posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster ON
		    first_poster.id = article.first_poster_id
		LEFT JOIN
			articles.primary_article_image AS image ON
				article.id = image.article_id AND
				image.article_id = ANY (get_articles.article_ids)
	WHERE
		article.id = ANY (get_articles.article_ids)
	ORDER BY
	    array_position(get_articles.article_ids, article.id);
$$;

CREATE FUNCTION
	articles.get_article_by_id(
		article_id bigint,
		user_account_id bigint
	)
RETURNS
	SETOF articles.article
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		*
	FROM
		articles.get_articles(
			article_ids := ARRAY[get_article_by_id.article_id],
			user_account_id := get_article_by_id.user_account_id
		);
$$;

CREATE FUNCTION
	articles.get_article_by_slug(
		slug text,
		user_account_id bigint
	)
RETURNS
	SETOF articles.article
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		*
	FROM
		articles.get_articles(
			article_ids := ARRAY(
				SELECT
					article.id
				FROM
					core.article
				WHERE
					article.slug = get_article_by_slug.slug
			),
			user_account_id := get_article_by_slug.user_account_id
		);
$$;

-- function for provisional user article
CREATE FUNCTION
	articles.get_article_for_provisional_user(
		article_id bigint,
		provisional_user_account_id bigint
	)
RETURNS
	SETOF articles.article
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
			articles.get_percent_complete(
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
		article.aotd_contender_rank,
		coalesce(article_authors.authors, '{}'),
		image.url
	FROM
		core.article
		JOIN
		    articles.article_pages ON
                article_pages.article_id = article.id
		JOIN
		    core.source ON
		        source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        array_agg((author.name, author.slug)::article_api.article_author) AS authors
		    FROM
		        core.article_author
		        JOIN
		            core.author ON
		                author.id = article_author.author_id
		    WHERE
		        article_author.article_id = get_article_for_provisional_user.article_id AND
		        article_author.date_unassigned IS NULL
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN
		    articles.article_tags ON
                article_tags.article_id = article.id
		LEFT JOIN
		    core.provisional_user_article ON
		        provisional_user_article.article_id = article.id AND
                provisional_user_article.provisional_user_account_id = get_article_for_provisional_user.provisional_user_account_id
		LEFT JOIN
		    core.user_account AS first_poster ON
		        first_poster.id = article.first_poster_id
		LEFT JOIN
			articles.primary_article_image AS image ON
				article.id = image.article_id
	WHERE
        article.id = get_article_for_provisional_user.article_id;
$$;

-- functions returning single article id
CREATE FUNCTION
	community_reads.set_aotd_v1()
RETURNS
	bigint
LANGUAGE
	sql
AS $$
	UPDATE
		core.article
	SET
		aotd_timestamp = core.utc_now()
	WHERE
		article.id = (
			SELECT
				community_read.id
			FROM
				community_reads.community_read
			WHERE
				community_read.aotd_timestamp IS NULL
			ORDER BY
				community_read.hot_score DESC
			LIMIT
				1
		)
	RETURNING
		id;
$$;

-- functions returning SETOF bigint article ids
CREATE FUNCTION
	analytics.get_articles_requiring_author_assignments_v1()
RETURNS
	SETOF bigint
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		article.id
	FROM
		core.subscription_period AS period
		JOIN
			core.subscription ON
				period.provider = subscription.provider AND
				period.provider_subscription_id = subscription.provider_subscription_id AND
				period.date_refunded IS NULL
		JOIN
			core.subscription_account AS account ON
				subscription.provider = account.provider AND
				subscription.provider_account_id = account.provider_account_id AND
				account.environment = 'production'::core.subscription_environment
		JOIN
			core.user_article ON
				account.user_account_id = user_article.user_account_id AND
				period.begin_date <= user_article.date_completed AND
				period.renewal_grace_period_end_date > user_article.date_completed
		JOIN
			core.article ON
				user_article.article_id = article.id
		LEFT JOIN
			core.article_author ON
				user_article.article_id = article_author.article_id AND
				article_author.date_unassigned IS NULL
		LEFT JOIN
			core.author ON
				article_author.author_id = author.id
	WHERE
		article_author.article_id IS NULL OR
		author.slug IN ('condé-nast', 'nature-editorial') OR
		(
			author.name ILIKE '%,%' AND
			author.name NOT ILIKE '%, Inc.'
		) OR
		author.name ILIKE '% and %'
	ORDER BY
		article.word_count DESC;
$$;

CREATE FUNCTION
	community_reads.get_aotds(
		day_count integer
	)
RETURNS
	SETOF bigint
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		article.id
	FROM
		core.article
	ORDER BY
		article.aotd_timestamp DESC NULLS LAST
	LIMIT
		get_aotds.day_count;
$$;

-- functions returning paginated article ids
CREATE TYPE
	articles.article_ids_page AS (
		article_ids bigint[],
		total_count int
	);

CREATE FUNCTION
	articles.get_article_history(
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
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
				WHERE user_article.user_account_id = get_article_history.user_account_id
			) AS user_article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE star.user_account_id = get_article_history.user_account_id
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
		ARRAY (
			SELECT
				article_id
			FROM
				history_article
			ORDER BY
				history_date DESC
			OFFSET
				(page_number - 1) * page_size
			LIMIT
				page_size
		),
		(
			SELECT
				count(*)::int
			FROM
				history_article
		);
$$;

CREATE FUNCTION
	articles.get_articles_by_author_slug(
		slug text,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
	WITH author_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published,
			article.top_score
		FROM
			core.article
			JOIN
				core.article_author ON
					article.id = article_author.article_id
			JOIN
				core.author ON
					article_author.author_id = author.id
		WHERE
			author.slug = get_articles_by_author_slug.slug AND
			article_author.date_unassigned IS NULL AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_author_slug.min_length,
				max_length := get_articles_by_author_slug.max_length
			)
	)
	SELECT
		ARRAY(
			SELECT
				author_article.id
			FROM
				author_article
			ORDER BY
				author_article.top_score DESC,
				author_article.date_published DESC NULLS LAST,
				author_article.id DESC
			OFFSET
				(get_articles_by_author_slug.page_number - 1) * get_articles_by_author_slug.page_size
			LIMIT
				get_articles_by_author_slug.page_size
		),
		(
			SELECT
				count(*)::int
			FROM
				author_article
		);
$$;

CREATE FUNCTION
	articles.get_articles_by_source_slug(
		slug text,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
	WITH publisher_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published
		FROM
			core.article
		WHERE
			article.source_id = (
				SELECT
					source.id
				FROM
					core.source
				WHERE
					source.slug = get_articles_by_source_slug.slug
			) AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_source_slug.min_length,
				max_length := get_articles_by_source_slug.max_length
			)
	)
	SELECT
		ARRAY(
			SELECT
				publisher_article.id
			FROM
				publisher_article
			ORDER BY
				publisher_article.date_published DESC NULLS LAST
			OFFSET
				(get_articles_by_source_slug.page_number - 1) * get_articles_by_source_slug.page_size
			LIMIT
				get_articles_by_source_slug.page_size
		),
		(
			SELECT
				count(*)::int
			FROM
				publisher_article
		);
$$;

CREATE FUNCTION
	articles.get_starred_articles(
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
	WITH starred_article AS (
		SELECT
			article_id,
			date_starred
		FROM
			star
			JOIN article ON article.id = star.article_id
		WHERE
			star.user_account_id = get_starred_articles.user_account_id AND
		    core.matches_article_length(
				article.word_count,
				min_length,
				max_length
			)
	)
	SELECT
		ARRAY(
			SELECT
				article_id
			FROM
				starred_article
			ORDER BY
				date_starred DESC
			OFFSET
				(page_number - 1) * page_size
			LIMIT
				page_size
		),
		(
			SELECT
				count(*)::int
			FROM
				starred_article
		);
$$;

CREATE FUNCTION
	community_reads.get_aotd_history(
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
    WITH previous_aotd AS (
        SELECT
            id,
            aotd_timestamp
        FROM
        	core.article
        WHERE (
        	aotd_timestamp IS NOT NULL AND
        	aotd_timestamp IS DISTINCT FROM (
        	    SELECT
        	    	max(aotd_timestamp)
        	    FROM
        	    	core.article
			) AND
			core.matches_article_length(
				word_count,
			    min_length,
			    max_length
			)
		)
	)
    SELECT
    	ARRAY(
			SELECT
				id
			FROM
				previous_aotd
			ORDER BY
				aotd_timestamp DESC
			OFFSET
				(page_number - 1) * page_size
			LIMIT
				page_size
		),
		(
		    SELECT
		        count(*)::int
		    FROM
		        previous_aotd
		);
$$;

CREATE FUNCTION
	community_reads.get_hot(
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
    WITH hot_read AS (
        SELECT
            id,
            hot_score
        FROM
        	community_reads.community_read
        WHERE (
        	aotd_timestamp IS NULL AND
			hot_score > 0 AND
			core.matches_article_length(
				word_count,
			    min_length,
			    max_length
			)
		)
	)
    SELECT
    	ARRAY(
			SELECT
				id
			FROM
				hot_read
			ORDER BY
				hot_score DESC
			OFFSET
				(page_number - 1) * page_size
			LIMIT
				page_size
		),
		(
		    SELECT
		        count(*)::int
		    FROM
		        hot_read
		);
$$;

CREATE FUNCTION
	community_reads.get_new_aotd_contenders(
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
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
    	ARRAY(
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
		),
		(
		    SELECT
		        count(*)::int
		    FROM
		        aotd_contender
		);
$$;

CREATE FUNCTION
	community_reads.get_top(
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
STABLE
AS $$
    WITH top_read AS (
        SELECT
            id,
            top_score
        FROM community_reads.community_read
        WHERE (
			top_score > 0 AND
			core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		)
	)
    SELECT
    	ARRAY(
			SELECT
				id
			FROM
				top_read
			ORDER BY
				top_score DESC
			OFFSET
				(page_number - 1) * page_size
			LIMIT
				page_size
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		    	top_read
		);
$$;

CREATE FUNCTION
	community_reads.search_articles(
		page_number integer,
		page_size integer,
		source_slugs text[],
		author_slugs text[],
		tag_slugs text[],
		min_length integer,
		max_length integer
	)
RETURNS
	articles.article_ids_page
LANGUAGE
	sql
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
                    author.slug = ANY (search_articles.author_slugs) AND
                    article_author.date_unassigned IS NULL
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
    	ARRAY(
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
		),
		(
		    SELECT
		        count(*)::int
		    FROM
		        filtered_article
		);
$$;

-- functions returning paginated post ids
CREATE TYPE
	social.post_reference AS (
		comment_id bigint,
		silent_post_id bigint
	);

CREATE TYPE
	social.post_references_page AS (
		post_references social.post_reference[],
		total_count int
	);

CREATE TYPE
	social.post AS (
		date_created timestamp,
		user_name text,
		article_id bigint,
		comment_id bigint,
		comment_text text,
		comment_addenda social.comment_addendum[],
		silent_post_id bigint,
		date_deleted timestamp,
		has_alert bool
	);

CREATE FUNCTION
	social.get_posts(
		post_references social.post_reference[],
		user_account_id bigint,
		alert_event_types text[]
	)
RETURNS
	SETOF social.post
LANGUAGE
	plpgsql
STABLE
AS $$
<<locals>>
DECLARE
	comment_ids bigint[];
	silent_post_ids bigint[];
BEGIN
	SELECT
		array_agg(post_reference.comment_id),
		array_agg(post_reference.silent_post_id)
	FROM
		unnest(get_posts.post_references) AS post_reference (
			comment_id,
			silent_post_id
		)
	INTO
		locals.comment_ids,
		locals.silent_post_ids;
	RETURN QUERY
	WITH post AS (
		SELECT
			comment.article_id,
			comment.user_account_id,
			comment.date_created,
			comment.id AS comment_id,
			comment.text AS comment_text,
			comment.addenda AS comment_addenda,
			NULL::bigint AS silent_post_id,
			comment.date_deleted
		FROM
			social.comment
		WHERE
			comment.id = ANY (locals.comment_ids)
		UNION ALL
		SELECT
			silent_post.article_id,
			silent_post.user_account_id,
			silent_post.date_created,
			NULL::bigint AS comment_id,
			NULL::text AS comment_text,
			NULL::social.comment_addendum[] AS comment_addenda,
			silent_post.id AS silent_post_id,
			silent_post.date_deleted
		FROM
			core.silent_post
		WHERE
			silent_post.id = ANY (locals.silent_post_ids)
	),
	alert AS (
		SELECT
			data.comment_id,
			data.silent_post_id
		FROM
			notification_event AS event
			JOIN
				notification_receipt AS receipt ON
					event.id = receipt.event_id
			JOIN
				notification_data AS data ON
					event.id = data.event_id
		WHERE
			event.type = ANY (get_posts.alert_event_types::core.notification_event_type[]) AND
			receipt.user_account_id = get_posts.user_account_id AND
			receipt.date_alert_cleared IS NULL AND
			(
				data.comment_id = ANY (locals.comment_ids) OR
				data.silent_post_id = ANY (locals.silent_post_ids)
			)
	)
	SELECT
		post.date_created,
		user_account.name::text,
		post.article_id,
		post.comment_id,
		post.comment_text,
      post.comment_addenda,
      post.silent_post_id,
      post.date_deleted,
		(
			alert.comment_id IS NOT NULL OR
			alert.silent_post_id IS NOT NULL
		)
	FROM
		post
		JOIN
			user_account ON
				user_account.id = post.user_account_id
		LEFT JOIN
		    alert ON
				 alert.comment_id = post.comment_id OR
				 alert.silent_post_id = post.silent_post_id
	ORDER BY
		array_position(get_posts.post_references, (post.comment_id, post.silent_post_id)::social.post_reference);
END;
$$;

CREATE FUNCTION
	social.get_notification_posts_v1(
		user_id bigint,
		page_number integer,
		page_size integer
	)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH notification_post AS (
	    -- followee post
	    SELECT
			followee_post.date_created,
			followee_post.comment_id,
			followee_post.silent_post_id
	    FROM
	    	core.post AS followee_post
	    	JOIN social.active_following ON
	    	    active_following.followee_user_account_id = followee_post.user_account_id AND
	    	    active_following.follower_user_account_id = get_notification_posts_v1.user_id AND
	    	    followee_post.date_deleted IS NULL
	    UNION ALL
	    -- loopback comment
	    SELECT
			loopback.date_created,
			loopback.id AS comment_id,
			NULL::bigint AS silent_post_id
	    FROM
	        social.comment AS loopback
	        JOIN core.user_article AS completed_article ON
	            completed_article.article_id = loopback.article_id AND
	            completed_article.date_completed < loopback.date_created AND
	            loopback.parent_comment_id IS NULL AND
	            loopback.user_account_id != completed_article.user_account_id AND
	            loopback.date_deleted IS NULL AND
	            completed_article.user_account_id = get_notification_posts_v1.user_id
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
			(get_notification_posts_v1.page_number - 1) * get_notification_posts_v1.page_size
		LIMIT
			get_notification_posts_v1.page_size
	)
	SELECT
		(
			SELECT
				array_agg(
					(paginated_post.comment_id, paginated_post.silent_post_id)::social.post_reference
					ORDER BY
						paginated_post.date_created DESC
				)
			FROM
				paginated_post
		),
		(
			SELECT
				count(notification_post.*)::int
			FROM
				notification_post
		);
$$;

CREATE FUNCTION
	social.get_posts_from_followees_v1(
		user_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
	)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH followee_post AS (
	    SELECT
	        post.date_created,
	        post.comment_id,
	        post.silent_post_id
	    FROM
	    	core.post
	    	JOIN core.article ON article.id = post.article_id
	    	JOIN social.active_following ON active_following.followee_user_account_id = post.user_account_id
	    WHERE
	        post.date_deleted IS NULL AND
	    	active_following.follower_user_account_id = get_posts_from_followees_v1.user_id AND
	        core.matches_article_length(
				article.word_count,
				get_posts_from_followees_v1.min_length,
				get_posts_from_followees_v1.max_length
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
			(get_posts_from_followees_v1.page_number - 1) * get_posts_from_followees_v1.page_size
		LIMIT
			get_posts_from_followees_v1.page_size
	)
    SELECT
		(
			SELECT
				array_agg(
					(paginated_post.comment_id, paginated_post.silent_post_id)::social.post_reference
					ORDER BY
						paginated_post.date_created DESC
				)
			FROM
				paginated_post
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        followee_post
		)
$$;

CREATE FUNCTION
	social.get_posts_from_inbox_v1(
		user_id bigint,
		page_number integer,
		page_size integer
	)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH inbox_comment AS (
	    SELECT
	    	reply.id,
	        reply.date_created
	    FROM
	    	core.comment
	    	JOIN social.comment AS reply ON reply.parent_comment_id = comment.id
	    WHERE
	    	comment.user_account_id = get_posts_from_inbox_v1.user_id AND
	        reply.user_account_id != get_posts_from_inbox_v1.user_id AND
	        reply.date_deleted IS NULL
	    UNION ALL
	    SELECT
	    	comment.id,
	        comment.date_created
	    FROM
	    	core.user_article
	    	JOIN social.comment ON comment.article_id = user_article.article_id
	    WHERE
	    	user_article.user_account_id = get_posts_from_inbox_v1.user_id AND
	    	user_article.date_completed IS NOT NULL AND
	        comment.user_account_id != get_posts_from_inbox_v1.user_id AND
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
			(get_posts_from_inbox_v1.page_number - 1) * get_posts_from_inbox_v1.page_size
		LIMIT
			get_posts_from_inbox_v1.page_size
	)
    SELECT
		(
			SELECT
				array_agg(
					(paginated_inbox_comment.id, NULL::bigint)::social.post_reference
					ORDER BY
						paginated_inbox_comment.date_created DESC
				)
			FROM
				paginated_inbox_comment
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        inbox_comment
		);
$$;

CREATE FUNCTION
	social.get_posts_from_user(
		subject_user_name text,
		page_size integer,
		page_number integer
	)
RETURNS
	social.post_references_page
LANGUAGE
	sql
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
	        post.date_created,
	        post.comment_id,
	        post.silent_post_id
	    FROM
	    	core.post
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
		(
			SELECT
				array_agg(
					(user_post.comment_id, user_post.silent_post_id)::social.post_reference
					ORDER BY
						user_post.date_created DESC
				)
			FROM
				user_post
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        core.post
		    WHERE
		    	user_account_id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		);
$$;

CREATE FUNCTION
	social.get_reply_posts_v1(
		user_id bigint,
		page_number integer,
		page_size integer
	)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH reply AS (
	    SELECT
	    	reply.id,
	        reply.date_created
	    FROM
	    	core.comment AS parent
	    	JOIN social.comment AS reply ON
	    	    reply.parent_comment_id = parent.id AND
                parent.user_account_id = get_reply_posts_v1.user_id AND
                reply.user_account_id != get_reply_posts_v1.user_id AND
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
			(get_reply_posts_v1.page_number - 1) * get_reply_posts_v1.page_size
		LIMIT
			get_reply_posts_v1.page_size
	)
    SELECT
		(
			SELECT
				array_agg(
					(paginated_reply.id, NULL::bigint)::social.post_reference
					ORDER BY
						paginated_reply.date_created DESC
				)
			FROM
				paginated_reply
		),
		(
		    SELECT
		    	count(reply.*)::int
		    FROM
		        reply
		);
$$;