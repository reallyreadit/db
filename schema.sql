--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.11
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: analytics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA analytics;


--
-- Name: article_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA article_api;


--
-- Name: bulk_mailing_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bulk_mailing_api;


--
-- Name: community_reads; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA community_reads;


--
-- Name: core; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA core;


--
-- Name: social; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA social;


--
-- Name: stats; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stats;


--
-- Name: user_account_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA user_account_api;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: rating_score; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.rating_score AS integer
	CONSTRAINT rating_score_check CHECK (((VALUE >= 1) AND (VALUE <= 10)));


--
-- Name: article; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.article AS (
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
	date_posted timestamp without time zone
);


--
-- Name: article_page_result; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.article_page_result AS (
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
	date_posted timestamp without time zone,
	total_count bigint
);


--
-- Name: user_comment_page_result; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.user_comment_page_result AS (
	id bigint,
	date_created timestamp without time zone,
	text text,
	article_id bigint,
	article_title text,
	article_slug text,
	user_account_id bigint,
	user_account text,
	parent_comment_id bigint,
	date_read timestamp without time zone,
	total_count bigint
);


--
-- Name: challenge_response_action; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.challenge_response_action AS ENUM (
    'enroll',
    'decline',
    'disenroll'
);


--
-- Name: source_rule_action; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.source_rule_action AS ENUM (
    'default',
    'read',
    'ignore'
);


--
-- Name: is_time_zone_name(text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.is_time_zone_name(name text) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
	PERFORM now() AT TIME ZONE is_time_zone_name.name;
	RETURN TRUE;
EXCEPTION
	WHEN invalid_parameter_value THEN
		RETURN FALSE;
END;
$$;


--
-- Name: time_zone_name; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.time_zone_name AS text
	CONSTRAINT time_zone_name_check CHECK (core.is_time_zone_name(VALUE));


--
-- Name: user_account_role; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.user_account_role AS ENUM (
    'regular',
    'admin'
);


--
-- Name: article_post_page_result; Type: TYPE; Schema: social; Owner: -
--

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
	date_posted timestamp without time zone,
	post_date_created timestamp without time zone,
	user_name text,
	comment_id bigint,
	comment_text text,
	total_count bigint
);


--
-- Name: following; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.following AS (
	user_name text,
	is_followed boolean
);


--
-- Name: profile; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.profile AS (
	user_name text,
	is_followed boolean,
	followee_count bigint,
	follower_count bigint
);


--
-- Name: leaderboard_ranking; Type: TYPE; Schema: stats; Owner: -
--

CREATE TYPE stats.leaderboard_ranking AS (
	user_name text,
	score integer,
	rank integer
);


--
-- Name: ranking; Type: TYPE; Schema: stats; Owner: -
--

CREATE TYPE stats.ranking AS (
	score integer,
	rank integer
);


--
-- Name: streak; Type: TYPE; Schema: stats; Owner: -
--

CREATE TYPE stats.streak AS (
	day_count integer,
	includes_today boolean
);


--
-- Name: streak_ranking; Type: TYPE; Schema: stats; Owner: -
--

CREATE TYPE stats.streak_ranking AS (
	day_count integer,
	includes_today boolean,
	rank integer
);


--
-- Name: get_key_metrics(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_key_metrics(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(day timestamp without time zone, user_account_app_count bigint, user_account_browser_count bigint, user_account_unknown_count bigint, read_app_count bigint, read_browser_count bigint, read_unknown_count bigint, comment_app_count bigint, comment_browser_count bigint, comment_unknown_count bigint, extension_installation_count bigint, extension_removal_count bigint)
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
		    date AS day,
			tsrange(date, date + '1 day'::interval) AS range
		FROM generate_series(
		    get_key_metrics.start_date,
		    get_key_metrics.end_date,
		    '1 day'::interval
		) AS series (date)
	)
	SELECT
		report_period.day,
		coalesce(user_account_totals.app_count, 0) AS user_account_app_count,
		coalesce(user_account_totals.browser_count, 0) AS user_account_browser_count,
		coalesce(user_account_totals.unknown_count, 0) AS user_account_unknown_count,
		coalesce(read_totals.app_count, 0) AS read_app_count,
		coalesce(read_totals.browser_count, 0) AS read_browser_count,
		coalesce(read_totals.unknown_count, 0) AS read_unknown_count,
		coalesce(comment_totals.app_count, 0) AS comment_app_count,
		coalesce(comment_totals.browser_count, 0) AS comment_browser_count,
		coalesce(comment_totals.unknown_count, 0) AS comment_unknown_count,
	    coalesce(extension_installation_total.count, 0) AS extension_installation_count,
	    coalesce(extension_removal_total.count, 0) AS extension_removal_count
	FROM
		report_period
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE creation_analytics IS NULL) AS unknown_count
			FROM
				user_account
				JOIN report_period ON user_account.date_created <@ report_period.range
			GROUP BY report_period.day
		) AS user_account_totals ON user_account_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_article
				JOIN report_period ON user_article.date_completed <@ report_period.range
			GROUP BY report_period.day
		) AS read_totals ON read_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
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
				JOIN report_period ON comment.date_created <@ report_period.range
			GROUP BY report_period.day
		) AS comment_totals ON comment_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
			    count(*) AS count
			FROM
				extension_installation
		    	JOIN report_period ON extension_installation.timestamp <@ report_period.range
		    GROUP BY
		    	report_period.day
		) AS extension_installation_total ON extension_installation_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
			    count(*) AS count
			FROM
				extension_removal
		    	JOIN report_period ON extension_removal.timestamp <@ report_period.range
		    GROUP BY
		    	report_period.day
		) AS extension_removal_total ON extension_removal_total.day = report_period.day
	ORDER BY report_period.day DESC;
$$;


--
-- Name: get_user_account_creations(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_user_account_creations(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(id bigint, name text, date_created timestamp without time zone, time_zone_name text, client_mode text, marketing_screen_variant integer, referrer_url text, initial_path text)
    LANGUAGE sql STABLE
    AS $$
	SELECT
		user_account.id,
	    user_account.name,
	    user_account.date_created,
	    time_zone.name,
	    user_account.creation_analytics->'client'->>'mode',
	    (user_account.creation_analytics->>'marketing_screen_variant')::int,
	    user_account.creation_analytics->>'referrer_url',
	    user_account.creation_analytics->>'initial_path'
	FROM
		user_account
    	LEFT JOIN time_zone
    		ON time_zone.id = user_account.time_zone_id
    WHERE
    	user_account.date_created <@ tsrange(start_date, end_date)
    ORDER BY
    	user_account.date_created DESC
$$;


--
-- Name: log_client_error_report(text, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_client_error_report(content text, analytics text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO
    	core.client_error_report (
    		content,
    	    analytics
    	)
    VALUES (
        log_client_error_report.content,
        log_client_error_report.analytics::jsonb
	);
$$;


--
-- Name: log_extension_installation(uuid, bigint, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_extension_installation(installation_id uuid, user_account_id bigint, platform text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO
        extension_installation (installation_id, user_account_id, platform)
    VALUES
    	(
    	 	log_extension_installation.installation_id,
    	 	log_extension_installation.user_account_id,
    	 	log_extension_installation.platform
		);
$$;


--
-- Name: log_extension_removal(uuid, bigint); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_extension_removal(installation_id uuid, user_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO
        extension_removal (installation_id, user_account_id)
    VALUES
    	(
    	 	log_extension_removal.installation_id,
    	 	log_extension_removal.user_account_id
		);
$$;


--
-- Name: log_extension_removal_feedback(uuid, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_extension_removal_feedback(installation_id uuid, reason text) RETURNS void
    LANGUAGE sql
    AS $$
    UPDATE
        extension_removal
    SET
    	reason = log_extension_removal_feedback.reason
    WHERE (
    	installation_id = log_extension_removal_feedback.installation_id AND
        reason IS NULL
	);
$$;


--
-- Name: create_article(text, text, bigint, timestamp without time zone, timestamp without time zone, text, text, text[], text[], text[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_article(title text, slug text, source_id bigint, date_published timestamp without time zone, date_modified timestamp without time zone, section text, description text, author_names text[], author_urls text[], tags text[]) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	article_id	 		bigint;
	current_author_url	text;
	current_author_id	bigint;
	current_tag			text;
	current_tag_id		bigint;
BEGIN
	INSERT INTO article (title, slug, source_id, date_published, date_modified, section, description)
		VALUES (title, slug, source_id, date_published, date_modified, section, description)
		RETURNING id INTO article_id;
	FOR i IN 1..coalesce(array_length(author_names, 1), 0) LOOP
		current_author_url := author_urls[i];
		SELECT id INTO current_author_id FROM author WHERE url = current_author_url;
		IF current_author_id IS NULL THEN
			INSERT INTO author (name, url) VALUES (author_names[i], current_author_url)
				RETURNING id INTO current_author_id;
		END IF;
		INSERT INTO article_author (article_id, author_id) VALUES (article_id, current_author_id);
	END LOOP;
	FOREACH current_tag IN ARRAY tags
	LOOP
		SELECT id INTO current_tag_id FROM tag WHERE name = current_tag;
		IF current_tag_id IS NULL THEN
			INSERT INTO tag (name) VALUES (current_tag) RETURNING id INTO current_tag_id;
		END IF;
		INSERT INTO article_tag (article_id, tag_id) VALUES (article_id, current_tag_id);
	END LOOP;
	RETURN article_id;
END;
$$;


--
-- Name: utc_now(); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.utc_now() RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
	SELECT local_now('UTC');
$$;


SET default_with_oids = false;

--
-- Name: article; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article (
    id bigint NOT NULL,
    title character varying(512) NOT NULL,
    slug character varying(256) NOT NULL,
    source_id bigint NOT NULL,
    date_published timestamp without time zone,
    date_modified timestamp without time zone,
    section character varying(256),
    description text,
    aotd_timestamp timestamp without time zone,
    hot_score integer DEFAULT 0 NOT NULL,
    top_score integer DEFAULT 0 NOT NULL,
    comment_count integer DEFAULT 0 NOT NULL,
    read_count integer DEFAULT 0 NOT NULL,
    average_rating_score numeric,
    word_count integer DEFAULT 0 NOT NULL,
    silent_post_count integer DEFAULT 0 NOT NULL
);


--
-- Name: comment; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.comment (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    text text NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    parent_comment_id bigint,
    date_read timestamp without time zone,
    analytics jsonb
);


--
-- Name: user_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_account (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    email character varying(256) NOT NULL,
    password_hash bytea NOT NULL,
    password_salt bytea NOT NULL,
    receive_reply_email_notifications boolean DEFAULT true NOT NULL,
    receive_reply_desktop_notifications boolean DEFAULT true NOT NULL,
    last_new_reply_ack timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    last_new_reply_desktop_notification timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    role core.user_account_role DEFAULT 'regular'::core.user_account_role NOT NULL,
    receive_website_updates boolean DEFAULT true,
    receive_suggested_readings boolean DEFAULT true,
    time_zone_id bigint,
    creation_analytics jsonb,
    CONSTRAINT user_account_email_valid CHECK (((email)::text ~~ '%@%'::text)),
    CONSTRAINT user_account_name_valid CHECK (((name)::text ~ similar_escape('[A-Za-z0-9\-_]+'::text, NULL::text)))
);


--
-- Name: user_comment; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.user_comment AS
 SELECT comment.id,
    comment.date_created,
    comment.text,
    comment.article_id,
    article.title AS article_title,
    article.slug AS article_slug,
    comment.user_account_id,
    user_account.name AS user_account,
    comment.parent_comment_id,
    comment.date_read
   FROM ((core.comment
     JOIN core.article ON ((comment.article_id = article.id)))
     JOIN core.user_account ON ((comment.user_account_id = user_account.id)));


--
-- Name: create_comment(text, bigint, bigint, bigint, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_comment(text text, article_id bigint, parent_comment_id bigint, user_account_id bigint, analytics text) RETURNS SETOF article_api.user_comment
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


--
-- Name: page; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.page (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    number integer NOT NULL,
    word_count integer NOT NULL,
    readable_word_count integer NOT NULL,
    url character varying(256) NOT NULL
);


--
-- Name: create_page(bigint, integer, integer, integer, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_page(article_id bigint, number integer, word_count integer, readable_word_count integer, url text) RETURNS SETOF core.page
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- set the cached word_count on article
    UPDATE article
    SET word_count = create_page.word_count
    WHERE id = create_page.article_id;
    -- create the new page and return it
	RETURN QUERY
   INSERT INTO page (article_id, number, word_count, readable_word_count, url)
	VALUES (article_id, number, word_count, readable_word_count, url)
	RETURNING *;
END;
$$;


--
-- Name: source; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.source (
    id bigint NOT NULL,
    name character varying(256),
    url character varying(256) NOT NULL,
    hostname character varying(256) NOT NULL,
    slug character varying(256) NOT NULL,
    parser text
);


--
-- Name: create_source(text, text, text, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_source(name text, url text, hostname text, slug text) RETURNS core.source
    LANGUAGE sql
    AS $$
	INSERT INTO source (name, url, hostname, slug) VALUES (name, url, hostname, slug) RETURNING *;
$$;


--
-- Name: user_article; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_article (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    last_modified timestamp without time zone,
    read_state integer[] NOT NULL,
    words_read integer DEFAULT 0 NOT NULL,
    date_completed timestamp without time zone,
    readable_word_count integer NOT NULL,
    analytics jsonb
);


--
-- Name: create_user_article(bigint, bigint, integer, text); Type: FUNCTION; Schema: article_api; Owner: -
--

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


--
-- Name: find_article(text, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.find_article(slug text, user_account_id bigint) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		(
		   SELECT id
		   FROM article
		   WHERE slug = find_article.slug
		)
	);
$$;


--
-- Name: find_page(text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.find_page(url text) RETURNS SETOF core.page
    LANGUAGE sql
    AS $$
	SELECT * FROM page WHERE url = find_page.url;
$$;


--
-- Name: find_source(text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.find_source(source_hostname text) RETURNS SETOF core.source
    LANGUAGE sql
    AS $$
	SELECT * FROM source WHERE hostname = source_hostname;
$$;


--
-- Name: get_article(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_article(article_id bigint, user_account_id bigint) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		article_id
	);
$$;


--
-- Name: get_article_history(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_article_history(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: get_articles(bigint, bigint[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_articles(user_account_id bigint, VARIADIC article_ids bigint[]) RETURNS SETOF article_api.article
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


--
-- Name: get_comment(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_comment(comment_id bigint) RETURNS SETOF article_api.user_comment
    LANGUAGE sql
    AS $$
	SELECT * FROM article_api.user_comment WHERE id = comment_id;
$$;


--
-- Name: get_page(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_page(page_id bigint) RETURNS SETOF core.page
    LANGUAGE sql
    AS $$
	SELECT * FROM page WHERE id = page_id;
$$;


--
-- Name: get_percent_complete(numeric, numeric); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_percent_complete(readable_word_count numeric, words_read numeric) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT greatest(
	   least(
	      (coalesce(words_read, 0)::double precision / greatest(coalesce(readable_word_count, 0), 1)) * 100,
	      100
	   ),
	   0
	);
$$;


--
-- Name: source_rule; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.source_rule (
    id bigint NOT NULL,
    hostname character varying(256) NOT NULL,
    path character varying(256) NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    action core.source_rule_action NOT NULL
);


--
-- Name: get_source_rules(); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_source_rules() RETURNS SETOF core.source_rule
    LANGUAGE sql
    AS $$
	SELECT * FROM source_rule;
$$;


--
-- Name: get_starred_articles(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_starred_articles(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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
		articles.*,
		(SELECT count(*) FROM starred_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM starred_article
			ORDER BY date_starred DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;


--
-- Name: get_user_article(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_user_article(user_article_id bigint) RETURNS SETOF core.user_article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_article
	WHERE id = get_user_article.user_article_id;
$$;


--
-- Name: get_user_article(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

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


--
-- Name: list_comments(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.list_comments(article_id bigint) RETURNS SETOF article_api.user_comment
    LANGUAGE sql
    AS $$
	SELECT * FROM article_api.user_comment WHERE article_id = list_comments.article_id;
$$;


--
-- Name: list_replies(bigint, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.list_replies(user_account_id bigint, page_number integer, page_size integer) RETURNS SETOF article_api.user_comment_page_result
    LANGUAGE sql
    AS $$
	SELECT
		reply.id,
		reply.date_created,
		reply.text,
		reply.article_id,
		reply.article_title,
		reply.article_slug,
		reply.user_account_id,
		reply.user_account,
		reply.parent_comment_id,
		reply.date_read,
		count(*) OVER() AS total_count
	FROM
		article_api.user_comment AS reply
		JOIN comment AS parent ON reply.parent_comment_id = parent.id
	WHERE parent.user_account_id = list_replies.user_account_id
	ORDER BY reply.date_created DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$$;


--
-- Name: rating; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.rating (
    id bigint NOT NULL,
    "timestamp" timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    score core.rating_score NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL
);


--
-- Name: rate_article(bigint, bigint, core.rating_score); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.rate_article(article_id bigint, user_account_id bigint, score core.rating_score) RETURNS core.rating
    LANGUAGE plpgsql STRICT
    AS $$
<<locals>>
DECLARE
   current_rating rating;
BEGIN
	-- insert the new rating
	INSERT INTO rating
		(score, article_id, user_account_id)
	VALUES
		(score, article_id, user_account_id)
	RETURNING *
	INTO locals.current_rating;
	-- update the cached article average rating score
	UPDATE article
	SET average_rating_score = (
	   	SELECT avg(user_article_rating.score)
	   	FROM article_api.user_article_rating
	   	WHERE user_article_rating.article_id = rate_article.article_id
	)
	WHERE id = rate_article.article_id;
	-- return
	RETURN locals.current_rating;
END;
$$;


--
-- Name: read_comment(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.read_comment(comment_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE comment SET date_read = utc_now() WHERE id = comment_id AND date_read IS NULL;
$$;


--
-- Name: score_articles(); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.score_articles() RETURNS void
    LANGUAGE sql
    AS $$
	WITH score AS (
		SELECT
			article.id AS article_id,
			(
				(
					coalesce(scored_first_comment.score, 0) +
					(coalesce(reads.score, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) / (
				CASE
				    -- divide articles from billloundy.com by 10
				    WHEN article.source_id = 7038
				    THEN 10
				    ELSE 1
				END
			) AS hot,
			(
				(
					coalesce(scored_first_comment.count, 0) +
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
						comment.article_id,
						utc_now() - comment.date_created AS age
					FROM
						comment
				    	LEFT JOIN comment AS earlier_comment ON (
				    		earlier_comment.article_id = comment.article_id AND
				    		earlier_comment.user_account_id = comment.user_account_id AND
				    		earlier_comment.date_created < comment.date_created
						)
				    WHERE
				    	earlier_comment.id IS NULL
				) AS first_comment
				GROUP BY article_id
			) AS scored_first_comment ON scored_first_comment.article_id = article.id
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


--
-- Name: star_article(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.star_article(user_account_id bigint, article_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
	INSERT INTO star (user_account_id, article_id)
	VALUES (user_account_id, article_id)
	ON CONFLICT (user_account_id, article_id)
	   DO UPDATE SET date_starred = utc_now();
$$;


--
-- Name: unstar_article(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.unstar_article(user_account_id bigint, article_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
	DELETE FROM star WHERE
		user_account_id = unstar_article.user_account_id AND
		article_id = unstar_article.article_id;
$$;


--
-- Name: update_page(bigint, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.update_page(page_id bigint, word_count integer, readable_word_count integer) RETURNS core.page
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_page page;
BEGIN
    -- update the page and store it in the local variable
	UPDATE page
	SET
	    word_count = update_page.word_count,
	    readable_word_count = update_page.readable_word_count
	WHERE page.id = update_page.page_id
	RETURNING * INTO updated_page;
    -- update the cached word_count on article
    UPDATE article
    SET word_count = update_page.word_count
    WHERE id = updated_page.article_id;
    -- return the updated page
    RETURN updated_page;
END;
$$;


--
-- Name: update_read_progress(bigint, integer[], text); Type: FUNCTION; Schema: article_api; Owner: -
--

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


--
-- Name: update_user_article(bigint, integer, integer[]); Type: FUNCTION; Schema: article_api; Owner: -
--

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


--
-- Name: create_bulk_mailing(text, text, text, bigint, bigint[], boolean[]); Type: FUNCTION; Schema: bulk_mailing_api; Owner: -
--

CREATE FUNCTION bulk_mailing_api.create_bulk_mailing(subject text, body text, list text, user_account_id bigint, recipient_ids bigint[], recipient_results boolean[]) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	bulk_mailing_id bigint;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOR i IN 1..coalesce(array_length(recipient_ids, 1), 0) LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id, is_successful)
			VALUES (bulk_mailing_id, recipient_ids[i], recipient_results[i]);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$$;


--
-- Name: create_email_notification(text, text, text, text); Type: FUNCTION; Schema: bulk_mailing_api; Owner: -
--

CREATE FUNCTION bulk_mailing_api.create_email_notification(notification_type text, mail text, bounce text, complaint text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO email_notification
        (notification_type, mail, bounce, complaint)
    VALUES
		(notification_type, mail::json, bounce::json, complaint::json);
$$;


--
-- Name: get_blocked_email_addresses(); Type: FUNCTION; Schema: bulk_mailing_api; Owner: -
--

CREATE FUNCTION bulk_mailing_api.get_blocked_email_addresses() RETURNS SETOF text
    LANGUAGE sql STABLE
    AS $$
	SELECT DISTINCT lower(recipient->>'email_address')
	FROM (
		SELECT jsonb_array_elements(bounce->'bounced_recipients')
		FROM email_notification
		UNION ALL
		SELECT jsonb_array_elements(complaint->'complained_recipients')
		FROM email_notification
	) AS row (recipient);
$$;


--
-- Name: list_bulk_mailings(); Type: FUNCTION; Schema: bulk_mailing_api; Owner: -
--

CREATE FUNCTION bulk_mailing_api.list_bulk_mailings() RETURNS TABLE(id bigint, date_sent timestamp without time zone, subject text, body text, list text, user_account text, recipient_count bigint, error_count bigint)
    LANGUAGE sql
    AS $$
	SELECT
		bulk_mailing.id,
		bulk_mailing.date_sent,
		bulk_mailing.subject,
		bulk_mailing.body,
		bulk_mailing.list,
		user_account.name AS user_account,
		count(*) AS recipient_count,
		count(*) FILTER (WHERE NOT bulk_mailing_recipient.is_successful) AS error_count
		FROM bulk_mailing
		JOIN user_account ON bulk_mailing.user_account_id = user_account.id
		JOIN bulk_mailing_recipient ON bulk_mailing.id = bulk_mailing_recipient.bulk_mailing_id
		GROUP BY bulk_mailing.id, user_account.id;
$$;


--
-- Name: email_confirmation; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.email_confirmation (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    user_account_id bigint NOT NULL,
    email_address text NOT NULL,
    date_confirmed timestamp without time zone
);


--
-- Name: time_zone; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.time_zone (
    id bigint NOT NULL,
    name core.time_zone_name NOT NULL,
    display_name character varying(256) NOT NULL,
    territory character varying(3) NOT NULL,
    base_utc_offset interval hour to second NOT NULL
);


--
-- Name: user_account; Type: VIEW; Schema: user_account_api; Owner: -
--

CREATE VIEW user_account_api.user_account AS
 SELECT user_account.id,
    user_account.name,
    user_account.email,
    user_account.password_hash,
    user_account.password_salt,
    user_account.receive_reply_email_notifications,
    user_account.receive_reply_desktop_notifications,
    user_account.last_new_reply_ack,
    user_account.last_new_reply_desktop_notification,
    user_account.date_created,
    user_account.role,
    user_account.receive_website_updates,
    user_account.receive_suggested_readings,
    (latest_email_confirmation.date_confirmed IS NOT NULL) AS is_email_confirmed,
    user_account.time_zone_id,
    time_zone.name AS time_zone_name,
    time_zone.display_name AS time_zone_display_name
   FROM ((core.user_account
     LEFT JOIN ( SELECT ec_left.user_account_id,
            ec_left.date_confirmed
           FROM (core.email_confirmation ec_left
             LEFT JOIN core.email_confirmation ec_right ON (((ec_right.user_account_id = ec_left.user_account_id) AND (ec_right.date_created > ec_left.date_created))))
          WHERE (ec_right.id IS NULL)) latest_email_confirmation ON ((latest_email_confirmation.user_account_id = user_account.id)))
     LEFT JOIN core.time_zone ON ((time_zone.id = user_account.time_zone_id)));


--
-- Name: list_confirmation_reminder_recipients(); Type: FUNCTION; Schema: bulk_mailing_api; Owner: -
--

CREATE FUNCTION bulk_mailing_api.list_confirmation_reminder_recipients() RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
	DISTINCT ON (user_account.id)
		user_account.*
	FROM
		bulk_mailing
		JOIN bulk_mailing_recipient recipient ON recipient.bulk_mailing_id = bulk_mailing.id
		JOIN user_account_api.user_account ON user_account.id = recipient.user_account_id
	WHERE
		bulk_mailing.list = 'ConfirmationReminder';
$$;


--
-- Name: get_aotd(bigint); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_aotd(user_account_id bigint) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT 1
		)
	);
$$;


--
-- Name: get_highest_rated(bigint, integer, integer, timestamp without time zone, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_highest_rated(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: get_hot(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_hot(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: get_most_commented(bigint, integer, integer, timestamp without time zone, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_most_commented(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: get_most_read(bigint, integer, integer, timestamp without time zone, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_most_read(user_account_id bigint, page_number integer, page_size integer, since_date timestamp without time zone, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: get_top(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_top(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
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


--
-- Name: set_aotd(); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.set_aotd() RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM community_reads.community_read
		WHERE
			aotd_timestamp IS NULL AND
			core.matches_article_length(word_count, 5, NULL)
		ORDER BY hot_score DESC
		LIMIT 1
	);
$$;


--
-- Name: estimate_article_length(integer); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.estimate_article_length(word_count integer) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT greatest(1, estimate_reading_time(word_count))::int;
$$;


--
-- Name: estimate_reading_time(numeric); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.estimate_reading_time(word_count numeric) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT greatest(0, coalesce(word_count, 0) / 184)::int;
$$;


--
-- Name: generate_local_timestamp_to_utc_range_series(timestamp with time zone, timestamp with time zone, interval, text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.generate_local_timestamp_to_utc_range_series(start timestamp with time zone, stop timestamp with time zone, step interval, time_zone_name text) RETURNS TABLE(local_timestamp timestamp with time zone, utc_range tsrange)
    LANGUAGE sql IMMUTABLE
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


--
-- Name: get_time_zones(); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.get_time_zones() RETURNS SETOF core.time_zone
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM time_zone;
$$;


--
-- Name: local_now(text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.local_now(time_zone_name text) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
	SELECT now() AT TIME ZONE time_zone_name;
$$;


--
-- Name: local_to_utc_timestamp(timestamp with time zone, text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.local_to_utc_timestamp(local_timestamp timestamp with time zone, time_zone_name text) RETURNS timestamp without time zone
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT make_timestamptz_at_time_zone(local_timestamp, time_zone_name) AT TIME ZONE 'UTC';
$$;


--
-- Name: make_timestamptz_at_time_zone(timestamp with time zone, text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.make_timestamptz_at_time_zone(input_timestamp timestamp with time zone, time_zone_name text) RETURNS timestamp with time zone
    LANGUAGE sql IMMUTABLE
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


--
-- Name: matches_article_length(integer, integer, integer); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.matches_article_length(word_count integer, min_length integer, max_length integer) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT (
    	CASE WHEN min_length IS NOT NULL
        THEN (SELECT core.estimate_article_length(word_count)) >= min_length
        ELSE TRUE
        END
	) AND (
	    CASE WHEN max_length IS NOT NULL
	    THEN (SELECT core.estimate_article_length(word_count)) < max_length + 1
	    ELSE TRUE
	    END
	);
$$;


--
-- Name: utc_to_local_timestamp(timestamp with time zone, text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.utc_to_local_timestamp(utc_timestamp timestamp with time zone, time_zone_name text) RETURNS timestamp without time zone
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT make_timestamptz_at_time_zone(utc_timestamp, 'UTC') AT TIME ZONE time_zone_name;
$$;


--
-- Name: create_following(bigint, text, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_following(follower_user_id bigint, followee_user_name text, analytics text) RETURNS void
    LANGUAGE sql
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


--
-- Name: silent_post; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.silent_post (
    id bigint NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    analytics jsonb NOT NULL
);


--
-- Name: create_silent_post(bigint, bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_silent_post(user_account_id bigint, article_id bigint, analytics text) RETURNS SETOF core.silent_post
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


--
-- Name: get_followees(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_followees(user_account_id bigint) RETURNS SETOF text
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	followee.name
    FROM
    	social.active_following
    	LEFT JOIN user_account AS followee ON followee.id = active_following.followee_user_account_id
    WHERE
    	active_following.follower_user_account_id = get_followees.user_account_id;
$$;


--
-- Name: get_followers(bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_followers(viewer_user_id bigint, subject_user_name text) RETURNS SETOF social.following
    LANGUAGE sql STABLE
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


--
-- Name: get_posts_from_followees(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_followees(user_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF social.article_post_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_posts_from_user(bigint, text, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_user(viewer_user_id bigint, subject_user_name text, page_size integer, page_number integer) RETURNS SETOF social.article_post_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_profile(bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_profile(viewer_user_id bigint, subject_user_name text) RETURNS SETOF social.profile
    LANGUAGE sql STABLE
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


--
-- Name: unfollow(bigint, text, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.unfollow(follower_user_id bigint, followee_user_name text, analytics text) RETURNS void
    LANGUAGE sql
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


--
-- Name: get_current_streak(bigint); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_current_streak(user_account_id bigint) RETURNS stats.streak
    LANGUAGE sql STABLE
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


--
-- Name: get_current_streak_leaderboard(bigint, integer); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_current_streak_leaderboard(user_account_id bigint, max_rank integer) RETURNS SETOF stats.leaderboard_ranking
    LANGUAGE sql STABLE
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


--
-- Name: get_daily_reading_time_totals(bigint, integer); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_daily_reading_time_totals(user_account_id bigint, number_of_days integer) RETURNS TABLE(date date, minutes_reading integer, minutes_reading_to_completion integer)
    LANGUAGE sql STABLE
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


--
-- Name: get_longest_read_leaderboard(integer, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_longest_read_leaderboard(max_rank integer, since_date timestamp without time zone) RETURNS SETOF stats.leaderboard_ranking
    LANGUAGE sql STABLE
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


--
-- Name: get_monthly_reading_time_totals(bigint, integer); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_monthly_reading_time_totals(user_account_id bigint, number_of_months integer) RETURNS TABLE(date date, minutes_reading integer, minutes_reading_to_completion integer)
    LANGUAGE sql STABLE
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


--
-- Name: get_read_count_leaderboard(integer, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_read_count_leaderboard(max_rank integer, since_date timestamp without time zone) RETURNS SETOF stats.leaderboard_ranking
    LANGUAGE sql STABLE
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


--
-- Name: get_scout_leaderboard(integer, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_scout_leaderboard(max_rank integer, since_date timestamp without time zone) RETURNS SETOF stats.leaderboard_ranking
    LANGUAGE sql STABLE
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


--
-- Name: get_scribe_leaderboard(integer, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_scribe_leaderboard(max_rank integer, since_date timestamp without time zone) RETURNS SETOF stats.leaderboard_ranking
    LANGUAGE sql STABLE
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


--
-- Name: get_user_count(); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_user_count() RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
	SELECT
		coalesce(count(*), 0)
	FROM
		user_account;
$$;


--
-- Name: get_user_leaderboard_rankings(bigint, timestamp without time zone, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_user_leaderboard_rankings(user_account_id bigint, longest_read_since_date timestamp without time zone, scout_since_date timestamp without time zone, scribe_since_date timestamp without time zone) RETURNS TABLE(longest_read stats.ranking, read_count stats.ranking, scout_count stats.ranking, scribe_count stats.ranking, streak stats.streak_ranking, weekly_read_count stats.ranking)
    LANGUAGE sql STABLE
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


--
-- Name: get_user_read_count(bigint); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_user_read_count(user_account_id bigint) RETURNS bigint
    LANGUAGE sql STABLE
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


--
-- Name: ack_new_reply(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.ack_new_reply(user_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE user_account SET last_new_reply_ack = utc_now() WHERE id = user_account_id;
$$;


--
-- Name: change_email_address(bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.change_email_address(user_account_id bigint, email text) RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE user_account
		SET email = change_email_address.email
		WHERE id = user_account_id;
$$;


--
-- Name: change_password(bigint, bytea, bytea); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.change_password(user_account_id bigint, password_hash bytea, password_salt bytea) RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE user_account
		SET
			password_hash = change_password.password_hash,
			password_salt = change_password.password_salt
		WHERE id = user_account_id;
$$;


--
-- Name: complete_password_reset_request(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.complete_password_reset_request(password_reset_request_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	rows_updated int;
BEGIN
	UPDATE password_reset_request
		SET date_completed = utc_now()
		WHERE id = password_reset_request_id AND date_completed IS NULL;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	RETURN rows_updated = 1;
END;
$$;


--
-- Name: confirm_email_address(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.confirm_email_address(email_confirmation_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
	rows_updated int;
BEGIN
	UPDATE email_confirmation SET date_confirmed = utc_now() WHERE id = email_confirmation_id AND date_confirmed IS NULL;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	RETURN rows_updated = 1;
END;
$$;


--
-- Name: create_captcha_response(text, boolean, double precision, text, timestamp without time zone, text, text[]); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_captcha_response(action_verified text, success boolean, score double precision, action text, challenge_ts timestamp without time zone, hostname text, error_codes text[]) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO captcha_response (action_verified, success, score, action, challenge_ts, hostname, error_codes)
    VALUES (action_verified, success, score, action, challenge_ts, hostname, error_codes);
$$;


--
-- Name: create_email_confirmation(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_email_confirmation(user_account_id bigint) RETURNS SETOF core.email_confirmation
    LANGUAGE sql
    AS $$
	INSERT INTO email_confirmation (user_account_id, email_address)
		VALUES (user_account_id, (SELECT email FROM user_account WHERE id = user_account_id))
		RETURNING *;
$$;


--
-- Name: password_reset_request; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.password_reset_request (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    user_account_id bigint NOT NULL,
    email_address text NOT NULL,
    date_completed timestamp without time zone
);


--
-- Name: create_password_reset_request(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_password_reset_request(user_account_id bigint) RETURNS SETOF core.password_reset_request
    LANGUAGE sql
    AS $$
	INSERT INTO password_reset_request (user_account_id, email_address)
		VALUES (user_account_id, (SELECT email FROM user_account WHERE id = user_account_id))
		RETURNING *;
$$;


--
-- Name: create_user_account(text, text, bytea, bytea, bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_user_account(name text, email text, password_hash bytea, password_salt bytea, time_zone_id bigint, analytics text) RETURNS SETOF user_account_api.user_account
    LANGUAGE plpgsql
    AS $$
DECLARE
	user_account_id bigint;
BEGIN
	INSERT INTO
	    user_account (name, email, password_hash, password_salt, time_zone_id, creation_analytics)
	VALUES
		(trim(name), trim(email), password_hash, password_salt, time_zone_id, analytics::json)
	RETURNING id INTO user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;


--
-- Name: get_email_confirmation(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_email_confirmation(email_confirmation_id bigint) RETURNS SETOF core.email_confirmation
    LANGUAGE sql
    AS $$
	SELECT * FROM email_confirmation WHERE id = email_confirmation_id;
$$;


--
-- Name: get_latest_password_reset_request(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_latest_password_reset_request(user_account_id bigint) RETURNS SETOF core.password_reset_request
    LANGUAGE sql
    AS $$
	SELECT * FROM password_reset_request
		WHERE user_account_id = get_latest_password_reset_request.user_account_id
		ORDER BY date_created DESC
		LIMIT 1;
$$;


--
-- Name: get_latest_unconfirmed_email_confirmation(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_latest_unconfirmed_email_confirmation(user_account_id bigint) RETURNS SETOF core.email_confirmation
    LANGUAGE sql
    AS $$
	SELECT * FROM email_confirmation
		WHERE
			user_account_id = get_latest_unconfirmed_email_confirmation.user_account_id AND
			date_confirmed IS NULL
		ORDER BY date_created DESC
		LIMIT 1;
$$;


--
-- Name: get_latest_unread_reply(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_latest_unread_reply(user_account_id bigint) RETURNS SETOF article_api.user_comment
    LANGUAGE sql
    AS $$
	SELECT reply.* FROM article_api.user_comment reply
		JOIN comment parent ON reply.parent_comment_id = parent.id AND reply.user_account_id != parent.user_account_id
		JOIN user_account ON parent.user_account_id = user_account.id
		WHERE user_account.id = get_latest_unread_reply.user_account_id AND reply.date_read IS NULL
		ORDER BY reply.date_created DESC
		LIMIT 1;
$$;


--
-- Name: get_password_reset_request(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_password_reset_request(password_reset_request_id bigint) RETURNS SETOF core.password_reset_request
    LANGUAGE sql
    AS $$
	SELECT * FROM password_reset_request WHERE id = password_reset_request_id;
$$;


--
-- Name: get_user_account_by_email(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_by_email(email text) RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE lower(email) = lower(get_user_account_by_email.email);
$$;


--
-- Name: get_user_account_by_id(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_by_id(user_account_id bigint) RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE id = get_user_account_by_id.user_account_id;
$$;


--
-- Name: get_user_account_by_name(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_by_name(user_name text) RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE lower(name) = lower(get_user_account_by_name.user_name);
$$;


--
-- Name: get_user_account_id_by_name(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_id_by_name(user_name text) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
	SELECT
		id
	FROM
		core.user_account
	WHERE
		lower(name) = lower(get_user_account_id_by_name.user_name);
$$;


--
-- Name: is_email_address_confirmed(bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.is_email_address_confirmed(user_account_id bigint, email text) RETURNS boolean
    LANGUAGE sql
    AS $$
	SELECT EXISTS(
		SELECT 1 FROM email_confirmation WHERE
			user_account_id = is_email_address_confirmed.user_account_id AND
			lower(email_address) = lower(email) AND
			date_confirmed IS NOT NULL
	);
$$;


--
-- Name: list_email_confirmations(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.list_email_confirmations(user_account_id bigint) RETURNS SETOF core.email_confirmation
    LANGUAGE sql
    AS $$
	SELECT
		id,
		date_created,
		user_account_id,
		email_address,
		date_confirmed
	FROM
		email_confirmation
	WHERE
		user_account_id = list_email_confirmations.user_account_id
	ORDER BY date_created DESC;
$$;


--
-- Name: list_user_accounts(); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.list_user_accounts() RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account;
$$;


--
-- Name: record_new_reply_desktop_notification(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.record_new_reply_desktop_notification(user_account_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE user_account SET last_new_reply_desktop_notification = utc_now() WHERE id = user_account_id;
$$;


--
-- Name: update_contact_preferences(bigint, boolean, boolean); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.update_contact_preferences(user_account_id bigint, receive_website_updates boolean, receive_suggested_readings boolean) RETURNS SETOF user_account_api.user_account
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE user_account
	SET
		receive_website_updates = update_contact_preferences.receive_website_updates,
		receive_suggested_readings = update_contact_preferences.receive_suggested_readings
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;


--
-- Name: update_notification_preferences(bigint, boolean, boolean); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.update_notification_preferences(user_account_id bigint, receive_reply_email_notifications boolean, receive_reply_desktop_notifications boolean) RETURNS SETOF user_account_api.user_account
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE user_account
	SET
		receive_reply_email_notifications = update_notification_preferences.receive_reply_email_notifications,
		receive_reply_desktop_notifications = update_notification_preferences.receive_reply_desktop_notifications
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;


--
-- Name: update_time_zone(bigint, bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.update_time_zone(user_account_id bigint, time_zone_id bigint) RETURNS SETOF user_account_api.user_account
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE user_account
	SET time_zone_id = update_time_zone.time_zone_id
	WHERE id = user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;


--
-- Name: article_author; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article_author (
    article_id bigint NOT NULL,
    author_id bigint NOT NULL
);


--
-- Name: author; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.author (
    id bigint NOT NULL,
    name text NOT NULL,
    url text
);


--
-- Name: article_authors; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_authors AS
 SELECT array_agg(author.name) AS names,
    article_author.article_id
   FROM (core.author
     JOIN core.article_author ON ((article_author.author_id = author.id)))
  GROUP BY article_author.article_id;


--
-- Name: article_pages; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_pages AS
 SELECT array_agg(page.url ORDER BY page.number) AS urls,
    count(*) AS count,
    sum(page.word_count) AS word_count,
    sum(page.readable_word_count) AS readable_word_count,
    page.article_id
   FROM core.page
  GROUP BY page.article_id;


--
-- Name: article_tag; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article_tag (
    article_id bigint NOT NULL,
    tag_id bigint NOT NULL
);


--
-- Name: tag; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.tag (
    id bigint NOT NULL,
    name text NOT NULL
);


--
-- Name: article_tags; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_tags AS
 SELECT array_agg(tag.name) AS names,
    article_tag.article_id
   FROM (core.tag
     JOIN core.article_tag ON ((article_tag.tag_id = tag.id)))
  GROUP BY article_tag.article_id;


--
-- Name: user_article_rating; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.user_article_rating AS
 SELECT rating.article_id,
    rating.user_account_id,
    rating.score,
    rating."timestamp"
   FROM (core.rating
     LEFT JOIN core.rating more_recent_rating ON (((rating.article_id = more_recent_rating.article_id) AND (rating.user_account_id = more_recent_rating.user_account_id) AND (rating."timestamp" < more_recent_rating."timestamp"))))
  WHERE (more_recent_rating.id IS NULL);


--
-- Name: community_read; Type: VIEW; Schema: community_reads; Owner: -
--

CREATE VIEW community_reads.community_read AS
 SELECT article.id,
    article.aotd_timestamp,
    article.word_count,
    article.hot_score,
    article.top_score,
    article.comment_count,
    article.read_count,
    article.average_rating_score
   FROM core.article
  WHERE ((article.comment_count > 0) OR (article.read_count > 1) OR (article.average_rating_score IS NOT NULL) OR (article.silent_post_count > 0));


--
-- Name: article_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.article_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.article_id_seq OWNED BY core.article.id;


--
-- Name: author_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.author_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: author_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.author_id_seq OWNED BY core.author.id;


--
-- Name: bulk_mailing; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.bulk_mailing (
    id bigint NOT NULL,
    date_sent timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    subject text NOT NULL,
    body text NOT NULL,
    list text NOT NULL,
    user_account_id bigint NOT NULL
);


--
-- Name: bulk_mailing_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.bulk_mailing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bulk_mailing_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.bulk_mailing_id_seq OWNED BY core.bulk_mailing.id;


--
-- Name: bulk_mailing_recipient; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.bulk_mailing_recipient (
    bulk_mailing_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    is_successful boolean NOT NULL
);


--
-- Name: captcha_response; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.captcha_response (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    action_verified text NOT NULL,
    success boolean,
    score double precision,
    action text,
    challenge_ts timestamp without time zone,
    hostname text,
    error_codes text[]
);


--
-- Name: captcha_response_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.captcha_response_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: captcha_response_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.captcha_response_id_seq OWNED BY core.captcha_response.id;


--
-- Name: challenge; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.challenge (
    id bigint NOT NULL,
    name character varying(256) NOT NULL,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    award_limit integer NOT NULL
);


--
-- Name: challenge_award; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.challenge_award (
    id bigint NOT NULL,
    challenge_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_awarded timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_fulfilled timestamp without time zone,
    reference character varying(1024)
);


--
-- Name: challenge_award_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.challenge_award_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_award_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.challenge_award_id_seq OWNED BY core.challenge_award.id;


--
-- Name: challenge_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.challenge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.challenge_id_seq OWNED BY core.challenge.id;


--
-- Name: challenge_response; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.challenge_response (
    id bigint NOT NULL,
    challenge_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    action core.challenge_response_action NOT NULL,
    time_zone_id bigint
);


--
-- Name: challenge_response_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.challenge_response_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: challenge_response_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.challenge_response_id_seq OWNED BY core.challenge_response.id;


--
-- Name: client_error_report; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.client_error_report (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    content text,
    analytics jsonb
);


--
-- Name: client_error_report_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.client_error_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_error_report_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.client_error_report_id_seq OWNED BY core.client_error_report.id;


--
-- Name: comment_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.comment_id_seq OWNED BY core.comment.id;


--
-- Name: email_confirmation_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.email_confirmation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_confirmation_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.email_confirmation_id_seq OWNED BY core.email_confirmation.id;


--
-- Name: email_notification; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.email_notification (
    id bigint NOT NULL,
    notification_type text NOT NULL,
    mail jsonb,
    bounce jsonb,
    complaint jsonb
);


--
-- Name: email_notification_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.email_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.email_notification_id_seq OWNED BY core.email_notification.id;


--
-- Name: email_share; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.email_share (
    id bigint NOT NULL,
    date_sent timestamp without time zone NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    message character varying(10000)
);


--
-- Name: email_share_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.email_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_share_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.email_share_id_seq OWNED BY core.email_share.id;


--
-- Name: email_share_recipient; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.email_share_recipient (
    id bigint NOT NULL,
    email_share_id bigint NOT NULL,
    email_address character varying(256) NOT NULL,
    user_account_id bigint,
    is_successful boolean NOT NULL
);


--
-- Name: email_share_recipient_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.email_share_recipient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_share_recipient_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.email_share_recipient_id_seq OWNED BY core.email_share_recipient.id;


--
-- Name: extension_installation; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.extension_installation (
    id bigint NOT NULL,
    "timestamp" timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    installation_id uuid NOT NULL,
    user_account_id bigint,
    platform text NOT NULL
);


--
-- Name: extension_installation_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.extension_installation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extension_installation_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.extension_installation_id_seq OWNED BY core.extension_installation.id;


--
-- Name: extension_removal; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.extension_removal (
    id bigint NOT NULL,
    "timestamp" timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    installation_id uuid NOT NULL,
    user_account_id bigint,
    reason text
);


--
-- Name: extension_removal_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.extension_removal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extension_removal_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.extension_removal_id_seq OWNED BY core.extension_removal.id;


--
-- Name: following; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.following (
    id bigint NOT NULL,
    follower_user_account_id bigint NOT NULL,
    followee_user_account_id bigint NOT NULL,
    date_followed timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_unfollowed timestamp without time zone,
    follow_analytics jsonb NOT NULL,
    unfollow_analytics jsonb,
    CONSTRAINT following_check CHECK ((follower_user_account_id <> followee_user_account_id))
);


--
-- Name: following_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.following_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: following_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.following_id_seq OWNED BY core.following.id;


--
-- Name: page_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.page_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: page_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.page_id_seq OWNED BY core.page.id;


--
-- Name: password_reset_request_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.password_reset_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_reset_request_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.password_reset_request_id_seq OWNED BY core.password_reset_request.id;


--
-- Name: rating_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.rating_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rating_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.rating_id_seq OWNED BY core.rating.id;


--
-- Name: silent_post_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.silent_post_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: silent_post_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.silent_post_id_seq OWNED BY core.silent_post.id;


--
-- Name: source_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.source_id_seq OWNED BY core.source.id;


--
-- Name: source_rule_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.source_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: source_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.source_rule_id_seq OWNED BY core.source_rule.id;


--
-- Name: star; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.star (
    user_account_id bigint NOT NULL,
    article_id bigint NOT NULL,
    date_starred timestamp without time zone DEFAULT core.utc_now() NOT NULL
);


--
-- Name: tag_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.tag_id_seq OWNED BY core.tag.id;


--
-- Name: user_account_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.user_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_account_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.user_account_id_seq OWNED BY core.user_account.id;


--
-- Name: user_article_progress; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_article_progress (
    id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    article_id bigint NOT NULL,
    period timestamp without time zone NOT NULL,
    words_read integer NOT NULL,
    client_type text
);


--
-- Name: user_article_progress_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.user_article_progress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_article_progress_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.user_article_progress_id_seq OWNED BY core.user_article_progress.id;


--
-- Name: user_page_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.user_page_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_page_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.user_page_id_seq OWNED BY core.user_article.id;


--
-- Name: active_following; Type: VIEW; Schema: social; Owner: -
--

CREATE VIEW social.active_following AS
 SELECT following.id,
    following.follower_user_account_id,
    following.followee_user_account_id,
    following.date_followed
   FROM core.following
  WHERE (following.date_unfollowed IS NULL);


--
-- Name: post; Type: VIEW; Schema: social; Owner: -
--

CREATE VIEW social.post AS
 SELECT comment.article_id,
    comment.user_account_id,
    comment.date_created,
    comment.id AS comment_id,
    comment.text AS comment_text
   FROM core.comment
  WHERE (comment.parent_comment_id IS NULL)
UNION ALL
 SELECT silent_post.article_id,
    silent_post.user_account_id,
    silent_post.date_created,
    NULL::bigint AS comment_id,
    NULL::text AS comment_text
   FROM core.silent_post;


--
-- Name: current_streak; Type: MATERIALIZED VIEW; Schema: stats; Owner: -
--

CREATE MATERIALIZED VIEW stats.current_streak AS
 SELECT user_account.id AS user_account_id,
    user_account.name AS user_name,
    current_streak.day_count AS streak
   FROM ((core.user_account
     JOIN ( SELECT user_article.user_account_id,
            max(user_article.date_completed) AS date_completed
           FROM core.user_article
          WHERE (user_article.date_completed >= (core.utc_now() - '37:00:00'::interval))
          GROUP BY user_article.user_account_id) latest_read ON ((latest_read.user_account_id = user_account.id)))
     JOIN LATERAL stats.get_current_streak(user_account.id) current_streak(day_count, includes_today) ON ((user_account.time_zone_id IS NOT NULL)))
  WHERE (current_streak.day_count > 0)
  WITH NO DATA;


--
-- Name: scouting; Type: VIEW; Schema: stats; Owner: -
--

CREATE VIEW stats.scouting AS
 SELECT article.id AS article_id,
    article.aotd_timestamp,
    post.user_account_id
   FROM ((core.article
     JOIN social.post ON ((post.article_id = article.id)))
     LEFT JOIN social.post earlier_post ON (((earlier_post.article_id = post.article_id) AND (earlier_post.date_created < post.date_created))))
  WHERE ((article.aotd_timestamp IS NOT NULL) AND (earlier_post.date_created IS NULL));


--
-- Name: scribe_comment; Type: VIEW; Schema: stats; Owner: -
--

CREATE VIEW stats.scribe_comment AS
 SELECT comment.id,
    comment.date_created,
    comment.user_account_id
   FROM (core.comment
     LEFT JOIN core.comment reply ON ((reply.parent_comment_id = comment.id)))
  WHERE ((comment.parent_comment_id IS NOT NULL) OR (reply.user_account_id <> comment.user_account_id));


--
-- Name: article id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article ALTER COLUMN id SET DEFAULT nextval('core.article_id_seq'::regclass);


--
-- Name: author id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author ALTER COLUMN id SET DEFAULT nextval('core.author_id_seq'::regclass);


--
-- Name: bulk_mailing id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing ALTER COLUMN id SET DEFAULT nextval('core.bulk_mailing_id_seq'::regclass);


--
-- Name: captcha_response id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.captcha_response ALTER COLUMN id SET DEFAULT nextval('core.captcha_response_id_seq'::regclass);


--
-- Name: challenge id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge ALTER COLUMN id SET DEFAULT nextval('core.challenge_id_seq'::regclass);


--
-- Name: challenge_award id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_award ALTER COLUMN id SET DEFAULT nextval('core.challenge_award_id_seq'::regclass);


--
-- Name: challenge_response id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_response ALTER COLUMN id SET DEFAULT nextval('core.challenge_response_id_seq'::regclass);


--
-- Name: client_error_report id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.client_error_report ALTER COLUMN id SET DEFAULT nextval('core.client_error_report_id_seq'::regclass);


--
-- Name: comment id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment ALTER COLUMN id SET DEFAULT nextval('core.comment_id_seq'::regclass);


--
-- Name: email_confirmation id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_confirmation ALTER COLUMN id SET DEFAULT nextval('core.email_confirmation_id_seq'::regclass);


--
-- Name: email_notification id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_notification ALTER COLUMN id SET DEFAULT nextval('core.email_notification_id_seq'::regclass);


--
-- Name: email_share id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share ALTER COLUMN id SET DEFAULT nextval('core.email_share_id_seq'::regclass);


--
-- Name: email_share_recipient id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share_recipient ALTER COLUMN id SET DEFAULT nextval('core.email_share_recipient_id_seq'::regclass);


--
-- Name: extension_installation id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_installation ALTER COLUMN id SET DEFAULT nextval('core.extension_installation_id_seq'::regclass);


--
-- Name: extension_removal id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_removal ALTER COLUMN id SET DEFAULT nextval('core.extension_removal_id_seq'::regclass);


--
-- Name: following id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.following ALTER COLUMN id SET DEFAULT nextval('core.following_id_seq'::regclass);


--
-- Name: page id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.page ALTER COLUMN id SET DEFAULT nextval('core.page_id_seq'::regclass);


--
-- Name: password_reset_request id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.password_reset_request ALTER COLUMN id SET DEFAULT nextval('core.password_reset_request_id_seq'::regclass);


--
-- Name: rating id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.rating ALTER COLUMN id SET DEFAULT nextval('core.rating_id_seq'::regclass);


--
-- Name: silent_post id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.silent_post ALTER COLUMN id SET DEFAULT nextval('core.silent_post_id_seq'::regclass);


--
-- Name: source id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source ALTER COLUMN id SET DEFAULT nextval('core.source_id_seq'::regclass);


--
-- Name: source_rule id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source_rule ALTER COLUMN id SET DEFAULT nextval('core.source_rule_id_seq'::regclass);


--
-- Name: tag id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag ALTER COLUMN id SET DEFAULT nextval('core.tag_id_seq'::regclass);


--
-- Name: user_account id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_account ALTER COLUMN id SET DEFAULT nextval('core.user_account_id_seq'::regclass);


--
-- Name: user_article id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article ALTER COLUMN id SET DEFAULT nextval('core.user_page_id_seq'::regclass);


--
-- Name: user_article_progress id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article_progress ALTER COLUMN id SET DEFAULT nextval('core.user_article_progress_id_seq'::regclass);


--
-- Name: article_author article_author_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_pkey PRIMARY KEY (article_id, author_id);


--
-- Name: article article_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article
    ADD CONSTRAINT article_pkey PRIMARY KEY (id);


--
-- Name: article article_slug_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article
    ADD CONSTRAINT article_slug_key UNIQUE (slug);


--
-- Name: article_tag article_tag_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_tag
    ADD CONSTRAINT article_tag_pkey PRIMARY KEY (article_id, tag_id);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: bulk_mailing bulk_mailing_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing
    ADD CONSTRAINT bulk_mailing_pkey PRIMARY KEY (id);


--
-- Name: bulk_mailing_recipient bulk_mailing_recipient_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing_recipient
    ADD CONSTRAINT bulk_mailing_recipient_pkey PRIMARY KEY (bulk_mailing_id, user_account_id);


--
-- Name: captcha_response captcha_response_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.captcha_response
    ADD CONSTRAINT captcha_response_pkey PRIMARY KEY (id);


--
-- Name: challenge_award challenge_award_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_award
    ADD CONSTRAINT challenge_award_pkey PRIMARY KEY (id);


--
-- Name: challenge challenge_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge
    ADD CONSTRAINT challenge_pkey PRIMARY KEY (id);


--
-- Name: challenge_response challenge_response_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_response
    ADD CONSTRAINT challenge_response_pkey PRIMARY KEY (id);


--
-- Name: client_error_report client_error_report_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.client_error_report
    ADD CONSTRAINT client_error_report_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: email_confirmation email_confirmation_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_confirmation
    ADD CONSTRAINT email_confirmation_pkey PRIMARY KEY (id);


--
-- Name: email_notification email_notification_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_notification
    ADD CONSTRAINT email_notification_pkey PRIMARY KEY (id);


--
-- Name: email_share email_share_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share
    ADD CONSTRAINT email_share_pkey PRIMARY KEY (id);


--
-- Name: email_share_recipient email_share_recipient_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share_recipient
    ADD CONSTRAINT email_share_recipient_pkey PRIMARY KEY (id);


--
-- Name: extension_installation extension_installation_installation_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_installation
    ADD CONSTRAINT extension_installation_installation_id_key UNIQUE (installation_id);


--
-- Name: extension_installation extension_installation_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_installation
    ADD CONSTRAINT extension_installation_pkey PRIMARY KEY (id);


--
-- Name: extension_removal extension_removal_installation_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_removal
    ADD CONSTRAINT extension_removal_installation_id_key UNIQUE (installation_id);


--
-- Name: extension_removal extension_removal_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_removal
    ADD CONSTRAINT extension_removal_pkey PRIMARY KEY (id);


--
-- Name: following following_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.following
    ADD CONSTRAINT following_pkey PRIMARY KEY (id);


--
-- Name: page page_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.page
    ADD CONSTRAINT page_pkey PRIMARY KEY (id);


--
-- Name: password_reset_request password_reset_request_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.password_reset_request
    ADD CONSTRAINT password_reset_request_pkey PRIMARY KEY (id);


--
-- Name: rating rating_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.rating
    ADD CONSTRAINT rating_pkey PRIMARY KEY (id);


--
-- Name: silent_post silent_post_article_id_user_account_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.silent_post
    ADD CONSTRAINT silent_post_article_id_user_account_id_key UNIQUE (article_id, user_account_id);


--
-- Name: silent_post silent_post_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.silent_post
    ADD CONSTRAINT silent_post_pkey PRIMARY KEY (id);


--
-- Name: source source_hostname_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source
    ADD CONSTRAINT source_hostname_key UNIQUE (hostname);


--
-- Name: source source_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source
    ADD CONSTRAINT source_pkey PRIMARY KEY (id);


--
-- Name: source_rule source_rule_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source_rule
    ADD CONSTRAINT source_rule_pkey PRIMARY KEY (id);


--
-- Name: source source_slug_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.source
    ADD CONSTRAINT source_slug_key UNIQUE (slug);


--
-- Name: star star_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.star
    ADD CONSTRAINT star_pkey PRIMARY KEY (user_account_id, article_id);


--
-- Name: tag tag_name_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag
    ADD CONSTRAINT tag_name_key UNIQUE (name);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);


--
-- Name: time_zone time_zone_name_territory_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.time_zone
    ADD CONSTRAINT time_zone_name_territory_key UNIQUE (name, territory);


--
-- Name: time_zone time_zone_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.time_zone
    ADD CONSTRAINT time_zone_pkey PRIMARY KEY (id);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_article_progress user_article_progress_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article_progress
    ADD CONSTRAINT user_article_progress_pkey PRIMARY KEY (id);


--
-- Name: user_article_progress user_article_progress_user_account_id_article_id_period_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article_progress
    ADD CONSTRAINT user_article_progress_user_account_id_article_id_period_key UNIQUE (user_account_id, article_id, period);


--
-- Name: user_article user_page_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_page_pkey PRIMARY KEY (id);


--
-- Name: article_aotd_timestamp_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_aotd_timestamp_idx ON core.article USING btree (aotd_timestamp DESC NULLS LAST);


--
-- Name: article_average_rating_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_average_rating_score_idx ON core.article USING btree (average_rating_score DESC);


--
-- Name: article_comment_count_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_comment_count_idx ON core.article USING btree (comment_count DESC);


--
-- Name: article_hot_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_hot_score_idx ON core.article USING btree (hot_score DESC);


--
-- Name: article_read_count_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_read_count_idx ON core.article USING btree (read_count DESC);


--
-- Name: article_silent_post_count_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_silent_post_count_idx ON core.article USING btree (silent_post_count);


--
-- Name: article_top_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_top_score_idx ON core.article USING btree (top_score DESC);


--
-- Name: article_word_count_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_word_count_idx ON core.article USING btree (word_count);


--
-- Name: comment_article_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX comment_article_id_idx ON core.comment USING btree (article_id);


--
-- Name: following_follower_user_account_id_followee_user_account_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX following_follower_user_account_id_followee_user_account_id_idx ON core.following USING btree (follower_user_account_id, followee_user_account_id) WHERE (date_unfollowed IS NULL);


--
-- Name: page_article_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX page_article_id_idx ON core.page USING btree (article_id);


--
-- Name: user_account_email_key; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX user_account_email_key ON core.user_account USING btree (lower((email)::text));


--
-- Name: user_account_name_key; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX user_account_name_key ON core.user_account USING btree (lower((name)::text));


--
-- Name: user_article_article_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_article_article_id_idx ON core.user_article USING btree (article_id);


--
-- Name: user_page_date_completed_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_page_date_completed_idx ON core.user_article USING btree (date_completed);


--
-- Name: user_page_user_account_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_page_user_account_id_idx ON core.user_article USING btree (user_account_id);


--
-- Name: current_streak_user_account_id_idx; Type: INDEX; Schema: stats; Owner: -
--

CREATE UNIQUE INDEX current_streak_user_account_id_idx ON stats.current_streak USING btree (user_account_id);


--
-- Name: article_author article_author_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: article_author article_author_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_author_id_fkey FOREIGN KEY (author_id) REFERENCES core.author(id);


--
-- Name: article article_source_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article
    ADD CONSTRAINT article_source_id_fkey FOREIGN KEY (source_id) REFERENCES core.source(id);


--
-- Name: article_tag article_tag_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_tag
    ADD CONSTRAINT article_tag_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: article_tag article_tag_tag_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_tag
    ADD CONSTRAINT article_tag_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES core.tag(id);


--
-- Name: bulk_mailing_recipient bulk_mailing_recipient_bulk_mailing_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing_recipient
    ADD CONSTRAINT bulk_mailing_recipient_bulk_mailing_id_fkey FOREIGN KEY (bulk_mailing_id) REFERENCES core.bulk_mailing(id);


--
-- Name: bulk_mailing_recipient bulk_mailing_recipient_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing_recipient
    ADD CONSTRAINT bulk_mailing_recipient_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: bulk_mailing bulk_mailing_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.bulk_mailing
    ADD CONSTRAINT bulk_mailing_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: challenge_award challenge_award_challenge_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_award
    ADD CONSTRAINT challenge_award_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES core.challenge(id);


--
-- Name: challenge_award challenge_award_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_award
    ADD CONSTRAINT challenge_award_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: challenge_response challenge_response_challenge_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_response
    ADD CONSTRAINT challenge_response_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES core.challenge(id);


--
-- Name: challenge_response challenge_response_time_zone_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_response
    ADD CONSTRAINT challenge_response_time_zone_id_fkey FOREIGN KEY (time_zone_id) REFERENCES core.time_zone(id);


--
-- Name: challenge_response challenge_response_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.challenge_response
    ADD CONSTRAINT challenge_response_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: comment comment_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment
    ADD CONSTRAINT comment_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: comment comment_parent_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment
    ADD CONSTRAINT comment_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES core.comment(id);


--
-- Name: comment comment_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment
    ADD CONSTRAINT comment_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: email_confirmation email_confirmation_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_confirmation
    ADD CONSTRAINT email_confirmation_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: email_share email_share_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share
    ADD CONSTRAINT email_share_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: email_share_recipient email_share_recipient_email_share_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share_recipient
    ADD CONSTRAINT email_share_recipient_email_share_id_fkey FOREIGN KEY (email_share_id) REFERENCES core.email_share(id);


--
-- Name: email_share_recipient email_share_recipient_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share_recipient
    ADD CONSTRAINT email_share_recipient_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: email_share email_share_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.email_share
    ADD CONSTRAINT email_share_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: extension_installation extension_installation_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_installation
    ADD CONSTRAINT extension_installation_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: extension_removal extension_removal_installation_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_removal
    ADD CONSTRAINT extension_removal_installation_id_fkey FOREIGN KEY (installation_id) REFERENCES core.extension_installation(installation_id);


--
-- Name: extension_removal extension_removal_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.extension_removal
    ADD CONSTRAINT extension_removal_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: following following_followee_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.following
    ADD CONSTRAINT following_followee_user_account_id_fkey FOREIGN KEY (followee_user_account_id) REFERENCES core.user_account(id);


--
-- Name: following following_follower_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.following
    ADD CONSTRAINT following_follower_user_account_id_fkey FOREIGN KEY (follower_user_account_id) REFERENCES core.user_account(id);


--
-- Name: page page_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.page
    ADD CONSTRAINT page_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: password_reset_request password_reset_request_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.password_reset_request
    ADD CONSTRAINT password_reset_request_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: rating rating_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.rating
    ADD CONSTRAINT rating_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: rating rating_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.rating
    ADD CONSTRAINT rating_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: silent_post silent_post_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.silent_post
    ADD CONSTRAINT silent_post_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: silent_post silent_post_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.silent_post
    ADD CONSTRAINT silent_post_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: star star_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.star
    ADD CONSTRAINT star_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: star star_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.star
    ADD CONSTRAINT star_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: user_account user_account_time_zone_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_account
    ADD CONSTRAINT user_account_time_zone_id_fkey FOREIGN KEY (time_zone_id) REFERENCES core.time_zone(id);


--
-- Name: user_article user_article_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_article_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: user_article_progress user_article_progress_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article_progress
    ADD CONSTRAINT user_article_progress_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: user_article_progress user_article_progress_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article_progress
    ADD CONSTRAINT user_article_progress_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: user_article user_page_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_page_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: current_streak; Type: MATERIALIZED VIEW DATA; Schema: stats; Owner: -
--

REFRESH MATERIALIZED VIEW stats.current_streak;


--
-- PostgreSQL database dump complete
--

