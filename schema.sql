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
-- Name: community_reads; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA community_reads;


--
-- Name: core; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA core;


--
-- Name: notifications; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA notifications;


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
-- Name: article_flair; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.article_flair AS ENUM (
    'paywall'
);


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
	dates_posted timestamp without time zone[],
	hot_score integer,
	hot_velocity numeric,
	rating_count integer,
	first_poster text,
	flair core.article_flair
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
	dates_posted timestamp without time zone[],
	hot_score integer,
	hot_velocity numeric,
	rating_count integer,
	first_poster text,
	flair core.article_flair,
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
-- Name: notification_action; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_action AS ENUM (
    'open',
    'view',
    'reply'
);


--
-- Name: notification_channel; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_channel AS ENUM (
    'email',
    'extension',
    'push'
);


--
-- Name: notification_event_frequency; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_event_frequency AS ENUM (
    'never',
    'daily',
    'weekly'
);


--
-- Name: notification_event_type; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_event_type AS ENUM (
    'welcome',
    'email_confirmation',
    'email_confirmation_reminder',
    'password_reset',
    'company_update',
    'suggested_reading',
    'aotd',
    'aotd_digest',
    'reply',
    'reply_daily_digest',
    'reply_weekly_digest',
    'loopback',
    'loopback_daily_digest',
    'loopback_weekly_digest',
    'post',
    'post_daily_digest',
    'post_weekly_digest',
    'follower',
    'follower_daily_digest',
    'follower_weekly_digest'
);


--
-- Name: notification_push_unregistration_reason; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_push_unregistration_reason AS ENUM (
    'sign_out',
    'user_change',
    'token_change',
    'service_unregistered'
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
-- Name: alert_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

CREATE TYPE notifications.alert_dispatch AS (
	receipt_id bigint,
	via_email boolean,
	via_push boolean,
	user_account_id bigint,
	user_name text,
	email_address text,
	push_device_tokens text[],
	aotd_alert boolean,
	reply_alert_count integer,
	loopback_alert_count integer,
	post_alert_count integer,
	follower_alert_count integer
);


--
-- Name: comment_addendum; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.comment_addendum AS (
	date_created timestamp without time zone,
	text_content text
);


--
-- Name: comment_digest_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

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


--
-- Name: email_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

CREATE TYPE notifications.email_dispatch AS (
	receipt_id bigint,
	user_account_id bigint,
	user_name text,
	email_address text
);


--
-- Name: follower_digest_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

CREATE TYPE notifications.follower_digest_dispatch AS (
	receipt_id bigint,
	user_account_id bigint,
	user_name text,
	email_address text,
	follower_following_id bigint,
	follower_date_followed timestamp without time zone,
	follower_user_name text
);


--
-- Name: post_alert_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

CREATE TYPE notifications.post_alert_dispatch AS (
	receipt_id bigint,
	via_email boolean,
	via_push boolean,
	has_recipient_read_article boolean,
	user_account_id bigint,
	user_name text,
	email_address text,
	push_device_tokens text[],
	aotd_alert boolean,
	reply_alert_count integer,
	loopback_alert_count integer,
	post_alert_count integer,
	follower_alert_count integer
);


--
-- Name: post_digest_dispatch; Type: TYPE; Schema: notifications; Owner: -
--

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


--
-- Name: follower; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.follower AS (
	user_name text,
	is_followed boolean,
	has_alert boolean
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


SET default_with_oids = false;

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
-- Name: utc_now(); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.utc_now() RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
	SELECT local_now('UTC');
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
    LANGUAGE plpgsql STRICT
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
-- Name: get_aotd_history(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_aotd_history(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_aotds(bigint, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_aotds(user_account_id bigint, day_count integer) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT get_aotds.day_count
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

CREATE FUNCTION community_reads.set_aotd() RETURNS SETOF article_api.article
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
-- Name: get_time_zone_by_id(bigint); Type: FUNCTION; Schema: core; Owner: -
--

CREATE FUNCTION core.get_time_zone_by_id(id bigint) RETURNS SETOF core.time_zone
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
    FROM
    	core.time_zone
    WHERE
    	id = get_time_zone_by_id.id;
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
-- Name: notification_receipt; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_receipt (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_alert_cleared timestamp without time zone,
    via_email boolean DEFAULT false NOT NULL,
    via_extension boolean DEFAULT false NOT NULL,
    via_push boolean DEFAULT false NOT NULL
);


--
-- Name: clear_alert(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.clear_alert(receipt_id bigint) RETURNS SETOF core.notification_receipt
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    cleared_receipt core.notification_receipt;
BEGIN
    -- clear the alert only if it hasn't be cleared yet
    UPDATE
    	core.notification_receipt AS receipt
    SET
    	date_alert_cleared = core.utc_now()
    WHERE
    	receipt.id = clear_alert.receipt_id AND
    	receipt.date_alert_cleared IS NULL
    RETURNING
        * INTO locals.cleared_receipt;
    -- if the alert was cleared then decrement the cached counts on user_account
    IF locals.cleared_receipt IS NOT NULL THEN
		CASE (
			SELECT
				type
			FROM
				core.notification_event
			WHERE
				id = locals.cleared_receipt.event_id
		)
			WHEN 'aotd' THEN
				UPDATE
					core.user_account
				SET
					aotd_alert = false
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'reply' THEN
				UPDATE
					core.user_account
				SET
					reply_alert_count = greatest(reply_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'loopback' THEN
				UPDATE
					core.user_account
				SET
					loopback_alert_count = greatest(loopback_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'post' THEN
				UPDATE
					core.user_account
				SET
					post_alert_count = greatest(post_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'follower' THEN
				UPDATE
					core.user_account
				SET
					follower_alert_count = greatest(follower_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			ELSE
				-- suppress CASE_NOT_FOUND exception
		END CASE;
	END IF;
    -- return the cleared receipt
    RETURN NEXT locals.cleared_receipt;
END;
$$;


--
-- Name: clear_all_alerts(text, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.clear_all_alerts(type text, user_account_id bigint) RETURNS SETOF core.notification_receipt
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- reset cached alert counters
    CASE clear_all_alerts.type
        WHEN 'reply' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    reply_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'loopback' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    loopback_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'post' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    post_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'follower' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    follower_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
    END CASE;
    -- clear all uncleared alerts of the specified type
    RETURN QUERY
    UPDATE
    	core.notification_receipt
    SET
    	date_alert_cleared = core.utc_now()
    FROM
    	core.notification_event
    WHERE
    	notification_receipt.event_id = notification_event.id AND
        notification_event.type = clear_all_alerts.type::core.notification_event_type AND
        notification_receipt.user_account_id = clear_all_alerts.user_account_id AND
    	notification_receipt.date_alert_cleared IS NULL
    RETURNING
        notification_receipt.*;
END;
$$;


--
-- Name: clear_aotd_alert(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.clear_aotd_alert(user_account_id bigint) RETURNS SETOF core.notification_receipt
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- set the cached user_account alert flag to false
	UPDATE
	    core.user_account
    SET
        aotd_alert = false
    WHERE
    	id = clear_aotd_alert.user_account_id;
    -- clear the latest aotd alert only if it hasn't been cleared yet
	RETURN QUERY
    UPDATE
        core.notification_receipt
    SET
        date_alert_cleared = core.utc_now()
    WHERE
    	id = (
    	    SELECT
    	    	CASE WHEN receipt.date_alert_cleared IS NULL
    	    		THEN receipt.id
    	    		ELSE NULL
    	    	END
    	    FROM
    	    	core.notification_receipt AS receipt
    	    	JOIN core.notification_event ON
    	    		notification_event.id = receipt.event_id
    	    WHERE
    	    	notification_event.type = 'aotd' AND
    	        receipt.user_account_id = clear_aotd_alert.user_account_id
    	    ORDER BY
    	    	notification_event.date_created DESC
    	    LIMIT
    	    	1
		)
    RETURNING *;
END;
$$;


--
-- Name: create_aotd_digest_notifications(); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_aotd_digest_notifications() RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.aotd_digest_via_email = 'weekly'
	),
    aotd_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	'aotd_digest'
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
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
			(SELECT id FROM aotd_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	),
    aotd_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				article_id
			)
		SELECT
			(SELECT id FROM aotd_event),
			article.id
		FROM
			core.article
		WHERE
			EXISTS (SELECT id FROM aotd_event)
        ORDER BY
        	article.aotd_timestamp DESC NULLS LAST
        LIMIT 7
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;


--
-- Name: create_aotd_notifications(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_aotd_notifications(article_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
	-- create the event
	INSERT INTO
		core.notification_event (
			type
		)
	VALUES
		(
			'aotd'
		)
	RETURNING
		id INTO locals.event_id;
	-- create the data
	INSERT INTO
		core.notification_data (
			event_id,
			article_id
		)
	VALUES
		(
			locals.event_id,
			create_aotd_notifications.article_id
		);
	-- set the alert for all users
	UPDATE
		core.user_account
	SET
		aotd_alert = true
	WHERE
		aotd_alert = false;
	-- create receipts and return the dispatches
	RETURN QUERY
	WITH receipt AS (
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
				locals.event_id,
				preference.user_account_id,
				preference.aotd_via_email,
				preference.aotd_via_extension,
				preference.aotd_via_push
			FROM
				notifications.current_preference AS preference
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_push
	)
	SELECT
		receipt.id,
	    receipt.via_email,
	    receipt.via_push,
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
		LEFT JOIN notifications.registered_push_device AS device
			ON device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
	    receipt.via_email,
	    receipt.via_push,
	    user_account.id;
END;
$$;


--
-- Name: create_company_update_notifications(bigint, text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_company_update_notifications(author_id bigint, subject text, body text) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.company_update_via_email
	),
    update_event AS (
		INSERT INTO
			core.notification_event (
				type,
			    bulk_email_author_id,
			    bulk_email_subject,
			    bulk_email_body
			)
		SELECT
        	'company_update',
		    create_company_update_notifications.author_id,
		    create_company_update_notifications.subject,
		    create_company_update_notifications.body
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
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
			(SELECT id FROM update_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;


--
-- Name: create_email_notification(text, text, text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_email_notification(notification_type text, mail text, bounce text, complaint text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO email_notification
        (notification_type, mail, bounce, complaint)
    VALUES
		(notification_type, mail::json, bounce::json, complaint::json);
$$;


--
-- Name: create_follower_digest_notifications(text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_follower_digest_notifications(frequency text) RETURNS SETOF notifications.follower_digest_dispatch
    LANGUAGE sql
    AS $$
    WITH follower AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
    	    active_following.id AS following_id,
			active_following.date_followed AS date_followed,
    	    follower.name AS user_name
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON (
					recipient.id = preference.user_account_id AND
					preference.follower_digest_via_email = create_follower_digest_notifications.frequency::core.notification_event_frequency
				)
			JOIN core.following AS active_following
    			ON (
					active_following.followee_user_account_id = recipient.id AND
    			    active_following.date_followed >= (
						CASE create_follower_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
					) AND
					active_following.date_unfollowed IS NULL
				)
    		JOIN core.user_account AS follower
    			ON follower.id = active_following.follower_user_account_id
    		LEFT JOIN core.following AS inactive_following
    			ON (
    			    inactive_following.followee_user_account_id = active_following.followee_user_account_id AND
    			    inactive_following.follower_user_account_id = active_following.follower_user_account_id AND
    			    inactive_following.id != active_following.id
    			)
		WHERE
			 inactive_following.id IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	follower
	),
    follower_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_follower_digest_notifications.frequency
				WHEN 'daily' THEN 'follower_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'follower_weekly_digest'::core.notification_event_type
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
				follower_event
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
    follower_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		SELECT
			recipient_event.event_id,
			follower.following_id
		FROM
			recipient_event
        	JOIN follower
        		ON follower.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        follower.recipient_id,
        follower.recipient_name,
        follower.recipient_email,
        follower.following_id,
		follower.date_followed,
		follower.user_name
    FROM
    	receipt
        JOIN follower
    		ON follower.recipient_id = receipt.user_account_id;
$$;


--
-- Name: create_follower_notification(bigint, bigint, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_follower_notification(following_id bigint, follower_id bigint, followee_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
    -- only notify on the first following
    IF (
		(
		    SELECT
		    	count(*)
		    FROM
		    	following
		    WHERE
		        following.follower_user_account_id = create_follower_notification.follower_id AND
		    	following.followee_user_account_id = create_follower_notification.followee_id
		) = 1
	) THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'follower'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		VALUES
			(
				locals.event_id,
				create_follower_notification.following_id
			);
		-- increment the followee's alert count
		UPDATE
			user_account
		SET
			follower_alert_count = follower_alert_count + 1
		WHERE
			id = create_follower_notification.followee_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
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
					locals.event_id,
					create_follower_notification.followee_id,
					preference.follower_via_email,
					preference.follower_via_extension,
					preference.follower_via_push
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = create_follower_notification.followee_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
			receipt.via_email,
			receipt.via_push,
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
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
        GROUP BY
        	receipt.id,
            receipt.via_email,
            receipt.via_push,
            user_account.id;
	END IF;
END;
$$;


--
-- Name: notification_interaction; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_interaction (
    id bigint NOT NULL,
    receipt_id bigint NOT NULL,
    channel core.notification_channel NOT NULL,
    action core.notification_action NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    url text,
    reply_id bigint,
    CONSTRAINT notification_interaction_check CHECK (((action = 'open'::core.notification_action) OR ((action = 'view'::core.notification_action) AND (url IS NOT NULL)) OR ((action = 'reply'::core.notification_action) AND (reply_id IS NOT NULL))))
);


--
-- Name: create_interaction(bigint, text, text, text, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_interaction(receipt_id bigint, channel text, action text, url text, reply_id bigint) RETURNS SETOF core.notification_interaction
    LANGUAGE sql
    AS $$
	INSERT INTO
    	core.notification_interaction (
			receipt_id,
    	    channel,
    	    action,
    	    url,
    	    reply_id
		)
	VALUES
    	(
			create_interaction.receipt_id,
			create_interaction.channel::core.notification_channel,
			create_interaction.action::core.notification_action,
			create_interaction.url,
			create_interaction.reply_id
		)
	RETURNING *;
$$;


--
-- Name: create_loopback_digest_notifications(text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_loopback_digest_notifications(frequency text) RETURNS SETOF notifications.comment_digest_dispatch
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


--
-- Name: create_loopback_notifications(bigint, bigint, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_loopback_notifications(article_id bigint, comment_id bigint, comment_author_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE sql
    AS $$
    WITH recipient AS (
        SELECT
			user_article.user_account_id,
		    preference.loopback_via_email,
		    preference.loopback_via_extension,
		    preference.loopback_via_push
		FROM
			core.user_article
			JOIN notifications.current_preference AS preference ON
				preference.user_account_id = user_article.user_account_id
        	LEFT JOIN social.active_following
        		ON (
        		    active_following.follower_user_account_id = user_article.user_account_id AND
        		    active_following.followee_user_account_id = create_loopback_notifications.comment_author_id
        		)
	    WHERE
	    	user_article.article_id = create_loopback_notifications.article_id AND
	        user_article.user_account_id != create_loopback_notifications.comment_author_id AND
	        user_article.date_completed IS NOT NULL AND
	        active_following.id IS NULL
	),
    loopback_event AS (
        INSERT INTO
			core.notification_event (type)
		SELECT
            'loopback'
        WHERE
            EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
    loopback_data AS (
        INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
        	id,
		    create_loopback_notifications.comment_id
        FROM
        	loopback_event
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
				(SELECT id FROM loopback_event),
				recipient.user_account_id,
				recipient.loopback_via_email,
				recipient.loopback_via_extension,
				recipient.loopback_via_push
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
    updated_user AS (
        UPDATE
			core.user_account
		SET
			loopback_alert_count = loopback_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
        RETURNING
        	user_account.id,
            user_account.name,
            user_account.email,
            user_account.aotd_alert,
            user_account.reply_alert_count,
            user_account.loopback_alert_count,
            user_account.post_alert_count,
            user_account.follower_alert_count
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		updated_user.id,
		updated_user.name,
		updated_user.email,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count
	FROM
		receipt
		JOIN updated_user ON
			updated_user.id = receipt.user_account_id
		LEFT JOIN notifications.registered_push_device AS device ON
			device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		updated_user.id,
	    updated_user.name,
		updated_user.email,
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count;
$$;


--
-- Name: create_post_digest_notifications(text); Type: FUNCTION; Schema: notifications; Owner: -
--

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


--
-- Name: create_post_notifications(bigint, bigint, bigint, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_post_notifications(article_id bigint, poster_id bigint, comment_id bigint, silent_post_id bigint) RETURNS SETOF notifications.post_alert_dispatch
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
    updated_user AS (
        UPDATE
			core.user_account
		SET
			post_alert_count = post_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
        RETURNING
        	user_account.id,
            user_account.name,
            user_account.email,
            user_account.aotd_alert,
            user_account.reply_alert_count,
            user_account.loopback_alert_count,
            user_account.post_alert_count,
            user_account.follower_alert_count
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
	    user_article.date_completed IS NOT NULL,
		updated_user.id,
		updated_user.name::text,
		updated_user.email::text,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count
	FROM
		receipt
		JOIN updated_user
			ON updated_user.id = receipt.user_account_id
		LEFT JOIN core.user_article
		    ON (
		        user_article.user_account_id = updated_user.id AND
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
		updated_user.id,
	    updated_user.name,
		updated_user.email,
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count,
	    user_article.date_completed;
$$;


--
-- Name: notification_push_auth_denial; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_push_auth_denial (
    id bigint NOT NULL,
    date_denied timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    user_account_id bigint NOT NULL,
    installation_id text,
    device_name text
);


--
-- Name: create_push_auth_denial(bigint, text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_push_auth_denial(user_account_id bigint, installation_id text, device_name text) RETURNS SETOF core.notification_push_auth_denial
    LANGUAGE sql
    AS $$
	INSERT INTO
    	core.notification_push_auth_denial (
    	    user_account_id,
    	    installation_id,
    	    device_name
    	)
    VALUES (
        create_push_auth_denial.user_account_id,
        create_push_auth_denial.installation_id,
        create_push_auth_denial.device_name
	)
	RETURNING *;
$$;


--
-- Name: create_reply_digest_notifications(text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_reply_digest_notifications(frequency text) RETURNS SETOF notifications.comment_digest_dispatch
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


--
-- Name: create_reply_notification(bigint, bigint, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_reply_notification(reply_id bigint, reply_author_id bigint, parent_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    parent_author_id bigint;
    event_id bigint;
BEGIN
    -- lookup the parent author
    SELECT
    	user_account_id
    INTO
        locals.parent_author_id
    FROM
    	core.comment
    WHERE
    	id = parent_id;
    -- check for a self-reply
    IF create_reply_notification.reply_author_id != locals.parent_author_id THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'reply'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		VALUES
			(
				locals.event_id,
				create_reply_notification.reply_id
			);
		-- increment the parent's alert count
		UPDATE
			user_account
		SET
			reply_alert_count = reply_alert_count + 1
		WHERE
			id = locals.parent_author_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
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
					locals.event_id,
					locals.parent_author_id,
					preference.reply_via_email,
					preference.reply_via_extension,
					preference.reply_via_push
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = locals.parent_author_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
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
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
		GROUP BY
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
		    user_account.id;
	END IF;
END;
$$;


--
-- Name: create_transactional_notification(bigint, text, bigint, bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_transactional_notification(user_account_id bigint, event_type text, email_confirmation_id bigint, password_reset_request_id bigint) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH transactional_event AS (
		INSERT INTO
			core.notification_event (type)
		VALUES
		    (create_transactional_notification.event_type::core.notification_event_type)
        RETURNING
        	id
	),
    transactional_data AS (
      	INSERT INTO
        	core.notification_data (
        		event_id,
        	    email_confirmation_id,
        	    password_reset_request_id
			)
    	VALUES (
    	    (SELECT id FROM transactional_event),
			create_transactional_notification.email_confirmation_id,
    	    create_transactional_notification.password_reset_request_id
		)
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
			(SELECT id FROM transactional_event),
		    create_transactional_notification.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        RETURNING
        	id
	)
    SELECT
        (SELECT id FROM receipt),
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	core.user_account
    WHERE
    	id = create_transactional_notification.user_account_id;
$$;


--
-- Name: get_blocked_email_addresses(); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_blocked_email_addresses() RETURNS SETOF text
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
-- Name: get_bulk_mailings(); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_bulk_mailings() RETURNS TABLE(id bigint, date_sent timestamp without time zone, subject text, body text, type core.notification_event_type, user_account text, recipient_count bigint)
    LANGUAGE sql
    AS $$
	SELECT
		event.id,
		event.date_created,
		event.bulk_email_subject,
		event.bulk_email_body,
		event.type,
		user_account.name AS user_account,
		count(*) AS recipient_count
	FROM
		notification_event AS event
		JOIN user_account ON user_account.id = event.bulk_email_author_id
		JOIN notification_receipt ON notification_receipt.event_id = event.id
	GROUP BY
		event.id, user_account.id;
$$;


--
-- Name: notification; Type: VIEW; Schema: notifications; Owner: -
--

CREATE VIEW notifications.notification AS
SELECT
    NULL::bigint AS event_id,
    NULL::timestamp without time zone AS date_created,
    NULL::core.notification_event_type AS event_type,
    NULL::bigint[] AS article_ids,
    NULL::bigint[] AS comment_ids,
    NULL::bigint[] AS silent_post_ids,
    NULL::bigint[] AS following_ids,
    NULL::bigint AS receipt_id,
    NULL::bigint AS user_account_id,
    NULL::timestamp without time zone AS date_alert_cleared,
    NULL::boolean AS via_email,
    NULL::boolean AS via_extension,
    NULL::boolean AS via_push;


--
-- Name: get_extension_notifications(bigint, timestamp without time zone, bigint[]); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_extension_notifications(user_account_id bigint, since_date timestamp without time zone, excluded_receipt_ids bigint[]) RETURNS SETOF notifications.notification
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	*
    FROM
    	notifications.notification
    WHERE
    	notification.user_account_id = get_extension_notifications.user_account_id AND
        notification.via_extension AND
        notification.date_created >= get_extension_notifications.since_date AND
        notification.date_alert_cleared IS NULL AND
    	NOT notification.receipt_id = ANY (get_extension_notifications.excluded_receipt_ids);
$$;


--
-- Name: get_notification(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_notification(receipt_id bigint) RETURNS SETOF notifications.notification
    LANGUAGE sql STABLE
    AS $$
    SELECT
		*
    FROM
    	notifications.notification
	WHERE
		notification.receipt_id = get_notification.receipt_id;
$$;


--
-- Name: get_notifications(bigint[]); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_notifications(receipt_ids bigint[]) RETURNS SETOF notifications.notification
    LANGUAGE sql STABLE
    AS $$
    SELECT
		*
    FROM
    	notifications.notification
	WHERE
		notification.receipt_id = ANY (get_notifications.receipt_ids);
$$;


--
-- Name: notification_preference; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_preference (
    id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    last_modified timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    company_update_via_email boolean DEFAULT true NOT NULL,
    aotd_via_email boolean DEFAULT true NOT NULL,
    aotd_via_extension boolean DEFAULT true NOT NULL,
    aotd_via_push boolean DEFAULT true NOT NULL,
    aotd_digest_via_email core.notification_event_frequency DEFAULT 'never'::core.notification_event_frequency NOT NULL,
    reply_via_email boolean DEFAULT true NOT NULL,
    reply_via_extension boolean DEFAULT true NOT NULL,
    reply_via_push boolean DEFAULT true NOT NULL,
    reply_digest_via_email core.notification_event_frequency DEFAULT 'never'::core.notification_event_frequency NOT NULL,
    loopback_via_email boolean DEFAULT true NOT NULL,
    loopback_via_extension boolean DEFAULT true NOT NULL,
    loopback_via_push boolean DEFAULT true NOT NULL,
    loopback_digest_via_email core.notification_event_frequency DEFAULT 'never'::core.notification_event_frequency NOT NULL,
    post_via_email boolean DEFAULT true NOT NULL,
    post_via_extension boolean DEFAULT true NOT NULL,
    post_via_push boolean DEFAULT true NOT NULL,
    post_digest_via_email core.notification_event_frequency DEFAULT 'never'::core.notification_event_frequency NOT NULL,
    follower_via_email boolean DEFAULT true NOT NULL,
    follower_via_extension boolean DEFAULT true NOT NULL,
    follower_via_push boolean DEFAULT true NOT NULL,
    follower_digest_via_email core.notification_event_frequency DEFAULT 'never'::core.notification_event_frequency NOT NULL,
    CONSTRAINT notification_preference_aotd_digest_via_email_check CHECK ((aotd_digest_via_email <> 'daily'::core.notification_event_frequency))
);


--
-- Name: get_preference(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_preference(user_account_id bigint) RETURNS SETOF core.notification_preference
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
    FROM
    	notifications.current_preference
    WHERE
    	user_account_id = get_preference.user_account_id;
$$;


--
-- Name: notification_push_device; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_push_device (
    id bigint NOT NULL,
    date_registered timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_unregistered timestamp without time zone,
    unregistration_reason core.notification_push_unregistration_reason,
    user_account_id bigint NOT NULL,
    installation_id text NOT NULL,
    name text,
    token text NOT NULL
);


--
-- Name: get_registered_push_devices(bigint); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_registered_push_devices(user_account_id bigint) RETURNS SETOF core.notification_push_device
    LANGUAGE sql STABLE
    AS $$
	SELECT
    	*
    FROM
    	notifications.registered_push_device
    WHERE
    	user_account_id = get_registered_push_devices.user_account_id;
$$;


--
-- Name: register_push_device(bigint, text, text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.register_push_device(user_account_id bigint, installation_id text, name text, token text) RETURNS SETOF core.notification_push_device
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    existing_device core.notification_push_device;
BEGIN
    -- check for existing registered device with matching installation_id
	SELECT
    	*
	INTO
		locals.existing_device
    FROM
    	notifications.registered_push_device AS device
    WHERE
        device.installation_id = register_push_device.installation_id;
    -- create a new registration if needed
    IF (
    	locals.existing_device IS NULL OR
    	locals.existing_device.user_account_id != register_push_device.user_account_id OR
    	locals.existing_device.token != register_push_device.token
    ) THEN
        -- unregister the existing device if the user or token has changed
        IF locals.existing_device IS NOT NULL THEN
			UPDATE
			    core.notification_push_device
            SET
                date_unregistered = core.utc_now(),
                unregistration_reason = (
                    CASE WHEN locals.existing_device.user_account_id != register_push_device.user_account_id
                        THEN 'user_change'
                        ELSE 'token_change'
                    END
				)
            WHERE
            	id = locals.existing_device.id;
		END IF;
        -- create the registration and return the result
        RETURN QUERY
		INSERT INTO
		    core.notification_push_device (
		        user_account_id,
		        installation_id,
		        name,
				token
		    )
		VALUES (
		    register_push_device.user_account_id,
			register_push_device.installation_id,
			register_push_device.name,
			register_push_device.token
		)
		RETURNING *;
	END IF;
END;
$$;


--
-- Name: set_preference(bigint, boolean, boolean, boolean, boolean, text, boolean, boolean, boolean, text, boolean, boolean, boolean, text, boolean, boolean, boolean, text, boolean, boolean, boolean, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.set_preference(user_account_id bigint, company_update_via_email boolean, aotd_via_email boolean, aotd_via_extension boolean, aotd_via_push boolean, aotd_digest_via_email text, reply_via_email boolean, reply_via_extension boolean, reply_via_push boolean, reply_digest_via_email text, loopback_via_email boolean, loopback_via_extension boolean, loopback_via_push boolean, loopback_digest_via_email text, post_via_email boolean, post_via_extension boolean, post_via_push boolean, post_digest_via_email text, follower_via_email boolean, follower_via_extension boolean, follower_via_push boolean, follower_digest_via_email text) RETURNS SETOF core.notification_preference
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    existing_preference_id bigint;
BEGIN
    -- casting from text to frequency because of poor mapping in api layer
    -- check for an existing record
	SELECT
		preference.id
    INTO
    	locals.existing_preference_id
    FROM
    	core.notification_preference AS preference
    WHERE
    	preference.user_account_id = set_preference.user_account_id AND
    	preference.last_modified >= core.utc_now() - '1 hour'::interval
    ORDER BY
    	preference.last_modified DESC
    LIMIT 1;
    -- update the existing record or create a new one
    IF existing_preference_id IS NOT NULL THEN
        RETURN QUERY
		UPDATE
		    core.notification_preference
        SET
            last_modified = core.utc_now(),
            company_update_via_email = set_preference.company_update_via_email,
			aotd_via_email = set_preference.aotd_via_email,
			aotd_via_extension = set_preference.aotd_via_extension,
			aotd_via_push = set_preference.aotd_via_push,
            aotd_digest_via_email = set_preference.aotd_digest_via_email::core.notification_event_frequency,
			reply_via_email = set_preference.reply_via_email,
			reply_via_extension = set_preference.reply_via_extension,
			reply_via_push = set_preference.reply_via_push,
			reply_digest_via_email = set_preference.reply_digest_via_email::core.notification_event_frequency,
			loopback_via_email = set_preference.loopback_via_email,
			loopback_via_extension = set_preference.loopback_via_extension,
			loopback_via_push = set_preference.loopback_via_push,
			loopback_digest_via_email = set_preference.loopback_digest_via_email::core.notification_event_frequency,
			post_via_email = set_preference.post_via_email,
			post_via_extension = set_preference.post_via_extension,
			post_via_push = set_preference.post_via_push,
			post_digest_via_email = set_preference.post_digest_via_email::core.notification_event_frequency,
			follower_via_email = set_preference.follower_via_email,
			follower_via_extension = set_preference.follower_via_extension,
			follower_via_push = set_preference.follower_via_push,
			follower_digest_via_email = set_preference.follower_digest_via_email::core.notification_event_frequency
        WHERE
        	id = locals.existing_preference_id
        RETURNING *;
	ELSE
	    RETURN QUERY
    	INSERT INTO
    	    core.notification_preference (
    	        user_account_id,
    	        company_update_via_email,
				aotd_via_email,
				aotd_via_extension,
				aotd_via_push,
    	        aotd_digest_via_email,
				reply_via_email,
				reply_via_extension,
				reply_via_push,
				reply_digest_via_email,
				loopback_via_email,
				loopback_via_extension,
				loopback_via_push,
				loopback_digest_via_email,
				post_via_email,
				post_via_extension,
				post_via_push,
				post_digest_via_email,
				follower_via_email,
				follower_via_extension,
				follower_via_push,
				follower_digest_via_email
			)
		VALUES (
		    set_preference.user_account_id,
			set_preference.company_update_via_email,
			set_preference.aotd_via_email,
			set_preference.aotd_via_extension,
			set_preference.aotd_via_push,
		    set_preference.aotd_digest_via_email::core.notification_event_frequency,
			set_preference.reply_via_email,
			set_preference.reply_via_extension,
			set_preference.reply_via_push,
			set_preference.reply_digest_via_email::core.notification_event_frequency,
			set_preference.loopback_via_email,
			set_preference.loopback_via_extension,
			set_preference.loopback_via_push,
			set_preference.loopback_digest_via_email::core.notification_event_frequency,
			set_preference.post_via_email,
			set_preference.post_via_extension,
			set_preference.post_via_push,
			set_preference.post_digest_via_email::core.notification_event_frequency,
			set_preference.follower_via_email,
			set_preference.follower_via_extension,
			set_preference.follower_via_push,
			set_preference.follower_digest_via_email::core.notification_event_frequency
		)
		RETURNING *;
    END IF;
END;
$$;


--
-- Name: unregister_push_device_by_installation_id(text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.unregister_push_device_by_installation_id(installation_id text, reason text) RETURNS SETOF core.notification_push_device
    LANGUAGE sql
    AS $$
	UPDATE
		core.notification_push_device AS device
    SET
    	date_unregistered = core.utc_now(),
        unregistration_reason = unregister_push_device_by_installation_id.reason::core.notification_push_unregistration_reason
    WHERE
    	device.installation_id = unregister_push_device_by_installation_id.installation_id AND
        device.date_unregistered IS NULL
    RETURNING *;
$$;


--
-- Name: unregister_push_device_by_token(text, text); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.unregister_push_device_by_token(token text, reason text) RETURNS SETOF core.notification_push_device
    LANGUAGE sql
    AS $$
	UPDATE
		core.notification_push_device AS device
    SET
    	date_unregistered = core.utc_now(),
        unregistration_reason = unregister_push_device_by_token.reason::core.notification_push_unregistration_reason
    WHERE
    	device.token = unregister_push_device_by_token.token AND
        device.date_unregistered IS NULL
    RETURNING *;
$$;


--
-- Name: comment; Type: VIEW; Schema: social; Owner: -
--

CREATE VIEW social.comment AS
SELECT
    NULL::bigint AS id,
    NULL::timestamp without time zone AS date_created,
    NULL::text AS text,
    NULL::bigint AS article_id,
    NULL::character varying(512) AS article_title,
    NULL::character varying(256) AS article_slug,
    NULL::bigint AS user_account_id,
    NULL::character varying(30) AS user_account,
    NULL::bigint AS parent_comment_id,
    NULL::social.comment_addendum[] AS addenda,
    NULL::timestamp without time zone AS date_deleted;


--
-- Name: create_comment(text, bigint, bigint, bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_comment(text text, article_id bigint, parent_comment_id bigint, user_account_id bigint, analytics text) RETURNS SETOF social.comment
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


--
-- Name: create_comment_addendum(bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_comment_addendum(comment_id bigint, text_content text) RETURNS SETOF social.comment
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
-- Name: create_following(bigint, text, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_following(follower_user_id bigint, followee_user_name text, analytics text) RETURNS SETOF core.following
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
		)
	RETURNING *;
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


--
-- Name: delete_comment(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.delete_comment(comment_id bigint) RETURNS SETOF social.comment
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


--
-- Name: get_comment(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_comment(comment_id bigint) RETURNS SETOF social.comment
    LANGUAGE sql
    AS $$
	SELECT
	    *
	FROM
	    social.comment
	WHERE
	    id = get_comment.comment_id;
$$;


--
-- Name: get_comments(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_comments(article_id bigint) RETURNS SETOF social.comment
    LANGUAGE sql
    AS $$
	SELECT
	    *
	FROM
	    social.comment
	WHERE
	    article_id = get_comments.article_id;
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
    	active_following.follower_user_account_id = get_followees.user_account_id
    ORDER BY
    	active_following.date_followed DESC;
$$;


--
-- Name: get_followers(bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_followers(viewer_user_id bigint, subject_user_name text) RETURNS SETOF social.follower
    LANGUAGE sql STABLE
    AS $$
	SELECT
		follower.name AS user_name,
	   	viewer_following.id IS NOT NULL AS is_followed,
		alert.following_id IS NOT NULL AS has_alert
	FROM
		social.active_following AS subject_following
		JOIN core.user_account AS follower ON follower.id = subject_following.follower_user_account_id
		LEFT JOIN social.active_following AS viewer_following ON (
			viewer_following.follower_user_account_id = get_followers.viewer_user_id AND
			viewer_following.followee_user_account_id = follower.id
		)
		LEFT JOIN (
			SELECT
				notification_data.following_id
		 	FROM
		    	notification_event
		    	JOIN notification_data
		    	    ON (
						notification_event.type = 'follower' AND
						notification_data.event_id = notification_event.id
					)
		    	JOIN notification_receipt AS receipt
		    		ON (
		    		    receipt.event_id = notification_event.id AND
		    		    receipt.user_account_id = get_followers.viewer_user_id AND
						receipt.date_alert_cleared IS NULL
					)
		) AS alert
			ON alert.following_id = subject_following.id
    WHERE
        subject_following.followee_user_account_id = user_account_api.get_user_account_id_by_name(get_followers.subject_user_name)
    ORDER BY
    	subject_following.date_followed DESC;
$$;


--
-- Name: get_following(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_following(following_id bigint) RETURNS SETOF core.following
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	*
    FROM
    	core.following
    WHERE
    	id = get_following.following_id;
$$;


--
-- Name: get_posts_from_followees(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_followees(user_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF social.article_post_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_posts_from_inbox(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_inbox(user_id bigint, page_number integer, page_size integer) RETURNS SETOF social.article_post_page_result
    LANGUAGE sql STABLE
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
-- Name: get_silent_post(bigint); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_silent_post(id bigint) RETURNS SETOF core.silent_post
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
    FROM
    	core.silent_post
	WHERE
    	id = get_silent_post.id;
$$;


--
-- Name: revise_comment(bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.revise_comment(comment_id bigint, revised_text text) RETURNS SETOF social.comment
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
<<locals>>
DECLARE
    user_account_id bigint;
	rows_updated int;
BEGIN
	UPDATE
	    email_confirmation
	SET
		date_confirmed = utc_now()
	WHERE
		email_confirmation.id = confirm_email_address.email_confirmation_id AND
	    email_confirmation.date_confirmed IS NULL
	RETURNING
		email_confirmation.user_account_id INTO locals.user_account_id;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	IF rows_updated = 1 THEN
		UPDATE
		    user_account
	    SET
	        is_email_confirmed = true
	    WHERE
	    	user_account.id = locals.user_account_id;
	END IF;
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
-- Name: create_email_confirmation(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_email_confirmation(user_account_id bigint) RETURNS SETOF core.email_confirmation
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE
		user_account
	SET
		is_email_confirmed = false
	WHERE
		id = create_email_confirmation.user_account_id;
    RETURN QUERY
	INSERT INTO
	    email_confirmation (
			user_account_id,
	        email_address
	    )
	VALUES (
		create_email_confirmation.user_account_id,
		(
		    SELECT
		    	email
			FROM
				user_account
		    WHERE
		    	id = create_email_confirmation.user_account_id
		)
	)
	RETURNING *;
END;
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
-- Name: user_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_account (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    email character varying(256) NOT NULL,
    password_hash bytea NOT NULL,
    password_salt bytea NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    role core.user_account_role DEFAULT 'regular'::core.user_account_role NOT NULL,
    time_zone_id bigint,
    creation_analytics jsonb,
    is_email_confirmed boolean DEFAULT false NOT NULL,
    aotd_alert boolean DEFAULT false NOT NULL,
    reply_alert_count integer DEFAULT 0 NOT NULL,
    loopback_alert_count integer DEFAULT 0 NOT NULL,
    post_alert_count integer DEFAULT 0 NOT NULL,
    follower_alert_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT user_account_email_valid CHECK (((email)::text ~~ '%@%'::text)),
    CONSTRAINT user_account_name_valid CHECK (((name)::text ~ similar_escape('[A-Za-z0-9\-_]+'::text, NULL::text)))
);


--
-- Name: create_user_account(text, text, bytea, bytea, bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_user_account(name text, email text, password_hash bytea, password_salt bytea, time_zone_id bigint, analytics text) RETURNS SETOF core.user_account
    LANGUAGE sql
    AS $$
    WITH new_user AS (
		INSERT INTO
			core.user_account (
				name,
				email,
				password_hash,
				password_salt,
				time_zone_id,
				creation_analytics
			)
		VALUES
			(
				trim(create_user_account.name),
				trim(create_user_account.email),
				create_user_account.password_hash,
				create_user_account.password_salt,
				create_user_account.time_zone_id,
				create_user_account.analytics::json
			)
		RETURNING *
    ),
	initial_preference AS (
		INSERT INTO
	    	core.notification_preference (user_account_id)
	    (SELECT id FROM new_user)
	)
    SELECT * FROM new_user;
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

CREATE FUNCTION user_account_api.get_user_account_by_email(email text) RETURNS SETOF core.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
	FROM
		core.user_account
	WHERE
		lower(email) = lower(get_user_account_by_email.email);
$$;


--
-- Name: get_user_account_by_id(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_by_id(user_account_id bigint) RETURNS SETOF core.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
	FROM
		core.user_account
	WHERE
	    id = get_user_account_by_id.user_account_id;
$$;


--
-- Name: get_user_account_by_name(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_account_by_name(user_name text) RETURNS SETOF core.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
	    *
	FROM
		core.user_account
	WHERE
		lower(name) = lower(get_user_account_by_name.user_name);
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
-- Name: get_user_accounts(); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_user_accounts() RETURNS SETOF core.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
	    *
	FROM
	    core.user_account;
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
-- Name: update_time_zone(bigint, bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.update_time_zone(user_account_id bigint, time_zone_id bigint) RETURNS SETOF core.user_account
    LANGUAGE sql
    AS $$
	UPDATE
		core.user_account
	SET
		time_zone_id = update_time_zone.time_zone_id
	WHERE
		id = update_time_zone.user_account_id
    RETURNING *;
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
    silent_post_count integer DEFAULT 0 NOT NULL,
    rating_count integer DEFAULT 0 NOT NULL,
    first_poster_id bigint,
    flair core.article_flair
);


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
-- Name: comment; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.comment (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    text text NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    parent_comment_id bigint,
    analytics jsonb,
    date_deleted timestamp without time zone
);


--
-- Name: comment_addendum; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.comment_addendum (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    comment_id bigint NOT NULL,
    text_content text
);


--
-- Name: comment_addendum_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.comment_addendum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_addendum_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.comment_addendum_id_seq OWNED BY core.comment_addendum.id;


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
-- Name: comment_revision; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.comment_revision (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    comment_id bigint NOT NULL,
    original_text_content text
);


--
-- Name: comment_revision_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.comment_revision_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment_revision_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.comment_revision_id_seq OWNED BY core.comment_revision.id;


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
-- Name: notification_data; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_data (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    article_id bigint,
    comment_id bigint,
    silent_post_id bigint,
    following_id bigint,
    email_confirmation_id bigint,
    password_reset_request_id bigint,
    CONSTRAINT notification_data_check CHECK (((article_id IS NOT NULL) OR (comment_id IS NOT NULL) OR (silent_post_id IS NOT NULL) OR (following_id IS NOT NULL) OR (email_confirmation_id IS NOT NULL) OR (password_reset_request_id IS NOT NULL)))
);


--
-- Name: notification_data_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_data_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_data_id_seq OWNED BY core.notification_data.id;


--
-- Name: notification_event; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.notification_event (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    type core.notification_event_type NOT NULL,
    bulk_email_author_id bigint,
    bulk_email_subject text,
    bulk_email_body text
);


--
-- Name: notification_event_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_event_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_event_id_seq OWNED BY core.notification_event.id;


--
-- Name: notification_interaction_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_interaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_interaction_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_interaction_id_seq OWNED BY core.notification_interaction.id;


--
-- Name: notification_preference_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_preference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_preference_id_seq OWNED BY core.notification_preference.id;


--
-- Name: notification_push_auth_denial_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_push_auth_denial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_push_auth_denial_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_push_auth_denial_id_seq OWNED BY core.notification_push_auth_denial.id;


--
-- Name: notification_push_device_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_push_device_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_push_device_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_push_device_id_seq OWNED BY core.notification_push_device.id;


--
-- Name: notification_receipt_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.notification_receipt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_receipt_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.notification_receipt_id_seq OWNED BY core.notification_receipt.id;


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
-- Name: current_preference; Type: VIEW; Schema: notifications; Owner: -
--

CREATE VIEW notifications.current_preference AS
 SELECT preference.id,
    preference.user_account_id,
    preference.last_modified,
    preference.company_update_via_email,
    preference.aotd_via_email,
    preference.aotd_via_extension,
    preference.aotd_via_push,
    preference.aotd_digest_via_email,
    preference.reply_via_email,
    preference.reply_via_extension,
    preference.reply_via_push,
    preference.reply_digest_via_email,
    preference.loopback_via_email,
    preference.loopback_via_extension,
    preference.loopback_via_push,
    preference.loopback_digest_via_email,
    preference.post_via_email,
    preference.post_via_extension,
    preference.post_via_push,
    preference.post_digest_via_email,
    preference.follower_via_email,
    preference.follower_via_extension,
    preference.follower_via_push,
    preference.follower_digest_via_email
   FROM (core.notification_preference preference
     LEFT JOIN core.notification_preference later_preference ON (((later_preference.user_account_id = preference.user_account_id) AND (later_preference.last_modified > preference.last_modified))))
  WHERE (later_preference.id IS NULL);


--
-- Name: registered_push_device; Type: VIEW; Schema: notifications; Owner: -
--

CREATE VIEW notifications.registered_push_device AS
 SELECT notification_push_device.id,
    notification_push_device.date_registered,
    notification_push_device.date_unregistered,
    notification_push_device.unregistration_reason,
    notification_push_device.user_account_id,
    notification_push_device.installation_id,
    notification_push_device.name,
    notification_push_device.token
   FROM core.notification_push_device
  WHERE (notification_push_device.date_unregistered IS NULL);


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
    comment.text AS comment_text,
    comment.addenda AS comment_addenda,
    NULL::bigint AS silent_post_id,
    comment.date_deleted
   FROM social.comment
  WHERE (comment.parent_comment_id IS NULL)
UNION ALL
 SELECT silent_post.article_id,
    silent_post.user_account_id,
    silent_post.date_created,
    NULL::bigint AS comment_id,
    NULL::text AS comment_text,
    NULL::social.comment_addendum[] AS comment_addenda,
    silent_post.id AS silent_post_id,
    NULL::timestamp without time zone AS date_deleted
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
-- Name: comment_addendum id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_addendum ALTER COLUMN id SET DEFAULT nextval('core.comment_addendum_id_seq'::regclass);


--
-- Name: comment_revision id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_revision ALTER COLUMN id SET DEFAULT nextval('core.comment_revision_id_seq'::regclass);


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
-- Name: notification_data id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data ALTER COLUMN id SET DEFAULT nextval('core.notification_data_id_seq'::regclass);


--
-- Name: notification_event id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_event ALTER COLUMN id SET DEFAULT nextval('core.notification_event_id_seq'::regclass);


--
-- Name: notification_interaction id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_interaction ALTER COLUMN id SET DEFAULT nextval('core.notification_interaction_id_seq'::regclass);


--
-- Name: notification_preference id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_preference ALTER COLUMN id SET DEFAULT nextval('core.notification_preference_id_seq'::regclass);


--
-- Name: notification_push_auth_denial id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_auth_denial ALTER COLUMN id SET DEFAULT nextval('core.notification_push_auth_denial_id_seq'::regclass);


--
-- Name: notification_push_device id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_device ALTER COLUMN id SET DEFAULT nextval('core.notification_push_device_id_seq'::regclass);


--
-- Name: notification_receipt id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt ALTER COLUMN id SET DEFAULT nextval('core.notification_receipt_id_seq'::regclass);


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
-- Name: comment_addendum comment_addendum_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_addendum
    ADD CONSTRAINT comment_addendum_pkey PRIMARY KEY (id);


--
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: comment_revision comment_revision_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_revision
    ADD CONSTRAINT comment_revision_pkey PRIMARY KEY (id);


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
-- Name: notification_data notification_data_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_pkey PRIMARY KEY (id);


--
-- Name: notification_event notification_event_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_event
    ADD CONSTRAINT notification_event_pkey PRIMARY KEY (id);


--
-- Name: notification_interaction notification_interaction_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_interaction
    ADD CONSTRAINT notification_interaction_pkey PRIMARY KEY (id);


--
-- Name: notification_preference notification_preference_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_preference
    ADD CONSTRAINT notification_preference_pkey PRIMARY KEY (id);


--
-- Name: notification_push_auth_denial notification_push_auth_denial_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_auth_denial
    ADD CONSTRAINT notification_push_auth_denial_pkey PRIMARY KEY (id);


--
-- Name: notification_push_device notification_push_device_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_device
    ADD CONSTRAINT notification_push_device_pkey PRIMARY KEY (id);


--
-- Name: notification_receipt notification_receipt_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt
    ADD CONSTRAINT notification_receipt_pkey PRIMARY KEY (id);


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
-- Name: notification_interaction_unique_open; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX notification_interaction_unique_open ON core.notification_interaction USING btree (receipt_id, channel, action) WHERE (action = 'open'::core.notification_action);


--
-- Name: notification_interaction_unique_view; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX notification_interaction_unique_view ON core.notification_interaction USING btree (receipt_id, channel, action, url);


--
-- Name: notification_push_device_unique_registered_installation_id; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX notification_push_device_unique_registered_installation_id ON core.notification_push_device USING btree (installation_id) WHERE (date_unregistered IS NULL);


--
-- Name: notification_push_device_unique_registered_token; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX notification_push_device_unique_registered_token ON core.notification_push_device USING btree (token) WHERE (date_unregistered IS NULL);


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
-- Name: notification _RETURN; Type: RULE; Schema: notifications; Owner: -
--

CREATE OR REPLACE VIEW notifications.notification AS
 SELECT event.id AS event_id,
    event.date_created,
    event.type AS event_type,
    COALESCE(array_agg(data.article_id) FILTER (WHERE (data.article_id IS NOT NULL)), '{}'::bigint[]) AS article_ids,
    COALESCE(array_agg(data.comment_id) FILTER (WHERE (data.comment_id IS NOT NULL)), '{}'::bigint[]) AS comment_ids,
    COALESCE(array_agg(data.silent_post_id) FILTER (WHERE (data.silent_post_id IS NOT NULL)), '{}'::bigint[]) AS silent_post_ids,
    COALESCE(array_agg(data.following_id) FILTER (WHERE (data.following_id IS NOT NULL)), '{}'::bigint[]) AS following_ids,
    receipt.id AS receipt_id,
    receipt.user_account_id,
    receipt.date_alert_cleared,
    receipt.via_email,
    receipt.via_extension,
    receipt.via_push
   FROM ((core.notification_event event
     JOIN core.notification_receipt receipt ON ((receipt.event_id = event.id)))
     LEFT JOIN core.notification_data data ON ((data.event_id = event.id)))
  GROUP BY event.id, receipt.id;


--
-- Name: comment _RETURN; Type: RULE; Schema: social; Owner: -
--

CREATE OR REPLACE VIEW social.comment AS
 SELECT comment.id,
    comment.date_created,
    comment.text,
    comment.article_id,
    article.title AS article_title,
    article.slug AS article_slug,
    comment.user_account_id,
    user_account.name AS user_account,
    comment.parent_comment_id,
    COALESCE(array_agg(ROW(addendum.date_created, addendum.text_content)::social.comment_addendum) FILTER (WHERE (addendum.id IS NOT NULL)), '{}'::social.comment_addendum[]) AS addenda,
    comment.date_deleted
   FROM (((core.comment
     JOIN core.article ON ((article.id = comment.article_id)))
     JOIN core.user_account ON ((user_account.id = comment.user_account_id)))
     LEFT JOIN core.comment_addendum addendum ON ((addendum.comment_id = comment.id)))
  GROUP BY comment.id, article.id, user_account.id;


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
-- Name: comment_addendum comment_addendum_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_addendum
    ADD CONSTRAINT comment_addendum_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES core.comment(id);


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
-- Name: comment_revision comment_revision_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.comment_revision
    ADD CONSTRAINT comment_revision_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES core.comment(id);


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
-- Name: notification_data notification_data_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: notification_data notification_data_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES core.comment(id);


--
-- Name: notification_data notification_data_email_confirmation_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_email_confirmation_id_fkey FOREIGN KEY (email_confirmation_id) REFERENCES core.email_confirmation(id);


--
-- Name: notification_data notification_data_event_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_event_id_fkey FOREIGN KEY (event_id) REFERENCES core.notification_event(id);


--
-- Name: notification_data notification_data_following_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_following_id_fkey FOREIGN KEY (following_id) REFERENCES core.following(id);


--
-- Name: notification_data notification_data_password_reset_request_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_password_reset_request_id_fkey FOREIGN KEY (password_reset_request_id) REFERENCES core.password_reset_request(id);


--
-- Name: notification_data notification_data_silent_post_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_data
    ADD CONSTRAINT notification_data_silent_post_id_fkey FOREIGN KEY (silent_post_id) REFERENCES core.silent_post(id);


--
-- Name: notification_event notification_event_bulk_email_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_event
    ADD CONSTRAINT notification_event_bulk_email_author_id_fkey FOREIGN KEY (bulk_email_author_id) REFERENCES core.user_account(id);


--
-- Name: notification_interaction notification_interaction_receipt_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_interaction
    ADD CONSTRAINT notification_interaction_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES core.notification_receipt(id);


--
-- Name: notification_interaction notification_interaction_reply_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_interaction
    ADD CONSTRAINT notification_interaction_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES core.comment(id);


--
-- Name: notification_preference notification_preference_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_preference
    ADD CONSTRAINT notification_preference_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: notification_push_auth_denial notification_push_auth_denial_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_auth_denial
    ADD CONSTRAINT notification_push_auth_denial_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: notification_push_device notification_push_device_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_push_device
    ADD CONSTRAINT notification_push_device_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: notification_receipt notification_receipt_event_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt
    ADD CONSTRAINT notification_receipt_event_id_fkey FOREIGN KEY (event_id) REFERENCES core.notification_event(id);


--
-- Name: notification_receipt notification_receipt_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt
    ADD CONSTRAINT notification_receipt_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


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

