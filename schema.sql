--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.8
-- Dumped by pg_dump version 11.2

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
-- Name: article_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA article_api;


--
-- Name: bulk_mailing_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bulk_mailing_api;


--
-- Name: core; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA core;


--
-- Name: stats_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA stats_api;


--
-- Name: user_account_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA user_account_api;


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
	rating_score core.rating_score
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
    top_score integer DEFAULT 0 NOT NULL
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
    date_read timestamp without time zone
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
-- Name: create_comment(text, bigint, bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_comment(text text, article_id bigint, parent_comment_id bigint, user_account_id bigint) RETURNS SETOF article_api.user_comment
    LANGUAGE plpgsql
    AS $$
DECLARE
  comment_id bigint;
BEGIN
	INSERT INTO comment
        (text, article_id, parent_comment_id, user_account_id) VALUES
        (text, article_id, parent_comment_id, user_account_id) RETURNING id INTO comment_id;
    RETURN QUERY SELECT * FROM article_api.user_comment WHERE id = comment_id;
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

CREATE FUNCTION article_api.create_page(article_id bigint, number integer, word_count integer, readable_word_count integer, url text) RETURNS core.page
    LANGUAGE sql
    AS $$
	INSERT INTO page (article_id, number, word_count, readable_word_count, url)
		VALUES (article_id, number, word_count, readable_word_count, url)
		RETURNING *;
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
-- Name: user_page; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_page (
    id bigint NOT NULL,
    page_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    last_modified timestamp without time zone,
    read_state integer[] NOT NULL,
    words_read integer DEFAULT 0 NOT NULL,
    date_completed timestamp without time zone,
    readable_word_count integer NOT NULL
);


--
-- Name: create_user_page(bigint, bigint, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_user_page(page_id bigint, user_account_id bigint, readable_word_count integer) RETURNS core.user_page
    LANGUAGE sql
    AS $$
	INSERT INTO user_page (
	   page_id,
	   user_account_id,
	   read_state,
	   readable_word_count
	)
	VALUES (
		create_user_page.page_id,
		create_user_page.user_account_id,
		ARRAY[(SELECT -create_user_page.readable_word_count)],
	   create_user_page.readable_word_count
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
-- Name: get_aotd(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_aotd(user_account_id bigint) RETURNS SETOF article_api.article
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
-- Name: get_article_history(bigint, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_article_history(user_account_id bigint, page_number integer, page_size integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
	WITH history_article AS (
		SELECT
			greatest(article.date_created, article.last_modified, star.date_starred) AS history_date,
			coalesce(article.article_id, star.article_id) AS article_id
		FROM
			(
				SELECT
					date_created,
					last_modified,
					article_id
				FROM article_api.user_article_pages
				WHERE user_account_id = get_article_history.user_account_id
			) AS article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE user_account_id = get_article_history.user_account_id
			) AS star ON star.article_id = article.article_id
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
		article_pages.word_count,
		coalesce(article_comment_count.count, 0) AS comment_count,
		coalesce(article_read_count.count, 0) AS read_count,
		user_article_pages.date_created,
		coalesce(
		   article_api.get_percent_complete(
		      user_article_pages.readable_word_count,
		      user_article_pages.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article_pages.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred,
	   average_article_rating.score AS average_rating_score,
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
		LEFT JOIN article_api.article_comment_count ON (
			article_comment_count.article_id = article.id AND
			article_comment_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_read_count ON (
			article_read_count.article_id = article.id AND
			article_read_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.average_article_rating ON (
			average_article_rating.article_id = article.id AND
			average_article_rating.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.user_article_pages ON (
		   user_article_pages.user_account_id = get_articles.user_account_id AND
			user_article_pages.article_id = article.id AND
			user_article_pages.article_id = ANY (article_ids)
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


--
-- Name: get_comment(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_comment(comment_id bigint) RETURNS SETOF article_api.user_comment
    LANGUAGE sql
    AS $$
	SELECT * FROM article_api.user_comment WHERE id = comment_id;
$$;


--
-- Name: get_community_reads(bigint, integer, integer, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_community_reads(user_account_id bigint, page_number integer, page_size integer, sort text) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
	SELECT
		articles.*,
		(SELECT count(*) FROM article_api.community_read) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article_api.community_read
			ORDER BY CASE sort
				WHEN 'hot' THEN hot_score
				WHEN 'top' THEN top_score
			END DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
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
	      (coalesce(words_read, 0)::double precision / coalesce(readable_word_count, 1)) * 100,
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
-- Name: get_starred_articles(bigint, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_starred_articles(user_account_id bigint, page_number integer, page_size integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
    AS $$
	WITH starred_article AS (
		SELECT
			article_id,
			date_starred
		FROM star
		WHERE user_account_id = get_starred_articles.user_account_id
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
-- Name: get_user_page(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_user_page(page_id bigint, user_account_id bigint) RETURNS SETOF core.user_page
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_page
	WHERE (
		page_id = get_user_page.page_id AND
		user_account_id = get_user_page.user_account_id
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

CREATE FUNCTION article_api.rate_article(article_id bigint, user_account_id bigint, score core.rating_score) RETURNS SETOF core.rating
    LANGUAGE sql STRICT
    AS $$
	INSERT INTO rating (score, article_id, user_account_id)
	VALUES (score, article_id, user_account_id)
	RETURNING *;
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
	UPDATE article
	SET
	    hot_score = coalesce(article_score.hot_score, 0),
	    top_score = coalesce(article_score.top_score, 0)
	FROM article_api.article_score
	WHERE article_score.article_id = article.id;
$$;


--
-- Name: set_aotd(); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.set_aotd() RETURNS void
    LANGUAGE sql
    AS $$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM
			article
			JOIN article_api.article_pages ON article_pages.article_id = article.id
		WHERE
			aotd_timestamp IS NULL AND
			word_count >= (184 * 5) AND
			hot_score > 0
		ORDER BY hot_score DESC
		LIMIT 1
	);
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
    LANGUAGE sql
    AS $$
	UPDATE page
	SET
	    word_count = update_page.word_count,
	    readable_word_count = update_page.readable_word_count
	WHERE page.id = update_page.page_id
	RETURNING *;
$$;


--
-- Name: update_read_progress(bigint, integer[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.update_read_progress(user_page_id bigint, read_state integer[]) RETURNS core.user_page
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	words_read CONSTANT int NOT NULL := (SELECT sum(n) FROM unnest(read_state) AS n WHERE n > 0);
	page_id bigint;
	is_complete boolean;
	updated_user_page user_page;
BEGIN
	-- get the page_id and cache the completion state before updating the progress
	SELECT
		user_page.page_id,
		user_page.date_completed IS NOT NULL
	INTO
		locals.page_id,
		locals.is_complete
	FROM user_page
	WHERE user_page.id = update_read_progress.user_page_id;
	-- update the progress
	UPDATE user_page
	SET
		read_state = update_read_progress.read_state,
		words_read = locals.words_read,
		last_modified = utc_now()
	WHERE user_page.id = update_read_progress.user_page_id
	RETURNING * INTO locals.updated_user_page;
	-- check if this update completed the page
	IF
		NOT is_complete AND
		(
		   SELECT article_api.get_percent_complete(
		      locals.updated_user_page.readable_word_count,
		      locals.words_read
		   ) >= 90
		)
	THEN
		-- set date_completed
		UPDATE user_page
		SET date_completed = user_page.last_modified
		WHERE user_page.id = update_read_progress.user_page_id
		RETURNING * INTO locals.updated_user_page;
	END IF;
	-- return
	RETURN locals.updated_user_page;
END;
$$;


--
-- Name: update_user_page(bigint, integer, integer[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.update_user_page(user_page_id bigint, readable_word_count integer, read_state integer[]) RETURNS core.user_page
    LANGUAGE sql
    AS $$
	UPDATE user_page
	SET
		readable_word_count = update_user_page.readable_word_count,
		read_state = update_user_page.read_state
	WHERE user_page.id = update_user_page.user_page_id
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
-- Name: generate_local_to_utc_date_series(date, date, integer, text); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.generate_local_to_utc_date_series(start date, stop date, day_step_count integer, time_zone_name text) RETURNS TABLE(local_day date, utc_range tsrange)
    LANGUAGE sql IMMUTABLE
    AS $$
	WITH day_pair AS (
		SELECT
			cast(local_day AS date) AS local_day,
			make_timestamptz(
				extract(year FROM local_day)::int,
				extract(month FROM local_day)::int,
				extract(day FROM local_day)::int,
				extract(hour FROM local_day)::int,
				extract(minute FROM local_day)::int,
				extract(second FROM local_day)::int,
				generate_local_to_utc_date_series.time_zone_name
			) AT TIME ZONE 'UTC' AS utc_day
		FROM
			generate_series(
				start,
				stop,
				make_interval(
					days => generate_local_to_utc_date_series.day_step_count
				)
			) AS local_day
	)
	SELECT
		local_day,
		tsrange(
			utc_day,
			utc_day + '1 day'::interval
		)
	FROM day_pair;
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
-- Name: get_current_streak(bigint); Type: FUNCTION; Schema: stats_api; Owner: -
--

CREATE FUNCTION stats_api.get_current_streak(user_account_id bigint) RETURNS bigint
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
			FROM generate_local_to_utc_date_series(
				cast(local_now((SELECT name FROM user_time_zone)) - '1 day'::interval AS date),
				cast(local_now((SELECT name FROM user_time_zone)) AS date),
				1,
				(SELECT name FROM user_time_zone)
			)
		),
		streak_start_daily_read_count AS (
			SELECT
				streak_start_day.local_day,
				streak_start_day.utc_range,
				count(*) FILTER (WHERE date_completed IS NOT NULL) AS read_count
			FROM
				streak_start_day
				LEFT JOIN (
					SELECT
						user_page.date_completed
					FROM
						user_page
						JOIN page ON user_page.page_id = page.id
					WHERE
						user_page.user_account_id = get_current_streak.user_account_id AND
						user_page.date_completed <@ tsrange(
							lower((SELECT utc_range FROM streak_start_day ORDER BY local_day LIMIT 1)),
							upper((SELECT utc_range FROM streak_start_day ORDER BY local_day DESC LIMIT 1))
						)
				) AS user_page ON streak_start_day.utc_range @> user_page.date_completed
			GROUP BY
				streak_start_day.local_day, streak_start_day.utc_range
		),
		streak_start_qualified_day AS (
			SELECT
				local_day,
				utc_range,
				CASE WHEN
					local_day = first_value(local_day) OVER local_day_desc AND
					lead(read_count) OVER local_day_desc > 0
					THEN TRUE
					ELSE read_count > 0
				END AS is_qualifying_day
			FROM
				streak_start_daily_read_count
			WINDOW
				local_day_desc AS (ORDER BY local_day DESC)
		)
		SELECT
			local_day,
			utc_range
		FROM streak_start_qualified_day
		WHERE is_qualifying_day
		UNION ALL
		(
			WITH next_day AS (
				SELECT
					cast(local_day - '1 day'::interval AS date) AS local_day,
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
				user_page
				JOIN page ON user_page.page_id = page.id
			WHERE
				user_page.user_account_id = get_current_streak.user_account_id AND
				user_page.date_completed <@ (SELECT utc_range FROM next_day)
		)
	)
	SELECT
		count(DISTINCT local_day)
	FROM
		streak_day;
$$;


--
-- Name: get_current_streak_leaderboard(bigint, integer); Type: FUNCTION; Schema: stats_api; Owner: -
--

CREATE FUNCTION stats_api.get_current_streak_leaderboard(user_account_id bigint, max_count integer) RETURNS TABLE(name text, streak bigint)
    LANGUAGE sql STABLE
    AS $$
	SELECT
		name,
		streak
	FROM
		(
			SELECT
				id,
				name,
				streak
			FROM
				stats_api.current_streak
			WHERE
				id != coalesce(get_current_streak_leaderboard.user_account_id, 0)
			UNION ALL
			SELECT
				user_account.id,
				user_account.name,
				streak
			FROM
				user_account
				JOIN stats_api.get_current_streak(user_account.id) AS streak ON TRUE
			WHERE
				user_account.id = coalesce(get_current_streak_leaderboard.user_account_id, 0) AND
				streak > 0
		) AS updated_current_streak
	ORDER BY
		streak DESC,
		id
	LIMIT get_current_streak_leaderboard.max_count;
$$;


--
-- Name: get_read_count_leaderboard(integer); Type: FUNCTION; Schema: stats_api; Owner: -
--

CREATE FUNCTION stats_api.get_read_count_leaderboard(max_count integer) RETURNS TABLE(name text, read_count bigint)
    LANGUAGE sql STABLE
    AS $$
	SELECT
		user_account.name,
		count(*) AS read_count
	FROM
		user_page
		JOIN user_account ON user_page.user_account_id = user_account.id
	WHERE
		user_page.date_completed IS NOT NULL
	GROUP BY
		user_account.id
	ORDER BY
		read_count DESC
	LIMIT
		get_read_count_leaderboard.max_count;
$$;


--
-- Name: get_user_stats(bigint); Type: FUNCTION; Schema: stats_api; Owner: -
--

CREATE FUNCTION stats_api.get_user_stats(user_account_id bigint) RETURNS TABLE(read_count bigint, read_count_rank bigint, streak bigint, streak_rank bigint, user_count bigint)
    LANGUAGE sql STABLE
    AS $$
	WITH read_count_ranking AS (
		SELECT
			user_account_id,
			count(*) AS count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS rank
		FROM
			user_page
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
-- Name: create_user_account(text, text, bytea, bytea, bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_user_account(name text, email text, password_hash bytea, password_salt bytea, time_zone_id bigint) RETURNS SETOF user_account_api.user_account
    LANGUAGE plpgsql
    AS $$
DECLARE
	user_account_id bigint;
BEGIN
	INSERT INTO user_account (name, email, password_hash, password_salt, time_zone_id)
		VALUES (trim(name), trim(email), password_hash, password_salt, time_zone_id)
		RETURNING id INTO user_account_id;
	RETURN QUERY
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
END;
$$;


--
-- Name: find_user_account(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.find_user_account(email text) RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE lower(email) = lower(find_user_account.email);
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
-- Name: get_user_account(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account(user_account_id bigint) RETURNS SETOF user_account_api.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM user_account_api.user_account
	WHERE id = user_account_id;
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
-- Name: article_comment_count; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_comment_count AS
 SELECT count(*) AS count,
    comment.article_id
   FROM core.comment
  GROUP BY comment.article_id;


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
-- Name: user_article_pages; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.user_article_pages AS
 SELECT sum(user_page.readable_word_count) AS readable_word_count,
    sum(user_page.words_read) AS words_read,
    min(user_page.date_created) AS date_created,
    max(user_page.last_modified) AS last_modified,
    max(user_page.date_completed) AS date_completed,
    user_page.user_account_id,
    page.article_id
   FROM (core.user_page
     JOIN core.page ON ((page.id = user_page.page_id)))
  GROUP BY user_page.user_account_id, page.article_id;


--
-- Name: article_read_count; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_read_count AS
 SELECT count(*) AS count,
    user_article_pages.article_id
   FROM article_api.user_article_pages
  WHERE (user_article_pages.date_completed IS NOT NULL)
  GROUP BY user_article_pages.article_id;


--
-- Name: article_score; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.article_score AS
 SELECT article_pages.article_id,
        CASE
            WHEN ((comments.count > 0) OR (reads.count > 1)) THEN (COALESCE(comments.score, (0)::bigint) + (((COALESCE(reads.score, (0)::bigint))::double precision * GREATEST((1)::double precision, (((article_pages.word_count)::double precision / (184)::double precision) / (5)::double precision))))::integer)
            ELSE (0)::bigint
        END AS hot_score,
        CASE
            WHEN ((comments.count > 0) OR (reads.count > 1)) THEN (COALESCE(comments.count, (0)::bigint) + (((COALESCE(reads.count, (0)::bigint))::double precision * GREATEST((1)::double precision, (((article_pages.word_count)::double precision / (184)::double precision) / (5)::double precision))))::integer)
            ELSE (0)::bigint
        END AS top_score
   FROM ((article_api.article_pages
     LEFT JOIN ( SELECT count(*) AS count,
            sum(
                CASE
                    WHEN (comment.age < '36:00:00'::interval) THEN 200
                    WHEN (comment.age < '72:00:00'::interval) THEN 150
                    WHEN (comment.age < '7 days'::interval) THEN 100
                    WHEN (comment.age < '14 days'::interval) THEN 50
                    WHEN (comment.age < '1 mon'::interval) THEN 5
                    ELSE 1
                END) AS score,
            comment.article_id
           FROM ( SELECT comment_1.article_id,
                    (core.utc_now() - comment_1.date_created) AS age
                   FROM core.comment comment_1) comment
          GROUP BY comment.article_id) comments ON ((comments.article_id = article_pages.article_id)))
     LEFT JOIN ( SELECT count(*) AS count,
            sum(
                CASE
                    WHEN (read.age < '36:00:00'::interval) THEN 175
                    WHEN (read.age < '72:00:00'::interval) THEN 125
                    WHEN (read.age < '7 days'::interval) THEN 75
                    WHEN (read.age < '14 days'::interval) THEN 25
                    WHEN (read.age < '1 mon'::interval) THEN 5
                    ELSE 1
                END) AS score,
            read.article_id
           FROM ( SELECT user_article_pages.article_id,
                    (core.utc_now() - user_article_pages.last_modified) AS age
                   FROM article_api.user_article_pages
                  WHERE (user_article_pages.date_completed IS NOT NULL)) read
          GROUP BY read.article_id) reads ON ((reads.article_id = article_pages.article_id)));


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
    rating.score
   FROM (core.rating
     LEFT JOIN core.rating more_recent_rating ON (((rating.article_id = more_recent_rating.article_id) AND (rating.user_account_id = more_recent_rating.user_account_id) AND (rating."timestamp" < more_recent_rating."timestamp"))))
  WHERE (more_recent_rating.id IS NULL);


--
-- Name: average_article_rating; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.average_article_rating AS
 SELECT user_article_rating.article_id,
    avg((user_article_rating.score)::integer) AS score
   FROM article_api.user_article_rating
  GROUP BY user_article_rating.article_id;


--
-- Name: community_read; Type: VIEW; Schema: article_api; Owner: -
--

CREATE VIEW article_api.community_read AS
 SELECT article.id,
    article.hot_score,
    article.top_score
   FROM core.article
  WHERE (((article.hot_score > 0) OR (article.top_score > 0)) AND ((article.aotd_timestamp IS NULL) OR (article.aotd_timestamp <> ( SELECT max(article_1.aotd_timestamp) AS max
           FROM core.article article_1))));


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

ALTER SEQUENCE core.user_page_id_seq OWNED BY core.user_page.id;


--
-- Name: current_streak; Type: MATERIALIZED VIEW; Schema: stats_api; Owner: -
--

CREATE MATERIALIZED VIEW stats_api.current_streak AS
 SELECT user_account.id,
    user_account.name,
    streak.streak
   FROM (core.user_account
     JOIN LATERAL stats_api.get_current_streak(user_account.id) streak(streak) ON ((user_account.time_zone_id IS NOT NULL)))
  WHERE (streak.streak > 0)
  WITH NO DATA;


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
-- Name: user_page id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_page ALTER COLUMN id SET DEFAULT nextval('core.user_page_id_seq'::regclass);


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
-- Name: user_page user_page_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_page
    ADD CONSTRAINT user_page_pkey PRIMARY KEY (id);


--
-- Name: article_aotd_timestamp_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_aotd_timestamp_idx ON core.article USING btree (aotd_timestamp DESC NULLS LAST);


--
-- Name: article_hot_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_hot_score_idx ON core.article USING btree (hot_score DESC);


--
-- Name: article_top_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_top_score_idx ON core.article USING btree (top_score DESC);


--
-- Name: comment_article_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX comment_article_id_idx ON core.comment USING btree (article_id);


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
-- Name: user_page_date_completed_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_page_date_completed_idx ON core.user_page USING btree (date_completed);


--
-- Name: user_page_page_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_page_page_id_idx ON core.user_page USING btree (page_id);


--
-- Name: user_page_user_account_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX user_page_user_account_id_idx ON core.user_page USING btree (user_account_id);


--
-- Name: current_streak_id_key; Type: INDEX; Schema: stats_api; Owner: -
--

CREATE UNIQUE INDEX current_streak_id_key ON stats_api.current_streak USING btree (id);


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
-- Name: user_page user_page_page_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_page
    ADD CONSTRAINT user_page_page_id_fkey FOREIGN KEY (page_id) REFERENCES core.page(id);


--
-- Name: user_page user_page_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_page
    ADD CONSTRAINT user_page_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: current_streak; Type: MATERIALIZED VIEW DATA; Schema: stats_api; Owner: -
--

REFRESH MATERIALIZED VIEW stats_api.current_streak;


--
-- PostgreSQL database dump complete
--

