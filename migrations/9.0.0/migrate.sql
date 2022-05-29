-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- add cached rating_score_count column to article
ALTER TABLE
    core.article
ADD COLUMN
	rating_count int NOT NULL DEFAULT 0;

-- set initial values
WITH ratings AS (
    SELECT
        article_id,
    	count(*) AS count
    FROM
    	article_api.user_article_rating
    GROUP BY
    	article_id
)
UPDATE
    core.article
SET
	rating_count = ratings.count
FROM
	ratings
WHERE
	ratings.article_id = article.id;

-- add cached first_poster_id column to article
ALTER TABLE
	core.article
ADD COLUMN
	first_poster_id bigint;

-- set initial values
UPDATE
	core.article
SET
	first_poster_id = post.user_account_id
FROM
	social.post
WHERE
    post.article_id = article.id;

-- add flair to article
CREATE TYPE core.article_flair AS ENUM (
    'paywall'
);

ALTER TABLE
	core.article
ADD COLUMN
	flair core.article_flair;

-- update article_api.article to include new columns
ALTER TYPE
	article_api.article
ALTER ATTRIBUTE
	date_posted SET DATA TYPE timestamp[];

ALTER TYPE
	article_api.article
RENAME ATTRIBUTE
	date_posted TO dates_posted;

ALTER TYPE
	article_api.article
ADD ATTRIBUTE
	hot_score int,
ADD ATTRIBUTE
	hot_velocity numeric,
ADD ATTRIBUTE
	rating_count int,
ADD ATTRIBUTE
	first_poster text,
ADD ATTRIBUTE
	flair core.article_flair;

-- update article_api.article_page_result to include new columns
ALTER TYPE
	article_api.article_page_result
ALTER ATTRIBUTE
	date_posted SET DATA TYPE timestamp[];

ALTER TYPE
	article_api.article_page_result
RENAME ATTRIBUTE
	date_posted TO dates_posted;

ALTER TYPE
    article_api.article_page_result
DROP ATTRIBUTE
    total_count;

ALTER TYPE
	article_api.article_page_result
ADD ATTRIBUTE
	hot_score int,
ADD ATTRIBUTE
	hot_velocity numeric,
ADD ATTRIBUTE
	rating_count int,
ADD ATTRIBUTE
	first_poster text,
ADD ATTRIBUTE
	flair core.article_flair,
ADD ATTRIBUTE
	total_count bigint;

-- update social.article_post_page_result to include new columns
ALTER TYPE
	social.article_post_page_result
ALTER ATTRIBUTE
	date_posted SET DATA TYPE timestamp[];

ALTER TYPE
	social.article_post_page_result
RENAME ATTRIBUTE
	date_posted TO dates_posted;

ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    post_date_created,
DROP ATTRIBUTE
    user_name,
DROP ATTRIBUTE
    comment_id,
DROP ATTRIBUTE
    comment_text,
DROP ATTRIBUTE
    silent_post_id,
DROP ATTRIBUTE
    has_alert,
DROP ATTRIBUTE
    total_count;

ALTER TYPE
	social.article_post_page_result
ADD ATTRIBUTE
	hot_score int,
ADD ATTRIBUTE
	hot_velocity numeric,
ADD ATTRIBUTE
	rating_count int,
ADD ATTRIBUTE
	first_poster text,
ADD ATTRIBUTE
	flair core.article_flair,
ADD ATTRIBUTE
	post_date_created timestamp,
ADD ATTRIBUTE
	user_name text,
ADD ATTRIBUTE
	comment_id bigint,
ADD ATTRIBUTE
	comment_text text,
ADD ATTRIBUTE
	silent_post_id bigint,
ADD ATTRIBUTE
	has_alert bool,
ADD ATTRIBUTE
	total_count bigint;

-- update article_api.get_articles to return new columns
CREATE OR REPLACE FUNCTION article_api.get_articles(
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

-- cache rating count
DROP FUNCTION article_api.rate_article(
	article_id bigint,
	user_account_id bigint,
	score core.rating_score
);
CREATE FUNCTION article_api.rate_article(
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
    average_score numeric;
    rating_count int;
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
    -- select the updated rating stats
    SELECT
		avg(current_rating.score),
        count(*)
    INTO
    	locals.average_score,
        locals.rating_count
	FROM
		article_api.user_article_rating AS current_rating
	WHERE
		current_rating.article_id = rate_article.article_id;
    -- cache the updated rating stats in article
    UPDATE
		core.article
	SET
		average_rating_score = locals.average_score,
		rating_count = locals.rating_count
	WHERE
		article.id = rate_article.article_id;
    -- return the new rating
    RETURN NEXT locals.new_rating;
END;
$$;

-- cache first poster
CREATE OR REPLACE FUNCTION social.create_silent_post(
	user_account_id bigint,
	article_id bigint,
	analytics text
)
RETURNS SETOF core.silent_post
LANGUAGE sql
AS $$
    WITH cache_post AS (
        UPDATE
			core.article
		SET
			silent_post_count = silent_post_count + 1,
		    first_poster_id = (
		        CASE WHEN
		            first_poster_id IS NULL
		        THEN
		            create_silent_post.user_account_id
		        ELSE
		            first_poster_id
		        END
			)
		WHERE
			id = create_silent_post.article_id
	)
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
	    *
$$;
CREATE OR REPLACE FUNCTION article_api.create_comment(
	text text,
	article_id bigint,
	parent_comment_id bigint,
	user_account_id bigint,
	analytics text
)
RETURNS SETOF article_api.user_comment
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    comment_id bigint;
BEGIN
    -- create the new comment
    INSERT INTO
		comment (
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
		article_api.user_comment
	WHERE
	    id = locals.comment_id;
END;
$$;

-- remove 5 min restriction for AOTDs
CREATE OR REPLACE FUNCTION community_reads.set_aotd()
RETURNS SETOF article_api.article
LANGUAGE sql
AS $$
    WITH aotd AS (
    	UPDATE
			core.article
		SET
			aotd_timestamp = core.utc_now()
		WHERE
			id = (
    			SELECT
					id
				FROM
					community_reads.community_read
				WHERE
					aotd_timestamp IS NULL
				ORDER BY
					hot_score DESC
				LIMIT
					1
			)
    	RETURNING
    		id
    )
    SELECT
    	*
    FROM
    	article_api.get_article(
    		article_id => (
    			SELECT
    				id
    			FROM
    				aotd
    		),
    		user_account_id => NULL
		);
$$;

-- remove existing AOTDs from hot sort
CREATE OR REPLACE FUNCTION community_reads.get_hot(
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
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        hot_read
		) AS total_count
    FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
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
			)
		) AS articles;
$$;

-- create new query for previous aotds
CREATE FUNCTION community_reads.get_aotd_history(
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
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        previous_aotd
		)
    FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
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
			)
		) AS articles;
$$;

-- rename is_replyable to has_recipient_read_article in post_alert_dispatch
ALTER TYPE
	notifications.post_alert_dispatch
RENAME ATTRIBUTE
    is_replyable TO has_recipient_read_article;
CREATE OR REPLACE FUNCTION notifications.create_post_notifications(
	article_id bigint,
	poster_id bigint,
	comment_id bigint,
	silent_post_id bigint
)
RETURNS SETOF notifications.post_alert_dispatch
LANGUAGE sql
    AS $$
    WITH recipient AS (
        SELECT
			following.follower_user_account_id AS user_account_id,
		    preference.post_via_email,
		    preference.post_via_extension,
		    preference.post_via_push
		FROM
			social.active_following AS following
			JOIN notifications.current_preference AS preference
			    ON (
					following.follower_user_account_id = preference.user_account_id AND
					following.followee_user_account_id = create_post_notifications.poster_id
				)
	),
    post_event AS (
        INSERT INTO
			core.notification_event (type)
		SELECT
            'post'
        WHERE
            EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
    post_data AS (
        INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
        	id,
		    create_post_notifications.comment_id,
		    create_post_notifications.silent_post_id
        FROM
        	post_event
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
		(
			SELECT
				(SELECT id FROM post_event),
				recipient.user_account_id,
				recipient.post_via_email,
				recipient.post_via_extension,
				recipient.post_via_push
			FROM
				recipient
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_extension,
		    via_push
	),
    alert_cache AS (
        UPDATE
			core.user_account
		SET
			post_alert_count = post_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
	    user_article.date_completed IS NOT NULL,
		user_account.id,
		user_account.name::text,
		user_account.email::text,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		user_account.aotd_alert,
		user_account.reply_alert_count,
		user_account.loopback_alert_count,
		user_account.post_alert_count,
		user_account.follower_alert_count
	FROM
		receipt
		JOIN core.user_account
			ON user_account.id = receipt.user_account_id
		LEFT JOIN core.user_article
		    ON (
		        user_article.user_account_id = user_account.id AND
		        user_article.article_id = create_post_notifications.article_id
		    )
		LEFT JOIN notifications.registered_push_device AS device
			ON device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		user_account.id,
	    user_article.date_completed;
$$;