-- fix user account creation analytics client type
UPDATE
    user_account
SET
    creation_analytics = jsonb_set(creation_analytics, '{client,type}', '"web/app/client"')
WHERE
	creation_analytics->'client'->>'type' SIMILAR TO '[0-9]';

-- strip client version from existing analytics
UPDATE
    comment
SET
	analytics = analytics #- '{client,version}' #- '{context}';

UPDATE
    user_article
SET
	analytics = analytics #- '{client,version}' #- '{context}';

UPDATE
    user_account
SET
	creation_analytics = creation_analytics #- '{client,version}';

-- create new core tables
CREATE TABLE core.following (
	id bigserial PRIMARY KEY,
	follower_user_account_id bigint NOT NULL REFERENCES core.user_account (id),
	followee_user_account_id bigint NOT NULL REFERENCES core.user_account (id),
	date_followed timestamp NOT NULL DEFAULT core.utc_now(),
	date_unfollowed timestamp,
	follow_analytics jsonb NOT NULL,
	unfollow_analytics jsonb,
	CHECK (follower_user_account_id != followee_user_account_id)
);

CREATE UNIQUE INDEX ON
    core.following (follower_user_account_id, followee_user_account_id)
WHERE
	date_unfollowed IS NULL;

CREATE TABLE core.silent_post (
  	id bigserial PRIMARY KEY,
  	article_id bigint NOT NULL REFERENCES core.article (id),
  	user_account_id bigint NOT NULL REFERENCES core.user_account (id),
  	date_created timestamp NOT NULL DEFAULT core.utc_now(),
  	analytics jsonb NOT NULL,
	UNIQUE (article_id, user_account_id)
);

-- add new cached silent_post_count column to article
ALTER TABLE
	core.article
ADD COLUMN
    silent_post_count int NOT NULL DEFAULT 0;

CREATE INDEX ON article (silent_post_count);

-- update user account lookup functions
DROP FUNCTION user_account_api.get_user_account(
	user_account_id bigint
);

CREATE FUNCTION user_account_api.get_user_account_by_id(
	user_account_id bigint
)
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE id = get_user_account_by_id.user_account_id;
$$;

DROP FUNCTION user_account_api.find_user_account(
	email text
);

CREATE FUNCTION user_account_api.get_user_account_by_email(
	email text
)
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE lower(email) = lower(get_user_account_by_email.email);
$$;

CREATE FUNCTION user_account_api.get_user_account_by_name(
	user_name text
)
RETURNS SETOF user_account_api.user_account
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE lower(name) = lower(get_user_account_by_name.user_name);
$$;

CREATE FUNCTION user_account_api.get_user_account_id_by_name(
	user_name text
)
RETURNS bigint
STABLE
LANGUAGE SQL
AS $$
	SELECT
		id
	FROM
		core.user_account
	WHERE
		lower(name) = lower(get_user_account_id_by_name.user_name);
$$;

-- create new schema and functions
CREATE SCHEMA social;

CREATE FUNCTION social.create_following(
	follower_user_id bigint,
	followee_user_name text,
	analytics text
)
RETURNS VOID
LANGUAGE SQL
AS $$
	INSERT INTO core.following
	    (
	    	follower_user_account_id,
	     	followee_user_account_id,
	     	follow_analytics
	    )
	VALUES
    	(
    		create_following.follower_user_id,
    	 	user_account_api.get_user_account_id_by_name(create_following.followee_user_name),
    	 	create_following.analytics::jsonb
		);
$$;

CREATE FUNCTION social.unfollow(
	follower_user_id bigint,
	followee_user_name text,
	analytics text
)
RETURNS VOID
LANGUAGE SQL
AS $$
	UPDATE
		core.following
    SET
    	date_unfollowed = core.utc_now(),
        unfollow_analytics = unfollow.analytics::jsonb
    WHERE
        follower_user_account_id = unfollow.follower_user_id AND
        followee_user_account_id = user_account_api.get_user_account_id_by_name(unfollow.followee_user_name) AND
    	date_unfollowed IS NULL
$$;

CREATE TYPE social.profile AS (
	user_name text,
    is_followed boolean,
    followee_count bigint,
    follower_count bigint
);

CREATE VIEW social.active_following AS (
	SELECT
		id,
		follower_user_account_id,
		followee_user_account_id,
		date_followed
	FROM
		core.following
    WHERE
    	date_unfollowed IS NULL
);

CREATE FUNCTION social.get_profile(
	viewer_user_id bigint,
	subject_user_name text
)
RETURNS SETOF social.profile
LANGUAGE SQL
STABLE
AS $$
    WITH subject_user_account AS (
        SELECT
        	id
        FROM
        	user_account_api.get_user_account_id_by_name(get_profile.subject_user_name) AS user_account (id)
	)
    SELECT
    	subject.name AS user_name,
        bool_or(active_following.follower_user_account_id = get_profile.viewer_user_id) AS is_followed,
		CASE WHEN get_profile.viewer_user_id = (SELECT id FROM subject_user_account)
		    THEN (
		    	SELECT
		    		count(*)
		    	FROM
		    		social.active_following
		        WHERE
		        	follower_user_account_id = get_profile.viewer_user_id
			)
		    ELSE 0
		END AS followee_count,
        count(active_following.id) AS follower_count
    FROM
    	core.user_account AS subject
    	LEFT JOIN social.active_following ON active_following.followee_user_account_id = subject.id
    WHERE
    	subject.id = user_account_api.get_user_account_id_by_name(get_profile.subject_user_name)
    GROUP BY
    	subject.id;
$$;

CREATE TYPE social.following AS (
	user_name text,
    is_followed boolean
);

CREATE FUNCTION social.get_followers(
	viewer_user_id bigint,
	subject_user_name text
)
RETURNS SETOF social.following
LANGUAGE SQL
STABLE
AS $$
	SELECT
		follower.name AS user_name,
	   	viewer_following.id IS NOT NULL AS is_followed
	FROM
		social.active_following AS subject_following
		JOIN core.user_account AS follower ON follower.id = subject_following.follower_user_account_id
		LEFT JOIN social.active_following AS viewer_following ON (
			viewer_following.follower_user_account_id = get_followers.viewer_user_id AND
			viewer_following.followee_user_account_id = follower.id
		)
    WHERE
        subject_following.followee_user_account_id = user_account_api.get_user_account_id_by_name(get_followers.subject_user_name);
$$;

CREATE FUNCTION social.get_followees(
	user_account_id bigint
)
RETURNS SETOF text
LANGUAGE SQL
STABLE
AS $$
    SELECT
    	followee.name
    FROM
    	social.active_following
    	LEFT JOIN user_account AS followee ON followee.id = active_following.followee_user_account_id
    WHERE
    	active_following.follower_user_account_id = get_followees.user_account_id;
$$;

CREATE FUNCTION social.create_silent_post(
	user_account_id bigint,
	article_id bigint,
	analytics text
)
RETURNS SETOF core.silent_post
LANGUAGE plpgsql
AS $$
BEGIN
    -- update the cached article silent_post count
	UPDATE
	    article
	SET
	    silent_post_count = silent_post_count + 1
	WHERE
		id = create_silent_post.article_id;
    -- insert the new silent post
    RETURN QUERY
	INSERT INTO core.silent_post
    	(
    		article_id,
    	 	user_account_id,
    	 	analytics
    	)
    VALUES
    	(
    	 	create_silent_post.article_id,
    	 	create_silent_post.user_account_id,
    	 	create_silent_post.analytics::jsonb
		)
	RETURNING *;
END;
$$;

-- add date_posted to article
CREATE VIEW social.post AS (
    SELECT
		article_id,
        user_account_id,
		date_created,
		id AS comment_id,
		text AS comment_text
	FROM
		core.comment
	WHERE
		parent_comment_id IS NULL
	UNION ALL
	SELECT
		article_id,
	    user_account_id,
		date_created,
		NULL AS comment_id,
		NULL AS comment_text
	FROM
		core.silent_post
);

ALTER TYPE
	article_api.article
ADD ATTRIBUTE
	date_posted timestamp;

ALTER TYPE
	article_api.article_page_result
RENAME ATTRIBUTE
	total_count TO date_posted;

ALTER TYPE
	article_api.article_page_result
ALTER ATTRIBUTE
	date_posted TYPE timestamp,
ADD ATTRIBUTE
	total_count bigint;

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
		user_article_rating.score AS rating_score,
	    earliest_post.date_created AS date_posted
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
				min(date_created) AS date_created
		    FROM
		    	social.post
		    WHERE
		    	article_id = ANY (get_articles.article_ids) AND
		        user_account_id = get_articles.user_account_id
		    GROUP BY
		    	article_id
		) AS earliest_post ON earliest_post.article_id = article.id
	ORDER BY
	    array_position(article_ids, article.id)
$$;

-- create post query functions
CREATE TYPE social.article_post_page_result AS (
	id bigint,
	title text,
	slug text,
	source text,
	date_published timestamp,
	section text,
	description text,
	aotd_timestamp timestamp,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	comment_count bigint,
	read_count bigint,
	date_created timestamp,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp,
	average_rating_score numeric,
	rating_score core.rating_score,
    date_posted timestamp,
    post_date_created timestamp,
    user_name text,
    comment_id bigint,
    comment_text text,
	total_count bigint
);

CREATE FUNCTION social.get_posts_from_user(
	viewer_user_id bigint,
	subject_user_name text,
	page_size int,
	page_number int
)
RETURNS SETOF social.article_post_page_result
STABLE
LANGUAGE SQL
AS $$
    WITH subject_user_account AS (
        SELECT
        	id
        FROM
        	user_account_api.get_user_account_id_by_name(get_posts_from_user.subject_user_name) AS user_account (id)
	),
	selected_post AS (
	    SELECT
	    	*
	    FROM
	    	social.post
	    WHERE
	    	user_account_id = (SELECT id FROM subject_user_account)
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_user.page_number - 1) * get_posts_from_user.page_size
		LIMIT
			get_posts_from_user.page_size
	)
    SELECT
		article.*,
		selected_post.date_created AS post_date_created,
		(
		    SELECT
		    	name
		    FROM
		        user_account
		    WHERE
		    	id = (SELECT id FROM subject_user_account)
		) AS user_name,
		selected_post.comment_id AS comment_id,
		selected_post.comment_text AS comment_text,
		(
		    SELECT
		    	count(*)
		    FROM
		        social.post
		    WHERE
		    	user_account_id = (SELECT id FROM subject_user_account)
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_user.viewer_user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    selected_post
			)
		) AS article
		JOIN selected_post ON selected_post.article_id = article.id
    ORDER BY
    	selected_post.date_created DESC
$$;

CREATE FUNCTION social.get_posts_from_followees(
	user_id bigint,
	page_number integer,
	page_size integer,
	min_length integer,
	max_length integer
)
RETURNS SETOF social.article_post_page_result
STABLE
LANGUAGE SQL
AS $$
	WITH selected_post AS (
	    SELECT
	    	post.*
	    FROM
	    	social.post
	    	JOIN core.article ON article.id = post.article_id
	    	JOIN social.active_following ON active_following.followee_user_account_id = post.user_account_id
	    WHERE
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
	    	selected_post
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_followees.page_number - 1) * get_posts_from_followees.page_size
		LIMIT
			get_posts_from_followees.page_size
	)
    SELECT
		article.*,
		paginated_post.date_created AS post_date_created,
		user_account.name AS user_name,
		paginated_post.comment_id,
		paginated_post.comment_text,
		(
		    SELECT
		    	count(*)
		    FROM
		        selected_post
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
    ORDER BY
    	paginated_post.date_created DESC
$$;

-- refactor community_reads
CREATE OR REPLACE FUNCTION community_reads.get_highest_rated(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
    WITH highest_rated AS (
		SELECT
			community_read.id,
			avg(user_article_rating.score) AS average_rating_score
		FROM
			community_reads.community_read
			JOIN article_api.user_article_rating ON user_article_rating.article_id = community_read.id
		WHERE
			since_date IS NOT NULL AND
			user_article_rating.timestamp >= since_date AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			average_rating_score
		FROM community_reads.community_read
		WHERE
			since_date IS NULL AND
			average_rating_score IS NOT NULL AND
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
		    FROM highest_rated
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM highest_rated
			ORDER BY average_rating_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;

CREATE OR REPLACE FUNCTION community_reads.get_hot(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
    WITH hot_read AS (
        SELECT
            id,
            hot_score
        FROM community_reads.community_read
        WHERE (
        	aotd_timestamp IS DISTINCT FROM (SELECT max(aotd_timestamp) FROM core.article) AND
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
		    SELECT count(*)
		    FROM hot_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM hot_read
			ORDER BY hot_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;

CREATE OR REPLACE FUNCTION community_reads.get_most_commented(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
    WITH most_commented AS (
		SELECT
			community_read.id,
			count(*) AS comment_count
		FROM
			community_reads.community_read
			JOIN comment ON comment.article_id = community_read.id
		WHERE
			since_date IS NOT NULL AND
			comment.date_created >= since_date AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			comment_count
		FROM community_reads.community_read
		WHERE
			since_date IS NULL AND
			comment_count > 0 AND
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
		    FROM most_commented
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM most_commented
			ORDER BY comment_count DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;

CREATE OR REPLACE FUNCTION community_reads.get_most_read(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
    WITH most_read AS (
		SELECT
			community_read.id,
			count(*) AS read_count
		FROM
			community_reads.community_read
			JOIN user_article ON user_article.article_id = community_read.id
		WHERE
			since_date IS NOT NULL AND
			user_article.date_completed >= since_date AND
		    core.matches_article_length(
				community_read.word_count,
				min_length,
				max_length
			)
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			read_count
		FROM community_reads.community_read
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

CREATE OR REPLACE FUNCTION community_reads.get_top(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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
    	articles.*,
		(
		    SELECT count(*)
		    FROM top_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM top_read
			ORDER BY top_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;

DROP VIEW community_reads.listed_community_read;

-- update community read to use silent_posts
CREATE OR REPLACE VIEW community_reads.community_read AS (
	SELECT
		article.id,
    	article.aotd_timestamp,
    	article.word_count,
    	article.hot_score,
    	article.top_score,
    	article.comment_count,
    	article.read_count,
    	article.average_rating_score
	FROM
		core.article
	WHERE
		article.comment_count > 0 OR
	    article.read_count > 1 OR
	    article.average_rating_score IS NOT NULL OR
	    article.silent_post_count > 0
);

-- update scouting to use posts instead of ratings
CREATE OR REPLACE VIEW stats.scouting AS (
	SELECT
		article.id AS article_id,
		article.aotd_timestamp,
		post.user_account_id
	FROM
		core.article
		JOIN social.post ON post.article_id = article.id
		LEFT JOIN social.post earlier_post ON (
			earlier_post.article_id = post.article_id AND
			earlier_post.date_created < post.date_created
		)
	WHERE
		article.aotd_timestamp IS NOT NULL AND
	    earlier_post.date_created IS NULL
);