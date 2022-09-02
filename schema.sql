-- Copyright (C) 2022 reallyread.it, inc.
--
-- This file is part of Readup.
--
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
--
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2
-- Dumped by pg_dump version 14.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
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
-- Name: articles; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA articles;


--
-- Name: authors; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA authors;


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
-- Name: subscriptions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA subscriptions;


--
-- Name: user_account_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA user_account_api;


--
-- Name: monthly_recurring_revenue_report_line_item; Type: TYPE; Schema: analytics; Owner: -
--

CREATE TYPE analytics.monthly_recurring_revenue_report_line_item AS (
	period timestamp without time zone,
	amount integer
);


--
-- Name: subscription_provider; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_provider AS ENUM (
    'apple',
    'stripe'
);


--
-- Name: revenue_report_line_item; Type: TYPE; Schema: analytics; Owner: -
--

CREATE TYPE analytics.revenue_report_line_item AS (
	period timestamp without time zone,
	provider core.subscription_provider,
	price_name text,
	price_amount integer,
	quantity_purchased integer,
	quantity_refunded integer
);


--
-- Name: weekly_user_activity_report; Type: TYPE; Schema: analytics; Owner: -
--

CREATE TYPE analytics.weekly_user_activity_report AS (
	week timestamp without time zone,
	active_user_count integer,
	active_reader_count integer,
	minutes_reading integer,
	minutes_reading_to_completion integer
);


--
-- Name: article_author; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.article_author AS (
	name text,
	slug text
);


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
	rating_count integer,
	first_poster text,
	flair core.article_flair,
	aotd_contender_rank integer,
	article_authors article_api.article_author[]
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
	rating_count integer,
	first_poster text,
	flair core.article_flair,
	aotd_contender_rank integer,
	article_authors article_api.article_author[],
	total_count bigint
);


--
-- Name: author_metadata; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.author_metadata AS (
	name text,
	url text,
	slug text
);


--
-- Name: tag_metadata; Type: TYPE; Schema: article_api; Owner: -
--

CREATE TYPE article_api.tag_metadata AS (
	name text,
	slug text
);


--
-- Name: article; Type: TYPE; Schema: articles; Owner: -
--

CREATE TYPE articles.article AS (
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


--
-- Name: article_ids_page; Type: TYPE; Schema: articles; Owner: -
--

CREATE TYPE articles.article_ids_page AS (
	article_ids bigint[],
	total_count integer
);


--
-- Name: author_contact_status_assignment; Type: TYPE; Schema: authors; Owner: -
--

CREATE TYPE authors.author_contact_status_assignment AS (
	slug text,
	contact_status text
);


--
-- Name: auth_service_association_method; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.auth_service_association_method AS ENUM (
    'auto',
    'manual',
    'link'
);


--
-- Name: auth_service_provider; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.auth_service_provider AS ENUM (
    'apple',
    'twitter'
);


--
-- Name: auth_service_real_user_rating; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.auth_service_real_user_rating AS ENUM (
    'likely_real',
    'unknown',
    'unsupported',
    'verified'
);


--
-- Name: author_assignment_method; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.author_assignment_method AS ENUM (
    'metadata',
    'manual'
);


--
-- Name: author_contact_status; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.author_contact_status AS ENUM (
    'none',
    'attempted'
);


--
-- Name: base64_text; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.base64_text AS text
	CONSTRAINT base64_text_check CHECK ((VALUE ~ similar_escape('[A-Za-z0-9+/]+={0,2}'::text, NULL::text)));


--
-- Name: calendar_month; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.calendar_month AS integer
	CONSTRAINT calendar_month_check CHECK ((VALUE <@ int4range(1, 12, '[]'::text)));


--
-- Name: calendar_year; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.calendar_year AS integer
	CONSTRAINT calendar_year_check CHECK ((VALUE <@ int4range(1000, 9999, '[]'::text)));


--
-- Name: challenge_response_action; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.challenge_response_action AS ENUM (
    'enroll',
    'decline',
    'disenroll'
);


--
-- Name: display_theme; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.display_theme AS ENUM (
    'light',
    'dark'
);


--
-- Name: free_trial_credit_trigger; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.free_trial_credit_trigger AS ENUM (
    'account_created',
    'promo_tweet_intended'
);


--
-- Name: free_trial_credit_type; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.free_trial_credit_type AS ENUM (
    'article_view'
);


--
-- Name: iso_alpha_2_country_code; Type: DOMAIN; Schema: core; Owner: -
--

CREATE DOMAIN core.iso_alpha_2_country_code AS character(2)
	CONSTRAINT iso_alpha_2_country_code_check CHECK ((VALUE ~ similar_escape('[A-Z]{2}'::text, NULL::text)));


--
-- Name: notification_action; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_action AS ENUM (
    'open',
    'view',
    'reply'
);


--
-- Name: notification_authorization_request_result; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.notification_authorization_request_result AS ENUM (
    'none',
    'granted',
    'denied',
    'previously_granted',
    'previously_denied'
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
    'free_trial_completion',
    'initial_subscription',
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
    'service_unregistered',
    'reinstall'
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
-- Name: subscription_environment; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_environment AS ENUM (
    'production',
    'sandbox'
);


--
-- Name: subscription_event_source; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_event_source AS ENUM (
    'provider_notification',
    'user_action'
);


--
-- Name: subscription_payment_method_brand; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_payment_method_brand AS ENUM (
    'none',
    'unknown',
    'amex',
    'diners',
    'discover',
    'jcb',
    'mastercard',
    'unionpay',
    'visa'
);


--
-- Name: subscription_payment_method_wallet; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_payment_method_wallet AS ENUM (
    'none',
    'unknown',
    'amex_express_checkout',
    'apple_pay',
    'google_pay',
    'masterpass',
    'samsung_pay',
    'visa_checkout'
);


--
-- Name: subscription_payment_status; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.subscription_payment_status AS ENUM (
    'succeeded',
    'requires_confirmation',
    'failed'
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
-- Name: twitter_handle_assignment; Type: TYPE; Schema: core; Owner: -
--

CREATE TYPE core.twitter_handle_assignment AS ENUM (
    'none',
    'manual',
    'name_search',
    'name_and_company_search'
);


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
-- Name: bulk_email_subscription_status_filter; Type: TYPE; Schema: notifications; Owner: -
--

CREATE TYPE notifications.bulk_email_subscription_status_filter AS ENUM (
    'currently_subscribed',
    'not_currently_subscribed',
    'never_subscribed'
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
	rating_count integer,
	first_poster text,
	flair core.article_flair,
	aotd_contender_rank integer,
	article_authors article_api.article_author[],
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
-- Name: post; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.post AS (
	date_created timestamp without time zone,
	user_name text,
	article_id bigint,
	comment_id bigint,
	comment_text text,
	comment_addenda social.comment_addendum[],
	silent_post_id bigint,
	date_deleted timestamp without time zone,
	has_alert boolean
);


--
-- Name: post_reference; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.post_reference AS (
	comment_id bigint,
	silent_post_id bigint
);


--
-- Name: post_references_page; Type: TYPE; Schema: social; Owner: -
--

CREATE TYPE social.post_references_page AS (
	post_references social.post_reference[],
	total_count integer
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
-- Name: author_earnings_report_line_item; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.author_earnings_report_line_item AS (
	author_id bigint,
	author_name text,
	author_slug text,
	user_account_id bigint,
	user_account_name text,
	donation_recipient_id bigint,
	donation_recipient_name text,
	minutes_read integer,
	amount_earned integer,
	amount_paid integer
);


--
-- Name: free_trial_article_view; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.free_trial_article_view AS (
	article_id bigint,
	article_slug text,
	date_viewed timestamp without time zone,
	free_trial_credit_id bigint
);


--
-- Name: payout_totals_report; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.payout_totals_report AS (
	totalauthorpayouts integer,
	totaldonationpayouts integer
);


--
-- Name: subscription_allocation_calculation; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_allocation_calculation AS (
	platform_amount integer,
	provider_amount integer,
	author_amount integer
);


--
-- Name: subscription_distribution_author_calculation; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_distribution_author_calculation AS (
	author_id integer,
	minutes_read integer,
	amount integer
);


--
-- Name: subscription_distribution_author_report; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_distribution_author_report AS (
	author_id bigint,
	author_name text,
	author_slug text,
	minutes_read integer,
	amount integer
);


--
-- Name: subscription_distribution_calculation; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_distribution_calculation AS (
	platform_amount integer,
	provider_amount integer,
	unknown_author_minutes_read integer,
	unknown_author_amount integer,
	author_distributions subscriptions.subscription_distribution_author_calculation[]
);


--
-- Name: subscription_distribution_report; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_distribution_report AS (
	subscription_amount integer,
	platform_amount integer,
	apple_amount integer,
	stripe_amount integer,
	unknown_author_minutes_read integer,
	unknown_author_amount integer,
	author_distributions subscriptions.subscription_distribution_author_report[]
);


--
-- Name: subscription_status_latest_period; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_status_latest_period AS (
	provider_period_id text,
	provider_price_id text,
	price_level_name text,
	price_amount integer,
	provider_payment_method_id text,
	begin_date timestamp without time zone,
	end_date timestamp without time zone,
	renewal_grace_period_end_date timestamp without time zone,
	date_created timestamp without time zone,
	payment_status core.subscription_payment_status,
	date_paid timestamp without time zone,
	date_refunded timestamp without time zone,
	refund_reason text
);


--
-- Name: subscription_status_latest_renewal_status_change; Type: TYPE; Schema: subscriptions; Owner: -
--

CREATE TYPE subscriptions.subscription_status_latest_renewal_status_change AS (
	date_created timestamp without time zone,
	auto_renew_enabled boolean,
	provider_price_id text,
	price_level_name text,
	price_amount integer
);


SET default_table_access_method = heap;

--
-- Name: website_traffic_weekly_total; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.website_traffic_weekly_total (
    week timestamp without time zone NOT NULL,
    unique_visit_count integer NOT NULL,
    last_updated timestamp without time zone NOT NULL,
    unique_authenticated_visit_count integer DEFAULT 0 NOT NULL
);


--
-- Name: create_or_update_website_traffic_weekly_total(timestamp without time zone, integer, integer); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.create_or_update_website_traffic_weekly_total(week timestamp without time zone, unique_visit_count integer, unique_authenticated_visit_count integer) RETURNS SETOF core.website_traffic_weekly_total
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.website_traffic_weekly_total (
			week,
			unique_visit_count,
			unique_authenticated_visit_count,
			last_updated
		)
	VALUES (
		create_or_update_website_traffic_weekly_total.week,
		create_or_update_website_traffic_weekly_total.unique_visit_count,
		create_or_update_website_traffic_weekly_total.unique_authenticated_visit_count,
		core.utc_now()
	)
	ON CONFLICT (
		week
	)
	DO UPDATE SET
		unique_visit_count = create_or_update_website_traffic_weekly_total.unique_visit_count,
		unique_authenticated_visit_count = create_or_update_website_traffic_weekly_total.unique_authenticated_visit_count,
		last_updated = core.utc_now()
	RETURNING
		*;
$$;


--
-- Name: get_article_issue_reports(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_article_issue_reports(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(date_created timestamp without time zone, article_url text, article_aotd_contender_rank integer, user_name text, issue text, client_type text)
    LANGUAGE sql STABLE
    AS $$
    SELECT
        report.date_created,
        page.url,
        article.aotd_contender_rank,
        user_account.name::text,
        report.issue,
        report.analytics->'client'->>'type'
    FROM
        core.article_issue_report AS report
        JOIN core.article ON
            article.id = report.article_id
        LEFT JOIN core.page ON
            page.article_id = report.article_id
        JOIN core.user_account ON
            user_account.id = report.user_account_id
    WHERE
        report.date_created <@ tsrange(get_article_issue_reports.start_date, get_article_issue_reports.end_date)
    ORDER BY
        report.date_created DESC;
$$;


--
-- Name: get_articles_requiring_author_assignments(); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_articles_requiring_author_assignments() RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	WITH authorless_subscriber_article AS (
		SELECT
			article.id,
			article.word_count
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
	)
	SELECT
		article_api_article.*
	FROM
		article_api.get_articles(
			NULL::bigint,
			VARIADIC ARRAY(
				SELECT DISTINCT
					authorless_subscriber_article.id
				FROM
					authorless_subscriber_article
			)
		) AS article_api_article
	ORDER BY
		article_api_article.word_count DESC;
$$;


--
-- Name: get_articles_requiring_author_assignments_v1(); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_articles_requiring_author_assignments_v1() RETURNS SETOF bigint
    LANGUAGE sql STABLE
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


--
-- Name: get_conversions(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_conversions(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(week timestamp without time zone, visitor_count bigint, signup_count bigint, signup_conversion numeric, article_viewer_count bigint, article_viewer_conversion numeric, article_reader_count bigint, article_reader_conversion numeric)
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
			first_day AS week,
			tsrange(first_day, first_day + '1 week'::interval) AS range
		FROM
			generate_series(
				get_conversions.start_date,
				get_conversions.end_date,
				'1 week'::interval
			) AS week (first_day)
	)
	SELECT
		report_period.week,
		visitor_total.count,
		signup_total.count,
		(
			CASE WHEN visitor_total.count > 0
				THEN signup_total.count::numeric / visitor_total.count
				ELSE 0
			END
		),
		article_action_total.viewer_count,
		(
			CASE WHEN signup_total.count > 0
				THEN article_action_total.viewer_count::numeric / signup_total.count
				ELSE 0
			END
		),
		article_action_total.reader_count,
		(
			CASE WHEN article_action_total.viewer_count > 0
				THEN article_action_total.reader_count::numeric / article_action_total.viewer_count
				ELSE 0
			END
		)
	FROM
		report_period
		JOIN (
			SELECT
				report_period.week,
				coalesce(sum(traffic_total.unique_visit_count), 0) AS count
			FROM
				report_period
				LEFT JOIN core.website_traffic_weekly_total AS traffic_total ON
					traffic_total.week <@ report_period.range
			GROUP BY
				report_period.week
		) AS visitor_total ON
			visitor_total.week = report_period.week
		JOIN (
			SELECT
				report_period.week,
				coalesce(count(user_account.id), 0) AS count
			FROM
				report_period
				LEFT JOIN core.user_account ON
					user_account.date_created <@ report_period.range
			GROUP BY
				report_period.week
		) AS signup_total ON
			signup_total.week = report_period.week
		JOIN (
			SELECT
				report_period.week,
				coalesce(
					count(new_user.date_created) FILTER (WHERE new_user.has_viewed_article),
					0
				) AS viewer_count,
				coalesce(
					count(new_user.date_created) FILTER (WHERE new_user.has_read_article),
					0
				) AS reader_count
			FROM
				report_period
				LEFT JOIN (
					SELECT
						user_account.date_created,
						coalesce(
							min(user_article.date_created) < user_account.date_created + '1 week'::interval,
							false
						) AS has_viewed_article,
						coalesce(
							min(user_article.date_completed) < user_account.date_created + '1 week'::interval,
							false
						) AS has_read_article
					FROM
						core.user_account
						JOIN
							core.user_article ON
								user_account.id = user_article.user_account_id
						JOIN
							core.article ON
								user_article.article_id = article.id
					WHERE
						user_account.date_created <@ (
							SELECT
								tsrange(
									min(lower(report_period.range)),
									max(upper(report_period.range))
								)
							FROM
								report_period
						) AND
						article.source_id != 48542 -- readup blog
					GROUP BY
						user_account.id
				) AS new_user ON
					report_period.range @> new_user.date_created
			GROUP BY
				report_period.week
		) AS article_action_total ON
			report_period.week = article_action_total.week
	ORDER BY
		report_period.week DESC;
$$;


--
-- Name: get_daily_totals(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_daily_totals(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(day timestamp without time zone, signup_app_count bigint, signup_browser_count bigint, signup_unknown_count bigint, read_app_count bigint, read_browser_count bigint, read_unknown_count bigint, post_app_count bigint, post_browser_count bigint, post_unknown_count bigint, reply_app_count bigint, reply_browser_count bigint, reply_unknown_count bigint, post_tweet_app_count bigint, post_tweet_browser_count bigint, extension_installation_count bigint, extension_removal_count bigint, subscriptions_active_count bigint, subscription_lapse_count bigint)
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
			date AS day,
			tsrange(date, date + '1 day'::interval) AS range
		FROM generate_series(
			get_daily_totals.start_date,
			get_daily_totals.end_date,
			'1 day'::interval
		) AS series (date)
	)
	SELECT
		report_period.day,
		coalesce(signup_totals.app_count, 0),
		coalesce(signup_totals.browser_count, 0),
		coalesce(signup_totals.unknown_count, 0),
		coalesce(read_totals.app_count, 0),
		coalesce(read_totals.browser_count, 0),
		coalesce(read_totals.unknown_count, 0),
		coalesce(comment_totals.post_app_count, 0) + coalesce(silent_post_totals.app_count, 0),
		coalesce(comment_totals.post_browser_count, 0) + coalesce(silent_post_totals.browser_count, 0),
		coalesce(comment_totals.post_unknown_count, 0) + coalesce(silent_post_totals.unknown_count, 0),
		coalesce(comment_totals.reply_app_count, 0),
		coalesce(comment_totals.reply_browser_count, 0),
		coalesce(comment_totals.reply_unknown_count, 0),
		coalesce(post_tweet_total.app_count, 0) AS post_tweet_app_count,
		coalesce(post_tweet_total.browser_count, 0) AS post_tweet_browser_count,
		coalesce(extension_installation_total.count, 0) AS extension_installation_count,
		coalesce(extension_removal_total.count, 0) AS extension_removal_count,
		coalesce(subscriptions_total.active_count, 0),
		coalesce(subscriptions_total.lapsed_count, 0)
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
		) AS signup_totals ON signup_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_article
				JOIN report_period ON user_article.date_completed <@ report_period.range
				JOIN user_account ON user_article.user_account_id = user_account.id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY report_period.day
		) AS read_totals ON read_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						(
							comment.analytics->'client'->>'mode' = 'App' OR
							comment.analytics->'client'->>'type' = 'ios/app'
						)
				) AS post_app_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						(
							comment.analytics->'client'->>'mode' = 'Browser' OR
							comment.analytics->'client'->>'type' = 'web/extension'
						)
				) AS post_browser_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NULL AND
						comment.analytics IS NULL
				) AS post_unknown_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						(
							comment.analytics->'client'->>'mode' = 'App' OR
							comment.analytics->'client'->>'type' = 'ios/app'
						)
				) AS reply_app_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						(
							comment.analytics->'client'->>'mode' = 'Browser' OR
							comment.analytics->'client'->>'type' = 'web/extension'
						)
				) AS reply_browser_count,
				count(*) FILTER (
					WHERE
						comment.parent_comment_id IS NOT NULL AND
						comment.analytics IS NULL
				) AS reply_unknown_count
			FROM
				report_period
				JOIN core.comment ON
					comment.date_created <@ report_period.range
				JOIN core.user_account ON
					user_account.id = comment.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS comment_totals ON
			comment_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						silent_post.analytics->'client'->>'mode' = 'App' OR
						silent_post.analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (
					WHERE
						silent_post.analytics->'client'->>'mode' = 'Browser' OR
						silent_post.analytics->'client'->>'type' = 'web/extension'
				) AS browser_count,
				count(*) FILTER (WHERE silent_post.analytics IS NULL) AS unknown_count
			FROM
				report_period
				JOIN core.silent_post ON
					silent_post.date_created <@ report_period.range
				JOIN core.user_account ON
					user_account.id = silent_post.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS silent_post_totals ON
			silent_post_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (
					WHERE
						comment.analytics->'client'->>'mode' = 'App' OR
						comment.analytics->'client'->>'type' = 'ios/app' OR
						silent_post.analytics->'client'->>'mode' = 'App' OR
						silent_post.analytics->'client'->>'type' = 'ios/app'
				) AS app_count,
				count(*) FILTER (
					WHERE
						comment.analytics->'client'->>'mode' = 'Browser' OR
						comment.analytics->'client'->>'type' = 'web/extension' OR
						silent_post.analytics->'client'->>'mode' = 'Browser' OR
						silent_post.analytics->'client'->>'type' = 'web/extension'
				) AS browser_count
			FROM
				report_period
				JOIN core.auth_service_post ON
					auth_service_post.date_posted <@ report_period.range
				LEFT JOIN core.comment ON
					comment.id = auth_service_post.comment_id
				LEFT JOIN core.silent_post ON
					silent_post.id = auth_service_post.silent_post_id
				JOIN core.user_account ON
					user_account.id = comment.user_account_id OR
					user_account.id = silent_post.user_account_id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.day
		) AS post_tweet_total ON
				post_tweet_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) AS count
			FROM
				extension_installation
				JOIN report_period ON extension_installation.timestamp <@ report_period.range
				LEFT JOIN user_account ON extension_installation.user_account_id = user_account.id
			WHERE
				coalesce(user_account.role, 'regular'::core.user_account_role) != 'admin'::core.user_account_role
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
				LEFT JOIN user_account ON extension_removal.user_account_id = user_account.id
			WHERE
				coalesce(user_account.role, 'regular'::core.user_account_role) != 'admin'::core.user_account_role
		GROUP BY
			report_period.day
		) AS extension_removal_total ON extension_removal_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(DISTINCT subscription_account.user_account_id)
					FILTER (
						WHERE
							report_period.range && tsrange(
								subscription_period.begin_date,
								coalesce(subscription_period.date_refunded, subscription_period.end_date)
							)
					) AS active_count,
				count(DISTINCT subscription_account.user_account_id)
					FILTER (
						WHERE
							report_period.range @> subscription_period.renewal_grace_period_end_date AND
							coalesce(next_period.payment_status, 'failed'::core.subscription_payment_status) != 'succeeded'::core.subscription_payment_status AND
							subscription_period.renewal_grace_period_end_date <= core.utc_now()
					) AS lapsed_count
			FROM
				report_period
				JOIN
					core.subscription_period ON
						report_period.range && tsrange(
							subscription_period.begin_date,
							coalesce(subscription_period.date_refunded, subscription_period.end_date)
						) OR
						report_period.range @> subscription_period.renewal_grace_period_end_date
				JOIN
					core.subscription ON
						subscription_period.provider = subscription.provider AND
						subscription_period.provider_subscription_id = subscription.provider_subscription_id
				JOIN
					core.subscription_account ON
						subscription.provider = subscription_account.provider AND
						subscription.provider_account_id = subscription_account.provider_account_id
				JOIN
					core.user_account ON
						subscription_account.user_account_id = user_account.id
				LEFT JOIN
					core.subscription_period AS next_period ON
						subscription_period.provider = next_period.provider AND
						subscription_period.next_provider_period_id = next_period.provider_period_id
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					user_account.role != 'admin'::core.user_account_role AND
					subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			GROUP BY
				report_period.day
		) AS subscriptions_total ON
			report_period.day = subscriptions_total.day
	ORDER BY report_period.day DESC;
$$;


--
-- Name: get_monthly_recurring_revenue_report(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_monthly_recurring_revenue_report(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS SETOF analytics.monthly_recurring_revenue_report_line_item
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
			series.period,
			tsrange(series.period, series.period + '1 day'::interval) AS range
		FROM
			generate_series(
				get_monthly_recurring_revenue_report.start_date,
				get_monthly_recurring_revenue_report.end_date,
				'1 day'::interval
			) AS series (
				period
			)
	)
	SELECT
		report_period.period,
		coalesce(
			sum(report_period_user_account_amount.amount)::int,
			0
		)
	FROM
		report_period
		LEFT JOIN (
			SELECT DISTINCT ON (
					report_period.period,
					subscription_account.user_account_id
				)
				report_period.period,
				coalesce(
					subscription_period.prorated_price_amount,
					price_level.amount
				) AS amount
			FROM
				report_period
				JOIN
					core.subscription_period ON
						report_period.range && tsrange(
							subscription_period.begin_date,
							coalesce(subscription_period.date_refunded, subscription_period.end_date)
						)
				JOIN
					subscriptions.price_level ON
						subscription_period.provider = price_level.provider AND
						subscription_period.provider_price_id = price_level.provider_price_id
				JOIN
					core.subscription ON
						subscription_period.provider = subscription.provider AND
						subscription_period.provider_subscription_id = subscription.provider_subscription_id
				JOIN
					core.subscription_account ON
						subscription.provider = subscription_account.provider AND
						subscription.provider_account_id = subscription_account.provider_account_id
				JOIN
					core.user_account ON
						subscription_account.user_account_id = user_account.id
				WHERE
					subscription_account.environment = 'production'::core.subscription_environment AND
					user_account.role != 'admin'::core.user_account_role AND
					subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			ORDER BY
				period,
				subscription_account.user_account_id,
				subscription_period.begin_date DESC
		) AS report_period_user_account_amount ON
			report_period.period = report_period_user_account_amount.period
	GROUP BY
		report_period.period
	ORDER BY
		report_period.period;
$$;


--
-- Name: get_revenue_report(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_revenue_report(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS SETOF analytics.revenue_report_line_item
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
			series.period,
			tsrange(series.period, series.period + '1 day'::interval) AS range
		FROM
			generate_series(
				get_revenue_report.start_date,
				get_revenue_report.end_date,
				'1 day'::interval
			) AS series (
				period
			)
	),
	purchase AS (
		SELECT
			period.date_paid,
			period.date_refunded,
			period.provider,
			price.name AS price_name,
			coalesce(period.prorated_price_amount, price.amount) AS price_amount
		FROM
			core.subscription_period AS period
			JOIN
				subscriptions.price_level AS price ON
					period.provider = price.provider AND
					period.provider_price_id = price.provider_price_id
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id AND
					account.environment = 'production'::core.subscription_environment
			JOIN
				core.user_account ON
					account.user_account_id = user_account.id AND
					user_account.role != 'admin'::core.user_account_role
		WHERE
			period.payment_status = 'succeeded'::core.subscription_payment_status
	)
	SELECT
		report_period.period,
		purchase.provider,
		purchase.price_name,
		coalesce(purchase.price_amount, 0),
		count(purchase.date_paid)::int,
		count(purchase.date_refunded)::int
	FROM
		report_period
		LEFT JOIN
			purchase ON
				report_period.range @> purchase.date_paid OR
				report_period.range @> purchase.date_refunded
	GROUP BY
		report_period.period,
		purchase.provider,
		purchase.price_amount,
		purchase.price_name;
$$;


--
-- Name: get_signups(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_signups(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS TABLE(id bigint, name text, email text, date_created timestamp without time zone, time_zone_name text, client_mode text, marketing_variant integer, referrer_url text, initial_path text, current_path text, action text, article_view_count bigint, article_read_count bigint, date_subscribed timestamp without time zone)
    LANGUAGE sql STABLE
    AS $$
	WITH new_user AS (
		SELECT
			user_account.id,
			user_account.name,
			user_account.email,
			user_account.date_created,
			user_account.time_zone_id,
			user_account.creation_analytics
		FROM
			core.user_account
		WHERE
			user_account.date_created <@ tsrange(get_signups.start_date, get_signups.end_date)
	)
	SELECT
		new_user.id,
		new_user.name,
		new_user.email,
		new_user.date_created,
		time_zone.name,
		new_user.creation_analytics->'client'->>'mode',
		(new_user.creation_analytics->>'marketing_variant')::int,
		new_user.creation_analytics->>'referrer_url',
		new_user.creation_analytics->>'initial_path',
		new_user.creation_analytics->>'current_path',
		new_user.creation_analytics->>'action',
		coalesce(user_article_stats.view_count, 0),
		coalesce(user_article_stats.read_count, 0),
		subscription_purchase.date_paid
	FROM
		new_user
		LEFT JOIN time_zone ON
			time_zone.id = new_user.time_zone_id
		LEFT JOIN (
			SELECT
				new_user.id AS user_account_id,
				count(*) AS view_count,
				count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS read_count
			FROM
				new_user
				JOIN
					core.user_article ON
						new_user.id = user_article.user_account_id
				JOIN
					core.article ON
						user_article.article_id = article.id
			WHERE
				article.source_id != 48542 -- readup blog
			GROUP BY
				new_user.id
		) AS user_article_stats ON
			user_article_stats.user_account_id = new_user.id
		LEFT JOIN (
			SELECT
				new_user.id AS user_account_id,
				min(subscription_period.date_paid) AS date_paid
			FROM
				new_user
				JOIN
					core.subscription_account ON
						new_user.id = subscription_account.user_account_id
				JOIN
					core.subscription ON
						subscription_account.provider = subscription.provider AND
						subscription_account.provider_account_id = subscription.provider_account_id
				JOIN
					core.subscription_period ON
						subscription.provider = subscription_period.provider AND
						subscription.provider_subscription_id = subscription_period.provider_subscription_id
			WHERE
				subscription_account.environment = 'production'::core.subscription_environment AND
				subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
			GROUP BY
				new_user.id
		) AS subscription_purchase ON
			subscription_purchase.user_account_id = new_user.id
	ORDER BY
		new_user.date_created DESC;
$$;


--
-- Name: get_weekly_user_activity(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.get_weekly_user_activity(start_date timestamp without time zone, end_date timestamp without time zone) RETURNS SETOF analytics.weekly_user_activity_report
    LANGUAGE sql STABLE
    AS $$
	WITH report_period AS (
		SELECT
			first_day AS week,
			tsrange(first_day, first_day + '1 week'::interval) AS range
		FROM
			generate_series(
				get_weekly_user_activity.start_date,
				get_weekly_user_activity.end_date,
				'1 week'::interval
			) AS week (first_day)
	)
	SELECT
		report_period.week,
		coalesce(active_user_total.count::int, 0),
		coalesce(reading_time_total.user_count::int, 0),
		coalesce(reading_time_total.minutes_reading, 0),
		coalesce(reading_time_total.minutes_reading_to_completion, 0)
	FROM
		report_period
		LEFT JOIN (
			SELECT
				report_period.week,
				sum(traffic_total.unique_authenticated_visit_count) AS count
			FROM
				report_period
				JOIN
					core.website_traffic_weekly_total AS traffic_total ON
						report_period.range @> traffic_total.week
			GROUP BY
				report_period.week
		) AS active_user_total ON
			report_period.week = active_user_total.week
		LEFT JOIN (
			SELECT
				report_period.week,
				count(DISTINCT user_account.id) AS user_count,
				core.estimate_reading_time(
					sum(progress.words_read)
				) AS minutes_reading,
				core.estimate_reading_time(
					sum(progress.words_read)
						FILTER (
							WHERE user_article.date_completed IS NOT NULL
						)
				) AS minutes_reading_to_completion
			FROM
				report_period
				JOIN
					core.user_article_progress AS progress ON
						report_period.range @> progress.period
				JOIN
					core.user_article ON
						progress.user_account_id = user_article.user_account_id AND
						progress.article_id = user_article.article_id
				JOIN
					core.user_account ON
						user_article.user_account_id = user_account.id
			WHERE
				user_account.role != 'admin'::core.user_account_role
			GROUP BY
				report_period.week
		) AS reading_time_total ON
			report_period.week = reading_time_total.week
	ORDER BY
		report_period.week DESC;
$$;


--
-- Name: log_article_issue_report(bigint, bigint, text, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_article_issue_report(article_id bigint, user_account_id bigint, issue text, analytics text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.article_issue_report (
            article_id,
            user_account_id,
            issue,
            analytics
        )
    VALUES (
        log_article_issue_report.article_id,
        log_article_issue_report.user_account_id,
        log_article_issue_report.issue,
        log_article_issue_report.analytics::jsonb
    );
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
-- Name: log_new_platform_notification_request(text, text, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_new_platform_notification_request(email_address text, ip_address text, user_agent text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.new_platform_notification_request (
            email_address,
            ip_address,
            user_agent
        )
    VALUES (
        log_new_platform_notification_request.email_address,
        log_new_platform_notification_request.ip_address,
        log_new_platform_notification_request.user_agent
    );
$$;


--
-- Name: log_orientation_analytics(bigint, integer, boolean, integer, integer, boolean, integer, text, boolean, integer, uuid, boolean, integer); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_orientation_analytics(user_account_id bigint, tracking_play_count integer, tracking_skipped boolean, tracking_duration integer, import_play_count integer, import_skipped boolean, import_duration integer, notifications_result text, notifications_skipped boolean, notifications_duration integer, share_result_id uuid, share_skipped boolean, share_duration integer) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO core.orientation_analytics (
        user_account_id,
        tracking_play_count,
        tracking_skipped,
        tracking_duration,
        import_play_count,
        import_skipped,
        import_duration,
        notifications_result,
        notifications_skipped,
        notifications_duration,
        share_result_id,
        share_skipped,
        share_duration
    )
    VALUES (
        log_orientation_analytics.user_account_id,
        log_orientation_analytics.tracking_play_count,
        log_orientation_analytics.tracking_skipped,
        log_orientation_analytics.tracking_duration,
        log_orientation_analytics.import_play_count,
        log_orientation_analytics.import_skipped,
        log_orientation_analytics.import_duration,
        log_orientation_analytics.notifications_result::core.notification_authorization_request_result,
        log_orientation_analytics.notifications_skipped,
        log_orientation_analytics.notifications_duration,
        log_orientation_analytics.share_result_id,
        log_orientation_analytics.share_skipped,
        log_orientation_analytics.share_duration
    );
$$;


--
-- Name: log_share_result(uuid, text, bigint, text, text, boolean, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_share_result(id uuid, client_type text, user_account_id bigint, action text, activity_type text, completed boolean, error text) RETURNS void
    LANGUAGE sql
    AS $$
    INSERT INTO core.share_result (
        id,
        client_type,
        user_account_id,
        action,
        activity_type,
        completed,
        error
    )
    VALUES (
        log_share_result.id,
        log_share_result.client_type,
        log_share_result.user_account_id,
        log_share_result.action,
        log_share_result.activity_type,
        log_share_result.completed,
        log_share_result.error
    );
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
-- Name: twitter_bot_tweet; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.twitter_bot_tweet (
    id bigint NOT NULL,
    handle text NOT NULL,
    date_tweeted timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    article_id bigint,
    comment_id bigint,
    content text NOT NULL,
    tweet_id text NOT NULL,
    CONSTRAINT twitter_bot_tweet_reference CHECK (((article_id IS NOT NULL) OR (comment_id IS NOT NULL)))
);


--
-- Name: log_twitter_bot_tweet(text, bigint, bigint, text, text); Type: FUNCTION; Schema: analytics; Owner: -
--

CREATE FUNCTION analytics.log_twitter_bot_tweet(handle text, article_id bigint, comment_id bigint, content text, tweet_id text) RETURNS SETOF core.twitter_bot_tweet
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.twitter_bot_tweet (
            handle,
            article_id,
            comment_id,
            content,
            tweet_id
        )
    VALUES (
        log_twitter_bot_tweet.handle,
        log_twitter_bot_tweet.article_id,
        log_twitter_bot_tweet.comment_id,
        log_twitter_bot_tweet.content,
        log_twitter_bot_tweet.tweet_id
    )
    RETURNING
        *;
$$;


--
-- Name: article_author; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article_author (
    article_id bigint NOT NULL,
    author_id bigint NOT NULL,
    date_assigned timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_unassigned timestamp without time zone,
    assignment_method core.author_assignment_method DEFAULT 'metadata'::core.author_assignment_method NOT NULL,
    assigned_by_user_account_id bigint,
    unassigned_by_user_account_id bigint,
    CONSTRAINT article_author_manual_assignment_check CHECK (((assigned_by_user_account_id IS NOT NULL) OR (assignment_method <> 'manual'::core.author_assignment_method))),
    CONSTRAINT article_author_unassignment_check CHECK (((unassigned_by_user_account_id IS NOT NULL) OR (date_unassigned IS NULL)))
);


--
-- Name: assign_author_to_article(bigint, bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.assign_author_to_article(article_id bigint, author_id bigint, assigned_by_user_account_id bigint) RETURNS SETOF core.article_author
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.article_author (
			article_id,
			author_id,
			assignment_method,
			assigned_by_user_account_id
		)
	VALUES (
		assign_author_to_article.article_id,
		assign_author_to_article.author_id,
		'manual'::core.author_assignment_method,
		assign_author_to_article.assigned_by_user_account_id
	)
	ON CONFLICT
		(article_id, author_id)
	DO NOTHING
	RETURNING
		*;
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
    twitter_handle text,
    twitter_handle_assignment core.twitter_handle_assignment DEFAULT 'none'::core.twitter_handle_assignment NOT NULL,
    hostname_priority integer DEFAULT 0 NOT NULL
);


--
-- Name: assign_twitter_handle_to_source(bigint, text, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.assign_twitter_handle_to_source(source_id bigint, twitter_handle text, twitter_handle_assignment text) RETURNS SETOF core.source
    LANGUAGE sql
    AS $$
    UPDATE
        core.source
    SET
        twitter_handle = assign_twitter_handle_to_source.twitter_handle,
        twitter_handle_assignment = assign_twitter_handle_to_source.twitter_handle_assignment::core.twitter_handle_assignment
    WHERE
        source.id = assign_twitter_handle_to_source.source_id
    RETURNING
        *;
$$;


--
-- Name: create_article(text, text, bigint, timestamp without time zone, timestamp without time zone, text, text, article_api.author_metadata[], article_api.tag_metadata[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_article(title text, slug text, source_id bigint, date_published timestamp without time zone, date_modified timestamp without time zone, section text, description text, authors article_api.author_metadata[], tags article_api.tag_metadata[]) RETURNS bigint
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
-- Name: provisional_user_article; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.provisional_user_article (
    article_id bigint NOT NULL,
    provisional_user_account_id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    last_modified timestamp without time zone,
    read_state integer[] NOT NULL,
    words_read integer DEFAULT 0 NOT NULL,
    date_completed timestamp without time zone,
    readable_word_count integer NOT NULL,
    analytics jsonb,
    date_viewed timestamp without time zone
);


--
-- Name: create_provisional_user_article(bigint, bigint, integer, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_provisional_user_article(article_id bigint, provisional_user_account_id bigint, readable_word_count integer, analytics text) RETURNS core.provisional_user_article
    LANGUAGE sql
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


--
-- Name: create_provisional_user_article(bigint, bigint, integer, boolean, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_provisional_user_article(article_id bigint, provisional_user_account_id bigint, readable_word_count integer, mark_as_viewed boolean, analytics text) RETURNS core.provisional_user_article
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.provisional_user_article (
			article_id,
			provisional_user_account_id,
			read_state,
			readable_word_count,
			date_viewed,
			analytics
		)
	VALUES (
		create_provisional_user_article.article_id,
		create_provisional_user_article.provisional_user_account_id,
		ARRAY[-create_provisional_user_article.readable_word_count],
		create_provisional_user_article.readable_word_count,
		CASE WHEN
			create_provisional_user_article.mark_as_viewed
		THEN
			core.utc_now()
		ELSE
			NULL::timestamp
		END,
		create_provisional_user_article.analytics::jsonb
	)
	RETURNING
	    *;
$$;


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
    analytics jsonb,
    date_viewed timestamp without time zone,
    free_trial_credit_id bigint
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
-- Name: create_user_article(bigint, bigint, integer, boolean, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.create_user_article(article_id bigint, user_account_id bigint, readable_word_count integer, mark_as_viewed boolean, analytics text) RETURNS core.user_article
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	new_user_article core.user_article;
BEGIN
	-- Create the new user_article without setting date_viewed.
	INSERT INTO
		core.user_article (
			article_id,
			user_account_id,
			read_state,
			readable_word_count,
			analytics
		)
	VALUES (
		create_user_article.article_id,
		create_user_article.user_account_id,
		ARRAY[-create_user_article.readable_word_count],
		create_user_article.readable_word_count,
		create_user_article.analytics::jsonb
	)
	RETURNING
		*
	INTO
		locals.new_user_article;
	-- Try to mark as viewed if requested.
	IF
		create_user_article.mark_as_viewed
	THEN
		SELECT
			*
		INTO
			locals.new_user_article
		FROM
			articles.mark_user_article_as_viewed(
				user_article_id := locals.new_user_article.id
			);
	END IF;
	-- Return the user_article.
	RETURN
		locals.new_user_article;
END;
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
    LANGUAGE sql STABLE
    AS $$
	SELECT
        page.*
    FROM
        core.page
    WHERE
        page.url LIKE ('%' || trim(LEADING 'https' FROM find_page.url))
$$;


--
-- Name: find_source(text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.find_source(source_hostname text) RETURNS SETOF core.source
    LANGUAGE sql
    AS $$
	SELECT
		source.*
	FROM
		core.source
	WHERE
		regexp_replace(source.hostname, '^www\.', '') = find_source.source_hostname
	ORDER BY
		source.hostname_priority
	LIMIT
		1;
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
-- Name: get_article_for_provisional_user(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_article_for_provisional_user(article_id bigint, provisional_user_account_id bigint) RETURNS SETOF article_api.article
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
	    article.aotd_contender_rank,
	    coalesce(article_authors.authors, '{}')
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
-- Name: article_image; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article_image (
    article_id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    creator_user_id bigint NOT NULL,
    url text NOT NULL
);


--
-- Name: get_article_image(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_article_image(article_id bigint) RETURNS SETOF core.article_image
    LANGUAGE sql STABLE
    AS $$
    SELECT
        *
    FROM
        core.article_image
    WHERE
        article_image.article_id = get_article_image.article_id
    ORDER BY
        article_image.date_created DESC
    LIMIT
        1;
$$;


--
-- Name: get_articles(bigint[], bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_articles(article_ids bigint[], user_account_id bigint) RETURNS SETOF article_api.article
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
	FROM
		article_api.get_articles(get_articles.user_account_id, VARIADIC get_articles.article_ids);
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


--
-- Name: get_articles_by_author_slug(text, bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_articles_by_author_slug(slug text, user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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
		articles.*,
		(
			SELECT
				count(*)
			FROM
				author_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
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
			)
		) AS articles;
$$;


--
-- Name: get_articles_by_source_slug(text, bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_articles_by_source_slug(slug text, user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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
		articles.*,
		(
			SELECT
				count(*)
			FROM
				publisher_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
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
	      (coalesce(words_read, 0)::double precision / greatest(coalesce(readable_word_count, 0), 1)) * 100,
	      100
	   ),
	   0
	);
$$;


--
-- Name: get_provisional_user_article(bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_provisional_user_article(article_id bigint, provisional_user_account_id bigint) RETURNS SETOF core.provisional_user_article
    LANGUAGE sql STABLE
    AS $$
	SELECT
	    *
	FROM
	    core.provisional_user_article AS user_article
	WHERE
		user_article.article_id = get_provisional_user_article.article_id AND
		user_article.provisional_user_account_id = get_provisional_user_article.provisional_user_account_id;
$$;


--
-- Name: get_source_of_article(bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.get_source_of_article(article_id bigint) RETURNS SETOF core.source
    LANGUAGE sql STABLE
    AS $$
    SELECT
        source.*
    FROM
        core.article
        JOIN core.source ON
            source.id = article.source_id
    WHERE
        article.id = get_source_of_article.article_id;
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
-- Name: merge_tags(text, text[]); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.merge_tags(target_slug text, VARIADIC source_slugs text[]) RETURNS bigint[]
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


--
-- Name: score_articles(); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.score_articles() RETURNS void
    LANGUAGE sql
    AS $$
    WITH scorable_criteria AS (
        SELECT
            core.utc_now() - '1 month'::interval - ('10 minutes'::interval) AS cutoff_date
    ),
    scorable_article AS (
        SELECT DISTINCT
            article_id AS id
        FROM
            core.comment
        WHERE
            comment.date_created >= (SELECT cutoff_date FROM scorable_criteria)
        UNION
        SELECT DISTINCT
            article_id AS id
        FROM
            core.user_article
        WHERE
            user_article.date_completed >= (SELECT cutoff_date FROM scorable_criteria)
    ),
	scored_article AS (
		SELECT
			community_read.id,
		    community_read.aotd_timestamp,
			round(
			    (
                    (coalesce(scored_first_user_comment.hot_score, 0) + coalesce(scored_read.hot_score, 0)) *
                    (
                        CASE
                            WHEN community_read.word_count <= 184 THEN 0.15
                            WHEN community_read.word_count <= 368 THEN 0.25
                            ELSE (least(core.estimate_article_length(community_read.word_count), 30) + 4)::double precision / 7
                        END
                    ) *
                    (coalesce(community_read.average_rating_score, 5) / 5)
                ) /
			    (
                    CASE
                        -- divide articles by Bill Loundy (id # 49) and Jeff Camera (id # 216185) by 10
                        WHEN
                           49 = ANY(article_authors.author_ids) OR
                           216185 = ANY(article_authors.author_ids)
                        THEN 10
                        ELSE 1
                    END
                )
			) AS hot_score,
			round(
                (coalesce(scored_first_user_comment.count, 0) + coalesce(scored_read.count, 0)) *
                (
                    CASE
                        WHEN community_read.word_count <= 184 THEN 0.15
                        WHEN community_read.word_count <= 368 THEN 0.25
                        ELSE (least(core.estimate_article_length(community_read.word_count), 30) + 4)::double precision / 7
                    END
                ) *
                (coalesce(community_read.average_rating_score, 5) / 5)
			) AS top_score
		FROM
		    community_reads.community_read
		    JOIN scorable_article ON
		        scorable_article.id = community_read.id
		    LEFT JOIN (
		        SELECT
		            article_author.article_id,
		            array_agg(article_author.author_id) AS author_ids
		        FROM
		            core.article_author
		            JOIN scorable_article ON
		                scorable_article.id = article_author.article_id
		        WHERE
		            article_author.date_unassigned IS NULL
		        GROUP BY
		            article_author.article_id
            ) AS article_authors ON
                article_authors.article_id = community_read.id
			LEFT JOIN (
				SELECT
					count(first_user_comment.*) AS count,
					sum(
						CASE
							WHEN first_user_comment.age < '18 hours' THEN 400
							WHEN first_user_comment.age < '36 hours' THEN 200
							WHEN first_user_comment.age < '72 hours' THEN 150
							WHEN first_user_comment.age < '1 week' THEN 100
							WHEN first_user_comment.age < '2 weeks' THEN 50
							WHEN first_user_comment.age < '1 month' THEN 5
							ELSE 0
						END
					) AS hot_score,
					first_user_comment.article_id
				FROM (
					SELECT
						first_user_comment.article_id,
						utc_now() - first_user_comment.date_created AS age
					FROM
						core.comment AS first_user_comment
						JOIN scorable_article ON
						    scorable_article.id = first_user_comment.article_id
				    	LEFT JOIN core.comment AS earlier_user_comment ON (
				    		earlier_user_comment.article_id = first_user_comment.article_id AND
				    		earlier_user_comment.user_account_id = first_user_comment.user_account_id AND
				    		earlier_user_comment.date_created < first_user_comment.date_created
						)
				    WHERE
				    	earlier_user_comment.id IS NULL
				) AS first_user_comment
				GROUP BY
				    first_user_comment.article_id
			) AS scored_first_user_comment ON
			    scored_first_user_comment.article_id = community_read.id
			LEFT JOIN (
				SELECT
					count(read.*) AS count,
					sum(
						CASE
							WHEN read.age < '18 hours' THEN 350
							WHEN read.age < '36 hours' THEN 175
							WHEN read.age < '72 hours' THEN 125
							WHEN read.age < '1 week' THEN 75
							WHEN read.age < '2 weeks' THEN 25
							WHEN read.age < '1 month' THEN 5
							ELSE 0
						END
					) AS hot_score,
					read.article_id
				FROM (
					SELECT
						user_article.article_id,
						utc_now() - user_article.date_completed AS age
					FROM
					    core.user_article
                        JOIN scorable_article ON
                            scorable_article.id = user_article.article_id
					WHERE
					    user_article.date_completed IS NOT NULL
				) AS read
				GROUP BY
				    read.article_id
			) AS scored_read ON
			    scored_read.article_id = community_read.id
	),
    aotd_contender AS (
        SELECT
            scored_article.id,
            rank() OVER (ORDER BY scored_article.hot_score DESC) AS rank
        FROM
            scored_article
        WHERE
            scored_article.hot_score > 0 AND
            scored_article.aotd_timestamp IS NULL
    )
	UPDATE
	    core.article
	SET
		hot_score = scored_article.hot_score,
		top_score = scored_article.top_score,
	    aotd_contender_rank = coalesce(aotd_contender.rank, 0)
	FROM
	    scored_article
        LEFT JOIN aotd_contender ON
            scored_article.id = aotd_contender.id
	WHERE
	    scored_article.id = article.id;
$$;


--
-- Name: set_article_image(bigint, bigint, text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.set_article_image(article_id bigint, creator_user_id bigint, url text) RETURNS SETOF core.article_image
    LANGUAGE sql
    AS $$
    INSERT INTO core.article_image (
        article_id,
        creator_user_id,
        url
    )
    VALUES (
        set_article_image.article_id,
        set_article_image.creator_user_id,
        set_article_image.url
    )
    RETURNING
        *;
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
-- Name: unassign_author_from_article(bigint, bigint, bigint); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.unassign_author_from_article(article_id bigint, author_id bigint, unassigned_by_user_account_id bigint) RETURNS SETOF core.article_author
    LANGUAGE sql
    AS $$
	UPDATE
		core.article_author
	SET
		date_unassigned = core.utc_now(),
		unassigned_by_user_account_id = unassign_author_from_article.unassigned_by_user_account_id
	WHERE
		article_author.article_id = unassign_author_from_article.article_id AND
		article_author.author_id = unassign_author_from_article.author_id AND
		article_author.date_unassigned IS NULL
	RETURNING
		*;
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
-- Name: update_provisional_read_progress(bigint, bigint, integer[], text); Type: FUNCTION; Schema: article_api; Owner: -
--

CREATE FUNCTION article_api.update_provisional_read_progress(provisional_user_account_id bigint, article_id bigint, read_state integer[], analytics text) RETURNS core.provisional_user_article
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
-- Name: get_article_by_id(bigint, bigint); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_article_by_id(article_id bigint, user_account_id bigint) RETURNS SETOF articles.article
    LANGUAGE sql STABLE
    AS $$
	SELECT
		*
	FROM
		articles.get_articles(
			article_ids := ARRAY[get_article_by_id.article_id],
			user_account_id := get_article_by_id.user_account_id
		);
$$;


--
-- Name: get_article_by_slug(text, bigint); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_article_by_slug(slug text, user_account_id bigint) RETURNS SETOF articles.article
    LANGUAGE sql STABLE
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


--
-- Name: get_article_for_provisional_user(bigint, bigint); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_article_for_provisional_user(article_id bigint, provisional_user_account_id bigint) RETURNS SETOF articles.article
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


--
-- Name: get_article_history(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_article_history(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
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


--
-- Name: get_articles(bigint[], bigint); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_articles(article_ids bigint[], user_account_id bigint) RETURNS SETOF articles.article
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


--
-- Name: get_articles_by_author_slug(text, integer, integer, integer, integer); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_articles_by_author_slug(slug text, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
    LANGUAGE sql STABLE
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


--
-- Name: get_articles_by_source_slug(text, integer, integer, integer, integer); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_articles_by_source_slug(slug text, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
    LANGUAGE sql STABLE
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


--
-- Name: get_percent_complete(numeric, numeric); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_percent_complete(readable_word_count numeric, words_read numeric) RETURNS double precision
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
-- Name: get_starred_articles(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.get_starred_articles(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
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


--
-- Name: mark_user_article_as_viewed(bigint); Type: FUNCTION; Schema: articles; Owner: -
--

CREATE FUNCTION articles.mark_user_article_as_viewed(user_article_id bigint) RETURNS SETOF core.user_article
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	target_user_article core.user_article;
	article_view_free_credit core.free_trial_credit;
BEGIN
	-- Query, cache, and lock the user article.
	SELECT
		user_article.*
	INTO
		locals.target_user_article
	FROM
		core.user_article
	WHERE
		user_article.id = mark_user_article_as_viewed.user_article_id
	FOR UPDATE;
	-- Return immediately without updating if the article has already been marked as viewed.
	IF
		locals.target_user_article.date_viewed IS NOT NULL
	THEN
		RETURN NEXT
			locals.target_user_article;
		RETURN;
	END IF;
	-- Set date_viewed and return immediately if the user is allowed to view the article based on their subscription or
	-- free-for-life status.
	IF
		subscriptions.is_user_subscribed_or_free_for_life(
			user_account_id := locals.target_user_article.user_account_id
		) OR
		subscriptions.is_article_free_to_read(
			article_id := locals.target_user_article.article_id
		)
	THEN
		RETURN QUERY
		UPDATE
			core.user_article
		SET
			date_viewed = core.utc_now()
		WHERE
			user_article.id = locals.target_user_article.id
		RETURNING
			*;
		RETURN;
	END IF;
	-- Query, cache, and lock any available free view credits that the user might have.
	SELECT
		credit.*
	INTO
		locals.article_view_free_credit
	FROM
		core.free_trial_credit AS credit
	WHERE
		credit.user_account_id = locals.target_user_article.user_account_id AND
		credit.credit_type = 'article_view'::core.free_trial_credit_type AND
		credit.amount_remaining > 0
	ORDER BY
		credit.date_created
	LIMIT
		1
	FOR UPDATE;
	-- Check for available free view credits.
	IF
		NOT (locals.article_view_free_credit IS NULL)
	THEN
		-- Subtract one view from the available credit.
		UPDATE
			core.free_trial_credit
		SET
			amount_remaining = locals.article_view_free_credit.amount_remaining - 1
		WHERE
			free_trial_credit.id = locals.article_view_free_credit.id;
		-- Set date_viewed, reference the free_trial_credit that was utilized, and return immediately.
		RETURN QUERY
		UPDATE
			core.user_article
		SET
			date_viewed = core.utc_now(),
			free_trial_credit_id = locals.article_view_free_credit.id
		WHERE
			user_article.id = locals.target_user_article.id
		RETURNING
			*;
		RETURN;
	END IF;
	-- Return without updating if the user doesn't have any free article view credits to use.
	RETURN NEXT
		locals.target_user_article;
END;
$$;


--
-- Name: assign_contact_status_to_authors(authors.author_contact_status_assignment[]); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.assign_contact_status_to_authors(assignments authors.author_contact_status_assignment[]) RETURNS SETOF bigint
    LANGUAGE sql
    AS $$
	UPDATE
		core.author
	SET
		contact_status = assignment.contact_status::core.author_contact_status
	FROM
		unnest(assign_contact_status_to_authors.assignments) AS assignment (
			slug,
			contact_status
		)
	WHERE
		author.slug = assignment.slug AND
		author.contact_status != assignment.contact_status::core.author_contact_status
	RETURNING
		author.id;
$$;


--
-- Name: author; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.author (
    id bigint NOT NULL,
    name text NOT NULL,
    url text,
    twitter_handle text,
    twitter_handle_assignment core.twitter_handle_assignment DEFAULT 'none'::core.twitter_handle_assignment NOT NULL,
    slug text NOT NULL,
    email_address text,
    contact_status core.author_contact_status DEFAULT 'none'::core.author_contact_status NOT NULL
);


--
-- Name: author_user_account_assignment; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.author_user_account_assignment (
    id bigint NOT NULL,
    author_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    date_assigned timestamp without time zone NOT NULL
);


--
-- Name: author; Type: VIEW; Schema: authors; Owner: -
--

CREATE VIEW authors.author AS
 SELECT author.id,
    author.name,
    author.url,
    author.twitter_handle,
    author.twitter_handle_assignment,
    author.slug,
    author.email_address,
    assignment.user_account_id
   FROM (core.author
     LEFT JOIN core.author_user_account_assignment assignment ON ((author.id = assignment.author_id)));


--
-- Name: assign_twitter_handle_to_author(bigint, text, text); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.assign_twitter_handle_to_author(author_id bigint, twitter_handle text, twitter_handle_assignment text) RETURNS SETOF authors.author
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- update the author
    UPDATE
        core.author
    SET
        twitter_handle = assign_twitter_handle_to_author.twitter_handle,
        twitter_handle_assignment = assign_twitter_handle_to_author.twitter_handle_assignment::core.twitter_handle_assignment
    WHERE
        author.id = assign_twitter_handle_to_author.author_id;
	-- return from view
	RETURN QUERY
	SELECT
		*
	FROM
		authors.author
	WHERE
		author.id = assign_twitter_handle_to_author.author_id;
END;
$$;


--
-- Name: assign_user_account_to_author(bigint, bigint); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.assign_user_account_to_author(author_id bigint, user_account_id bigint) RETURNS SETOF authors.author
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- Create the assignment.
	INSERT INTO
		core.author_user_account_assignment (
			author_id,
			user_account_id,
			date_assigned
		)
	VALUES (
		assign_user_account_to_author.author_id,
		assign_user_account_to_author.user_account_id,
		core.utc_now()
	);
	-- Return from view.
	RETURN QUERY
	SELECT
		*
	FROM
		authors.author
	WHERE
		author.id = assign_user_account_to_author.author_id;
END;
$$;


--
-- Name: create_author(text, text); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.create_author(name text, slug text) RETURNS SETOF authors.author
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO
		core.author (
			name,
			slug
		)
	VALUES (
		create_author.name,
		create_author.slug
	);
	RETURN QUERY
	SELECT
		author.*
	FROM
		authors.author
	WHERE
		author.slug = create_author.slug;
END;
$$;


--
-- Name: get_author(text); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.get_author(slug text) RETURNS SETOF authors.author
    LANGUAGE sql STABLE
    AS $$
    SELECT
        author.*
    FROM
        authors.author
    WHERE
        author.slug = get_author.slug;
$$;


--
-- Name: get_author_by_user_account_name(text); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.get_author_by_user_account_name(user_account_name text) RETURNS SETOF authors.author
    LANGUAGE sql STABLE
    AS $$
	SELECT
		author.*
	FROM
		authors.author
	WHERE
		author.id = (
			SELECT
				assignment.author_id
			FROM
				core.author_user_account_assignment AS assignment
				JOIN
					core.user_account ON
						assignment.user_account_id = user_account.id
			WHERE
				user_account.name = get_author_by_user_account_name.user_account_name
		);
$$;


--
-- Name: get_authors_of_article(bigint); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.get_authors_of_article(article_id bigint) RETURNS SETOF authors.author
    LANGUAGE sql STABLE
    AS $$
    SELECT
        author.*
    FROM
        core.article_author
        JOIN authors.author ON
            author.id = article_author.author_id
    WHERE
        article_author.article_id = get_authors_of_article.article_id AND
        article_author.date_unassigned IS NULL;
$$;


--
-- Name: user_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.user_account (
    id bigint NOT NULL,
    name character varying(30) NOT NULL,
    email character varying(256) NOT NULL,
    password_hash bytea,
    password_salt bytea,
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
    has_linked_twitter_account boolean DEFAULT false NOT NULL,
    date_deleted timestamp without time zone,
    date_orientation_completed timestamp without time zone,
    subscription_end_date timestamp without time zone,
    CONSTRAINT user_account_email_valid CHECK ((((email)::text ~~ '%@%'::text) OR (((email)::text ~ similar_escape('\[deleted\_[0-9]+\]'::text, NULL::text)) AND (date_deleted IS NOT NULL)))),
    CONSTRAINT user_account_name_valid CHECK ((((name)::text ~ similar_escape('[A-Za-z0-9\-_]+'::text, NULL::text)) OR (((name)::text ~ similar_escape('\[deleted\_[0-9]+\]'::text, NULL::text)) AND (date_deleted IS NOT NULL))))
);


--
-- Name: get_user_account_by_author_slug(text); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.get_user_account_by_author_slug(author_slug text) RETURNS SETOF core.user_account
    LANGUAGE sql STABLE
    AS $$
	SELECT
		user_account.*
	FROM
		core.user_account
	WHERE
		user_account.id = (
			SELECT
				assignment.user_account_id
			FROM
				core.author_user_account_assignment AS assignment
				JOIN
					core.author ON
						assignment.author_id = author.id
			WHERE
				author.slug = get_user_account_by_author_slug.author_slug
		);
$$;


--
-- Name: run_wrm_sync_report(integer, integer); Type: FUNCTION; Schema: authors; Owner: -
--

CREATE FUNCTION authors.run_wrm_sync_report(min_amount_earned integer, max_amount_earned integer) RETURNS TABLE(author_name text, author_slug text, author_contact_status core.author_contact_status, top_source text, user_account_name text, user_account_email text, amount_earned integer, amount_paid integer, amount_donated integer)
    LANGUAGE sql STABLE
    AS $$
	WITH earnings_report AS (
		SELECT
			earnings_report.*
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := run_wrm_sync_report.min_amount_earned,
				max_amount_earned := run_wrm_sync_report.max_amount_earned
			) AS earnings_report (
				author_id,
				amount_earned
			)
	),
	author_with_earnings AS (
		SELECT
			author.id AS author_id,
			author.name AS author_name,
			author.slug AS author_slug,
			author.contact_status AS author_contact_status,
			user_account.id AS user_account_id,
			user_account.name AS user_account_name,
			user_account.email AS user_account_email,
			earnings_report.amount_earned
		FROM
			earnings_report
			JOIN
				core.author ON
					earnings_report.author_id = author.id
			LEFT JOIN
				core.author_user_account_assignment AS user_account_assignment ON
					author.id = user_account_assignment.author_id
			LEFT JOIN
				core.user_account ON
					user_account_assignment.user_account_id = user_account.id
	),
	top_source AS (
		SELECT
			DISTINCT ON (
				author_source_stats.author_id
			)
			author_source_stats.author_id,
			author_source_stats.source_name
		FROM
			(
				SELECT
					author_with_earnings.author_id,
					source.name AS source_name,
					count(*) AS article_count
				FROM
					author_with_earnings
					JOIN
						core.article_author ON
							author_with_earnings.author_id = article_author.author_id
					JOIN
						core.article ON
							article_author.article_id = article.id
					JOIN
						core.source ON
							article.source_id = source.id
				GROUP BY
					author_with_earnings.author_id,
					source.id
			) AS author_source_stats
		ORDER BY
			author_source_stats.author_id,
			author_source_stats.article_count DESC
	),
	author_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(author_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.payout_account ON
					author_with_earnings.user_account_id = payout_account.user_account_id
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
		GROUP BY
			author_with_earnings.author_id
	),
	donation_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(donation_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.donation_account ON
					author_with_earnings.author_id = donation_account.author_id OR
					author_with_earnings.user_account_id = donation_account.user_account_id
			JOIN
				core.donation_payout ON
					donation_account.id = donation_payout.donation_account_id
		GROUP BY
			author_with_earnings.author_id
	)
	SELECT
		author_with_earnings.author_name,
		author_with_earnings.author_slug,
		author_with_earnings.author_contact_status,
		trim(top_source.source_name),
		author_with_earnings.user_account_name,
		author_with_earnings.user_account_email,
		author_with_earnings.amount_earned,
		coalesce(author_payouts.payout_total::int, 0),
		coalesce(donation_payouts.payout_total::int, 0)
	FROM
		author_with_earnings
		JOIN
			top_source ON
				author_with_earnings.author_id = top_source.author_id
		LEFT JOIN
			author_payouts ON
				author_with_earnings.author_id = author_payouts.author_id
		LEFT JOIN
			donation_payouts ON
				author_with_earnings.author_id = donation_payouts.author_id
$$;


--
-- Name: get_aotd_history(integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_aotd_history(page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
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
-- Name: get_aotds(integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_aotds(day_count integer) RETURNS SETOF bigint
    LANGUAGE sql STABLE
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
-- Name: get_hot(integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_hot(page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
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
-- Name: get_new_aotd_contenders(integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_new_aotd_contenders(page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
    LANGUAGE sql STABLE
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


--
-- Name: get_new_aotd_contenders(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_new_aotd_contenders(user_account_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_search_options(); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_search_options() RETURNS TABLE(category text, name text, slug text, score bigint)
    LANGUAGE sql STABLE
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


--
-- Name: get_top(integer, integer, integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.get_top(page_number integer, page_size integer, min_length integer, max_length integer) RETURNS articles.article_ids_page
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
-- Name: search_articles(integer, integer, text[], text[], text[], integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.search_articles(page_number integer, page_size integer, source_slugs text[], author_slugs text[], tag_slugs text[], min_length integer, max_length integer) RETURNS articles.article_ids_page
    LANGUAGE sql STABLE
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


--
-- Name: search_articles(bigint, integer, integer, text[], text[], text[], integer, integer); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.search_articles(user_account_id bigint, page_number integer, page_size integer, source_slugs text[], author_slugs text[], tag_slugs text[], min_length integer, max_length integer) RETURNS SETOF article_api.article_page_result
    LANGUAGE sql STABLE
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
-- Name: set_aotd_v1(); Type: FUNCTION; Schema: community_reads; Owner: -
--

CREATE FUNCTION community_reads.set_aotd_v1() RETURNS bigint
    LANGUAGE sql
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
    via_push boolean DEFAULT false NOT NULL,
    event_type core.notification_event_type NOT NULL
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
				via_push,
				event_type
			)
		SELECT
			(SELECT id FROM aotd_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    'aotd_digest'::core.notification_event_type
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
				via_push,
				event_type
			)
		(
			SELECT
				locals.event_id,
				preference.user_account_id,
				preference.aotd_via_email,
				preference.aotd_via_extension,
				preference.aotd_via_push,
				'aotd'::core.notification_event_type
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
				via_push,
				event_type
			)
		SELECT
			(SELECT id FROM update_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    'company_update'::core.notification_event_type
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
-- Name: create_company_update_notifications(bigint, text, text, text, boolean); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_company_update_notifications(author_id bigint, subject text, body text, subscription_status_filter text, free_for_life_filter boolean) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
	WITH recipient AS (
		SELECT
			user_account.id AS user_account_id
		FROM
			core.user_account
			JOIN
				notifications.current_preference ON
					user_account.id = current_preference.user_account_id
			LEFT JOIN
				core.subscription_account ON
					user_account.id = subscription_account.user_account_id
			LEFT JOIN
				core.subscription ON
					subscription_account.provider = subscription.provider AND
					subscription_account.provider_account_id = subscription.provider_account_id
			LEFT JOIN
				core.subscription_period ON
					subscription.provider = subscription_period.provider AND
					subscription.provider_subscription_id = subscription_period.provider_subscription_id
		WHERE
			current_preference.company_update_via_email AND
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			WHEN
				'not_currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				NOT subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			ELSE
				TRUE
			END AND
			CASE
				create_company_update_notifications.free_for_life_filter
			WHEN
				TRUE
			THEN
				subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			WHEN
				FALSE
			THEN
				NOT subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			ELSE
				TRUE
			END
		GROUP BY
			user_account.id
		HAVING
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'never_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				every(subscription_period.payment_status IS DISTINCT FROM 'succeeded'::core.subscription_payment_status)
			ELSE
				TRUE
			END
	),
	update_event AS (
		INSERT INTO
			core.notification_event (
				type,
				bulk_email_author_id,
				bulk_email_subject,
				bulk_email_body,
				bulk_email_subscription_status_filter,
				bulk_email_free_for_life_filter
			)
		SELECT
			'company_update',
			create_company_update_notifications.author_id,
			create_company_update_notifications.subject,
			create_company_update_notifications.body,
			create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter,
			create_company_update_notifications.free_for_life_filter
		FROM
			recipient
		LIMIT
			1
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
				via_push,
				event_type
			)
		SELECT
			(
				SELECT
					update_event.id
				FROM
					update_event
			),
			recipient.user_account_id,
			TRUE,
			FALSE,
			FALSE,
			'company_update'::core.notification_event_type
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
		JOIN
			core.user_account ON
				user_account.id = receipt.user_account_id;
$$;


--
-- Name: create_company_update_notifications(bigint, text, text, text, boolean, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.create_company_update_notifications(author_id bigint, subject text, body text, subscription_status_filter text, free_for_life_filter boolean, user_created_after_filter timestamp without time zone, user_created_before_filter timestamp without time zone) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
	WITH recipient AS (
		SELECT
			user_account.id AS user_account_id
		FROM
			core.user_account
			JOIN
				notifications.current_preference ON
					user_account.id = current_preference.user_account_id
			LEFT JOIN
				core.subscription_account ON
					user_account.id = subscription_account.user_account_id
			LEFT JOIN
				core.subscription ON
					subscription_account.provider = subscription.provider AND
					subscription_account.provider_account_id = subscription.provider_account_id
			LEFT JOIN
				core.subscription_period ON
					subscription.provider = subscription_period.provider AND
					subscription.provider_subscription_id = subscription_period.provider_subscription_id
		WHERE
			current_preference.company_update_via_email AND
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			WHEN
				'not_currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				NOT subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			ELSE
				TRUE
			END AND
			CASE
				create_company_update_notifications.free_for_life_filter
			WHEN
				TRUE
			THEN
				subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			WHEN
				FALSE
			THEN
				NOT subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			ELSE
				TRUE
			END AND
			CASE WHEN
				create_company_update_notifications.user_created_after_filter IS NOT NULL
			THEN
				user_account.date_created >= create_company_update_notifications.user_created_after_filter
			ELSE
				TRUE
			END AND
			CASE WHEN
				create_company_update_notifications.user_created_before_filter IS NOT NULL
			THEN
				user_account.date_created < create_company_update_notifications.user_created_before_filter
			ELSE
				TRUE
			END
		GROUP BY
			user_account.id
		HAVING
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'never_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				every(subscription_period.payment_status IS DISTINCT FROM 'succeeded'::core.subscription_payment_status)
			ELSE
				TRUE
			END
	),
	update_event AS (
		INSERT INTO
			core.notification_event (
				type,
				bulk_email_author_id,
				bulk_email_subject,
				bulk_email_body,
				bulk_email_subscription_status_filter,
				bulk_email_free_for_life_filter,
				bulk_email_user_created_after_filter,
				bulk_email_user_created_before_filter
			)
		SELECT
			'company_update',
			create_company_update_notifications.author_id,
			create_company_update_notifications.subject,
			create_company_update_notifications.body,
			create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter,
			create_company_update_notifications.free_for_life_filter,
			create_company_update_notifications.user_created_after_filter,
			create_company_update_notifications.user_created_before_filter
		FROM
			recipient
		LIMIT
			1
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
				via_push,
				event_type
			)
		SELECT
			(
				SELECT
					update_event.id
				FROM
					update_event
			),
			recipient.user_account_id,
			TRUE,
			FALSE,
			FALSE,
			'company_update'::core.notification_event_type
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
		JOIN
			core.user_account ON
				user_account.id = receipt.user_account_id;
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_follower_digest_notifications.frequency
				WHEN 'daily' THEN 'follower_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'follower_weekly_digest'::core.notification_event_type
			END
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
					via_push,
					event_type
				)
			(
				SELECT
					locals.event_id,
					create_follower_notification.followee_id,
					preference.follower_via_email,
					preference.follower_via_extension,
					preference.follower_via_push,
					'follower'::core.notification_event_type
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_loopback_digest_notifications.frequency
				WHEN 'daily' THEN 'loopback_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'loopback_weekly_digest'::core.notification_event_type
			END
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
				via_push,
				event_type
			)
		(
			SELECT
				(SELECT id FROM loopback_event),
				recipient.user_account_id,
				recipient.loopback_via_email,
				recipient.loopback_via_extension,
				recipient.loopback_via_push,
				'loopback'::core.notification_event_type
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
				via_push,
				event_type
			)
		(
			SELECT
				(SELECT id FROM post_event),
				recipient.user_account_id,
				recipient.post_via_email,
				recipient.post_via_extension,
				recipient.post_via_push,
				'post'::core.notification_event_type
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_reply_digest_notifications.frequency
				WHEN 'daily' THEN 'reply_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'reply_weekly_digest'::core.notification_event_type
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
					via_push,
					event_type
				)
			(
				SELECT
					locals.event_id,
					locals.parent_author_id,
					preference.reply_via_email,
					preference.reply_via_extension,
					preference.reply_via_push,
					'reply'::core.notification_event_type
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
		SELECT
			transactional_event.id,
			create_transactional_notification.email_confirmation_id,
			create_transactional_notification.password_reset_request_id
		FROM
			transactional_event
    	WHERE
    		create_transactional_notification.email_confirmation_id IS NOT NULL OR
    		create_transactional_notification.password_reset_request_id IS NOT NULL
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
			(SELECT id FROM transactional_event),
		    create_transactional_notification.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    create_transactional_notification.event_type::core.notification_event_type
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
	SELECT DISTINCT
		lower(
			recipient->>'email_address'
		)
	FROM (
		SELECT
			jsonb_array_elements(
				notification.complaint->'complained_recipients'
			)
		FROM
			core.email_notification AS notification
		WHERE
			notification.complaint != 'null'
		UNION ALL
		SELECT
			jsonb_array_elements(
				notification.bounce->'bounced_recipients'
			)
		FROM
			core.email_notification AS notification
		WHERE
			notification.bounce != 'null' AND
			(
				notification.bounce->>'bounce_type' IS NULL OR
				NOT (
					notification.bounce->>'bounce_type' = 'Transient' AND
					notification.bounce->>'bounce_sub_type' = 'General' AND
					(
						(
							notification.bounce->'bounced_recipients'->0->>'action' IS NULL OR
							notification.bounce->'bounced_recipients'->0->>'status' IS NULL OR
							notification.bounce->'bounced_recipients'->0->>'diagnostic_code' IS NULL
						) OR
						(
							notification.bounce->'bounced_recipients'->0->>'email_address' ILIKE '%@privaterelay.appleid.com%' AND
							notification.bounce->'bounced_recipients'->0->>'diagnostic_code' ILIKE '%relay not allowed%'
						)
					)
				)
			)
	) AS report (
		recipient
	);
$$;


--
-- Name: get_bulk_mailings(); Type: FUNCTION; Schema: notifications; Owner: -
--

CREATE FUNCTION notifications.get_bulk_mailings() RETURNS TABLE(id bigint, date_sent timestamp without time zone, subject text, body text, type core.notification_event_type, subscription_status_filter notifications.bulk_email_subscription_status_filter, free_for_life_filter boolean, user_created_after_filter timestamp without time zone, user_created_before_filter timestamp without time zone, user_account text, recipient_count bigint)
    LANGUAGE sql
    AS $$
	SELECT
		event.id,
		event.date_created,
		event.bulk_email_subject,
		event.bulk_email_body,
		event.type,
		event.bulk_email_subscription_status_filter,
		event.bulk_email_free_for_life_filter,
		event.bulk_email_user_created_after_filter,
		event.bulk_email_user_created_before_filter,
		user_account.name AS user_account,
		count(*) AS recipient_count
	FROM
		core.notification_event AS event
		JOIN
			core.user_account ON
				event.bulk_email_author_id = core.user_account.id
		JOIN
			core.notification_receipt ON
				event.id = notification_receipt.event_id
	GROUP BY
		event.id,
		user_account.id;
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
	existing_device notifications.registered_push_device;
BEGIN
	-- check for existing registered device with matching installation_id
	SELECT
		*
	INTO
		locals.existing_device
	FROM
		notifications.registered_push_device AS device
	WHERE
		device.installation_id = register_push_device.installation_id
	FOR UPDATE;
	-- create a new registration if needed
	IF
		locals.existing_device IS NULL OR
		locals.existing_device.user_account_id != register_push_device.user_account_id OR
		locals.existing_device.token != register_push_device.token
	THEN
		-- unregister the existing device if the user or token has changed
		IF
		   locals.existing_device.id IS NOT NULL
		THEN
		   PERFORM
		   	notifications.unregister_push_device_by_installation_id(
		   	   installation_id => locals.existing_device.installation_id,
		   	   reason => (
		   	      CASE WHEN
							locals.existing_device.user_account_id != register_push_device.user_account_id
						THEN
							'user_change'
						ELSE
							'token_change'
						END
					)
		   	);
		END IF;
		-- unregister any other currently registered devices using the same token
		PERFORM
			notifications.unregister_push_device_by_token(
				token => register_push_device.token,
			   reason => 'reinstall'
			);
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
		RETURNING
			*;
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
    analytics jsonb NOT NULL,
    date_deleted timestamp without time zone
);


--
-- Name: create_silent_post(bigint, bigint, text); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.create_silent_post(user_account_id bigint, article_id bigint, analytics text) RETURNS SETOF core.silent_post
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
-- Name: get_notification_posts(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_notification_posts(user_id bigint, page_number integer, page_size integer) RETURNS SETOF social.article_post_page_result
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


--
-- Name: get_notification_posts_v1(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_notification_posts_v1(user_id bigint, page_number integer, page_size integer) RETURNS social.post_references_page
    LANGUAGE sql STABLE
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
		coalesce(
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
			ARRAY[]::social.post_reference[]
		),
		(
			SELECT
				count(notification_post.*)::int
			FROM
				notification_post
		);
$$;


--
-- Name: get_posts(social.post_reference[], bigint, text[]); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts(post_references social.post_reference[], user_account_id bigint, alert_event_types text[]) RETURNS SETOF social.post
    LANGUAGE plpgsql STABLE
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


--
-- Name: get_posts_from_followees_v1(bigint, integer, integer, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_followees_v1(user_id bigint, page_number integer, page_size integer, min_length integer, max_length integer) RETURNS social.post_references_page
    LANGUAGE sql STABLE
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
		coalesce(
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
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        followee_post
		)
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
-- Name: get_posts_from_inbox_v1(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_inbox_v1(user_id bigint, page_number integer, page_size integer) RETURNS social.post_references_page
    LANGUAGE sql STABLE
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
		coalesce(
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
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        inbox_comment
		);
$$;


--
-- Name: get_posts_from_user(text, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_posts_from_user(subject_user_name text, page_size integer, page_number integer) RETURNS social.post_references_page
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
		coalesce(
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
			ARRAY[]::social.post_reference[]
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
-- Name: get_reply_posts(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_reply_posts(user_id bigint, page_number integer, page_size integer) RETURNS SETOF social.article_post_page_result
    LANGUAGE sql STABLE
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


--
-- Name: get_reply_posts_v1(bigint, integer, integer); Type: FUNCTION; Schema: social; Owner: -
--

CREATE FUNCTION social.get_reply_posts_v1(user_id bigint, page_number integer, page_size integer) RETURNS social.post_references_page
    LANGUAGE sql STABLE
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
		coalesce(
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
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(reply.*)::int
		    FROM
		        reply
		);
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
							local_to_utc_timestamp(local_timestamp - '1 day'::interval, (SELECT name FROM user_time_zone)),
							local_to_utc_timestamp(local_timestamp, (SELECT name FROM user_time_zone))
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
-- Name: get_top_author_leaderboard(integer, integer); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_top_author_leaderboard(min_amount_earned integer, max_amount_earned integer) RETURNS TABLE(author_id bigint, author_name text, author_slug text, author_contact_status core.author_contact_status, user_account_id bigint, user_account_name text, donation_recipient_id bigint, donation_recipient_name text, minutes_read integer, top_article_id bigint, amount_earned integer, amount_paid integer)
    LANGUAGE sql STABLE
    AS $$
	WITH earnings_report AS (
		SELECT
			earnings_report.*
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := get_top_author_leaderboard.min_amount_earned,
				max_amount_earned := get_top_author_leaderboard.max_amount_earned
			) AS earnings_report (
				author_id,
				amount_earned
			)
	),
	author_with_earnings AS (
		SELECT
			author.id AS author_id,
			author.name AS author_name,
			author.slug AS author_slug,
			author.contact_status AS author_contact_status,
			user_account.id AS user_account_id,
			user_account.name AS user_account_name,
			earnings_report.amount_earned
		FROM
			earnings_report
			JOIN
				core.author ON
					earnings_report.author_id = author.id
			LEFT JOIN
				core.author_user_account_assignment AS user_account_assignment ON
					author.id = user_account_assignment.author_id
			LEFT JOIN
				core.user_account ON
					user_account_assignment.user_account_id = user_account.id
	),
	author_reading_time AS (
		SELECT
			author_with_earnings.author_id,
			core.estimate_reading_time(
				word_count := sum(article.word_count)
			) AS total_minutes_read
		FROM
			author_with_earnings
			JOIN
				core.article_author ON
					author_with_earnings.author_id = article_author.author_id
			JOIN
				core.user_article ON
					article_author.article_id = user_article.article_id AND
					user_article.date_completed IS NOT NULL
			JOIN
				core.article ON
					user_article.article_id = article.id
		GROUP BY
			author_with_earnings.author_id
	),
	author_top_article AS (
		SELECT
			DISTINCT ON (
				article_author.author_id
			)
			article_author.author_id,
			article.id AS top_article_id
		FROM
			author_with_earnings
			JOIN
				core.article_author ON
					author_with_earnings.author_id = article_author.author_id
			JOIN
				core.article ON
					article_author.article_id = article.id
		ORDER BY
			article_author.author_id,
			article.top_score DESC,
			article.id DESC
	),
	author_payouts AS (
		SELECT
			author_with_earnings.author_id,
			sum(author_payout.amount) AS payout_total
		FROM
			author_with_earnings
			JOIN
				core.payout_account ON
					author_with_earnings.user_account_id = payout_account.user_account_id
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
		GROUP BY
			author_with_earnings.author_id
	)
	SELECT
		author_with_earnings.author_id,
		author_with_earnings.author_name,
		author_with_earnings.author_slug,
		author_with_earnings.author_contact_status,
		author_with_earnings.user_account_id,
		author_with_earnings.user_account_name,
		donation_recipient.id,
		donation_recipient.name,
		author_reading_time.total_minutes_read::int,
		author_top_article.top_article_id,
		author_with_earnings.amount_earned,
		author_payouts.payout_total::int
	FROM
		author_with_earnings
		JOIN
			author_reading_time ON
				author_with_earnings.author_id = author_reading_time.author_id
		JOIN
			author_top_article ON
				author_with_earnings.author_id = author_top_article.author_id
		LEFT JOIN
			author_payouts ON
				author_with_earnings.author_id = author_payouts.author_id
		LEFT JOIN
			core.donation_account ON
				author_with_earnings.author_id = donation_account.author_id OR
				author_with_earnings.user_account_id = donation_account.user_account_id
		LEFT JOIN
			core.donation_recipient ON
				donation_account.donation_recipient_id = donation_recipient.id
$$;


--
-- Name: get_top_author_leaderboard(integer, timestamp without time zone); Type: FUNCTION; Schema: stats; Owner: -
--

CREATE FUNCTION stats.get_top_author_leaderboard(max_rank integer, since_date timestamp without time zone) RETURNS TABLE(name text, slug text, score integer, rank integer)
    LANGUAGE sql STABLE
    AS $$
    WITH ranking AS (
        SELECT
            author.name,
            author.slug,
            core.estimate_reading_time(
                sum(community_read.word_count)
            ) AS score,
            dense_rank() OVER (
                ORDER BY sum(community_read.word_count) DESC
            )::int AS rank
        FROM
            core.user_article
            JOIN community_reads.community_read ON
                community_read.id = user_article.article_id
            JOIN core.article_author ON
                article_author.article_id = user_article.article_id
            JOIN core.author ON
                author.id = article_author.author_id
        WHERE
            CASE WHEN get_top_author_leaderboard.since_date IS NOT NULL
                THEN user_article.date_completed >= get_top_author_leaderboard.since_date
                ELSE user_article.date_completed IS NOT NULL
            END AND
            article_author.date_unassigned IS NULL
        GROUP BY
            author.id
    )
    SELECT
        ranking.name,
        ranking.slug,
        ranking.score,
        ranking.rank
    FROM
        ranking
    WHERE
        ranking.rank <= get_top_author_leaderboard.max_rank
    ORDER BY
        ranking.rank,
        ranking.name;
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
-- Name: subscription_payment_method; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_payment_method (
    provider core.subscription_provider NOT NULL,
    provider_payment_method_id text NOT NULL,
    provider_account_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    wallet core.subscription_payment_method_wallet NOT NULL,
    brand core.subscription_payment_method_brand NOT NULL,
    last_four_digits character(4) NOT NULL,
    country core.iso_alpha_2_country_code NOT NULL,
    current_version_date timestamp without time zone NOT NULL,
    CONSTRAINT subscription_payment_method_last_four_digits_pattern_check CHECK ((last_four_digits ~ similar_escape('[0-9]{4}'::text, NULL::text)))
);


--
-- Name: subscription_payment_method_version; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_payment_method_version (
    provider core.subscription_provider NOT NULL,
    provider_payment_method_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    event_source core.subscription_event_source NOT NULL,
    expiration_month core.calendar_month NOT NULL,
    expiration_year core.calendar_year NOT NULL
);


--
-- Name: current_payment_method; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.current_payment_method AS
 SELECT method.provider,
    method.provider_payment_method_id,
    method.provider_account_id,
    method.date_created,
    method.wallet,
    method.brand,
    method.last_four_digits,
    method.country,
    current_version.expiration_month,
    current_version.expiration_year
   FROM (core.subscription_payment_method method
     JOIN core.subscription_payment_method_version current_version ON (((method.provider = current_version.provider) AND (method.provider_payment_method_id = current_version.provider_payment_method_id) AND (method.current_version_date = current_version.date_created))));


--
-- Name: assign_default_payment_method(text, text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.assign_default_payment_method(provider text, provider_account_id text, provider_payment_method_id text) RETURNS SETOF subscriptions.current_payment_method
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	current_default_payment_method_id CONSTANT text := (
	   SELECT
	   	default_method.provider_payment_method_id
	   FROM
	   	subscriptions.current_default_payment_method AS default_method
	   WHERE
	   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	      default_method.provider_account_id = assign_default_payment_method.provider_account_id
	   FOR UPDATE
	);
BEGIN
   IF
      locals.current_default_payment_method_id IS NOT NULL AND
	   locals.current_default_payment_method_id != assign_default_payment_method.provider_payment_method_id
	THEN
	   UPDATE
	      core.subscription_default_payment_method AS default_method
	   SET
	      date_unassigned = core.utc_now()
	   WHERE
	   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	      default_method.provider_account_id = assign_default_payment_method.provider_account_id AND
	      default_method.date_unassigned IS NULL;
	END IF;
	IF
	   locals.current_default_payment_method_id IS NULL OR
	   locals.current_default_payment_method_id != assign_default_payment_method.provider_payment_method_id
	THEN
		INSERT INTO
		   core.subscription_default_payment_method (
		   	provider,
		   	provider_account_id,
		   	date_assigned,
		   	provider_payment_method_id
		   )
		VALUES (
			assign_default_payment_method.provider::core.subscription_provider,
			assign_default_payment_method.provider_account_id,
			core.utc_now(),
			assign_default_payment_method.provider_payment_method_id
		);
	END IF;
   RETURN QUERY
   SELECT
   	default_method.*
   FROM
      subscriptions.current_default_payment_method AS default_method
   WHERE
   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	   default_method.provider_account_id = assign_default_payment_method.provider_account_id;
END;
$$;


--
-- Name: calculate_allocation_for_all_periods(); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.calculate_allocation_for_all_periods() RETURNS subscriptions.subscription_allocation_calculation
    LANGUAGE sql STABLE
    AS $$
	WITH allocation AS (
		SELECT
			(
				subscriptions.calculate_allocation_for_period(
					provider := period.provider,
					subscription_amount := coalesce(
						period.prorated_price_amount,
						price_level.amount
					),
					payment_method_country := payment_method.country
				)
			).*
		FROM
			core.subscription_period AS period
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
			JOIN
				subscriptions.price_level ON
					period.provider = price_level.provider AND
					period.provider_price_id = price_level.provider_price_id
			LEFT JOIN
				core.subscription_payment_method AS payment_method ON
					period.provider = payment_method.provider AND
					period.provider_payment_method_id = payment_method.provider_payment_method_id
		WHERE
			period.payment_status = 'succeeded'::core.subscription_payment_status AND
			period.date_refunded IS NULL AND
			account.environment = 'production'::core.subscription_environment
	)
	SELECT
		sum(allocation.platform_amount)::int,
		sum(allocation.provider_amount)::int,
		sum(allocation.author_amount)::int
	FROM
		allocation;
$$;


--
-- Name: calculate_allocation_for_period(core.subscription_provider, integer, core.iso_alpha_2_country_code); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.calculate_allocation_for_period(provider core.subscription_provider, subscription_amount integer, payment_method_country core.iso_alpha_2_country_code) RETURNS subscriptions.subscription_allocation_calculation
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
<<locals>>
DECLARE
	provider_amount int;
	platform_amount int;
	author_amount int;
BEGIN
	-- calculate the payment provider fee amount
	locals.provider_amount := least(
		CASE
			calculate_allocation_for_period.provider
		WHEN
			'apple'::core.subscription_provider
		THEN
			-- app store small business program 15% commission
			round(calculate_allocation_for_period.subscription_amount * 0.15)
		WHEN
			'stripe'::core.subscription_provider
		THEN
			-- payments percentage-based commission
			round(
				calculate_allocation_for_period.subscription_amount * (
					-- base 2.9% commission
					0.029 +
					-- international 1% commission
					CASE
						WHEN
							calculate_allocation_for_period.payment_method_country != 'US'::core.iso_alpha_2_country_code
						THEN
							0.01
						ELSE
							0
					END
				)
			) +
			-- payments flat-rate $0.30 commission
			30 +
			-- billing 0.5% commission (applied separately from payments commission so needs to be rounded separately)
			round(calculate_allocation_for_period.subscription_amount * 0.005)
		END,
		-- prorated subscriptions could potentially be less than the flat-rate commission
		calculate_allocation_for_period.subscription_amount
	);
	-- calculate the platform fee amount
	locals.platform_amount := greatest(
		least(
			round(calculate_allocation_for_period.subscription_amount * 0.05),
			calculate_allocation_for_period.subscription_amount - locals.provider_amount
		),
		0
	);
	-- calculate the amount left for the authors
	locals.author_amount := greatest(
		calculate_allocation_for_period.subscription_amount - locals.provider_amount - locals.platform_amount,
		0
	);
	-- return the calculation
	RETURN (
		locals.platform_amount,
		locals.provider_amount,
		locals.author_amount
	);
END;
$_$;


--
-- Name: calculate_distribution_for_period(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.calculate_distribution_for_period(provider text, provider_period_id text) RETURNS subscriptions.subscription_distribution_calculation
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	period core.subscription_period;
	effective_period_range tsrange;
	subscription_amount int;
	allocation subscriptions.subscription_allocation_calculation;
	unknown_author_minutes_read int;
	unknown_author_amount int;
	author_distributions subscriptions.subscription_distribution_author_calculation[];
BEGIN
	-- get the subscription period
	SELECT
		subscription_period.*
	INTO
		locals.period
	FROM
		core.subscription_period
	WHERE
		subscription_period.provider = calculate_distribution_for_period.provider::core.subscription_provider AND
		subscription_period.provider_period_id = calculate_distribution_for_period.provider_period_id AND
		subscription_period.date_refunded IS NULL;
	-- calculate the effective period range
	IF
		locals.period.next_provider_period_id IS NOT NULL
	THEN
		SELECT
			tsrange(locals.period.begin_date, next_period.begin_date, '[)')
		INTO
			locals.effective_period_range
		FROM
			core.subscription_period AS next_period
		WHERE
			next_period.provider = locals.period.provider AND
			next_period.provider_period_id = locals.period.next_provider_period_id;
	ELSE
		locals.effective_period_range := tsrange(locals.period.begin_date, locals.period.renewal_grace_period_end_date, '[)');
	END IF;
	-- get the subscription amount, checking for a prorated amount first
	IF
		locals.period.prorated_price_amount IS NOT NULL
	THEN
		locals.subscription_amount := locals.period.prorated_price_amount;
	ELSE
		SELECT
			price_level.amount
		INTO
			locals.subscription_amount
		FROM
			subscriptions.price_level
		WHERE
			price_level.provider = locals.period.provider AND
			price_level.provider_price_id = locals.period.provider_price_id;
	END IF;
	-- calculate the allocation
	SELECT
		*
	INTO
		locals.allocation
	FROM
		subscriptions.calculate_allocation_for_period(
			provider := locals.period.provider,
			subscription_amount := locals.subscription_amount,
			payment_method_country := (
				CASE
					locals.period.provider
				WHEN
					'apple'::core.subscription_provider
				THEN
					NULL::iso_alpha_2_country_code
				WHEN
					'stripe'::core.subscription_provider
				THEN
					(
						SELECT
							payment_method.country
						FROM
							core.subscription_payment_method AS payment_method
						WHERE
							payment_method.provider = locals.period.provider AND
							payment_method.provider_payment_method_id = locals.period.provider_payment_method_id
					)
				END
			)
		);
	-- calculate the individual author amounts based on their share of minutes read
	CREATE TEMPORARY TABLE
		author_distribution
	AS (
		WITH period_read AS (
			SELECT
				article.id,
				article.word_count
			FROM
				core.user_article
				JOIN
					core.article ON
						article.id = user_article.article_id
			WHERE
				user_article.user_account_id = (
					SELECT
						subscription_account.user_account_id
					FROM
						core.subscription
						JOIN core.subscription_account ON
							subscription.provider = subscription_account.provider AND
							subscription.provider_account_id = subscription_account.provider_account_id
					WHERE
						subscription.provider = locals.period.provider AND
						subscription.provider_subscription_id = locals.period.provider_subscription_id
				) AND
				user_article.date_completed <@ locals.effective_period_range
		),
		read_author_share AS (
			SELECT
				article_author.author_id,
				(
					core.estimate_article_length(period_read.word_count)::decimal /
					count(*) OVER (PARTITION BY period_read.id)
				) AS minutes_read
			FROM
				period_read
				LEFT JOIN
					core.article_author ON
						period_read.id = article_author.article_id AND
						article_author.date_unassigned IS NULL
		)
		SELECT
			read_author_share.author_id,
			sum(read_author_share.minutes_read) AS minutes_read,
			round(
				(
					sum(read_author_share.minutes_read) /
					(
						SELECT
							sum(
								core.estimate_article_length(period_read.word_count)
							)
						FROM
							period_read
					)
				) *
				locals.allocation.author_amount
			)::int AS amount
		FROM
			read_author_share
		GROUP BY
			read_author_share.author_id
	);
	-- absorb any difference between the author total amount and individual distributions caused by rounding into the platform fee
	locals.allocation.platform_amount := locals.allocation.platform_amount + (
			locals.allocation.author_amount -
			(
				SELECT
					coalesce(
						sum(author_distribution.amount)::int,
						0
					)
				FROM
					author_distribution
			)
		);
	-- select the unknown author distribution
	SELECT
		author_distribution.minutes_read,
		author_distribution.amount
	INTO
		locals.unknown_author_minutes_read,
		locals.unknown_author_amount
	FROM
		author_distribution
	WHERE
		author_distribution.author_id IS NULL;
	-- select the author distributions
	locals.author_distributions := ARRAY (
		SELECT
			(
				author_distribution.author_id,
				author_distribution.minutes_read,
				author_distribution.amount
			)::subscriptions.subscription_distribution_author_calculation
		FROM
			author_distribution
		WHERE
			author_distribution.author_id IS NOT NULL
	);
	-- clean up the temp table
	DROP TABLE
		author_distribution;
	-- return the calculation
	RETURN (
		locals.allocation.platform_amount,
		locals.allocation.provider_amount,
		coalesce(locals.unknown_author_minutes_read, 0),
		coalesce(locals.unknown_author_amount, 0),
		locals.author_distributions
	);
END;
$$;


--
-- Name: author_payout; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.author_payout (
    id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    payout_account_id text NOT NULL,
    amount integer NOT NULL
);


--
-- Name: create_author_payout(text, timestamp without time zone, text, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_author_payout(id text, date_created timestamp without time zone, payout_account_id text, amount integer) RETURNS SETOF core.author_payout
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.author_payout (
			id,
			date_created,
			payout_account_id,
			amount
		)
	VALUES (
		create_author_payout.id,
		create_author_payout.date_created,
		create_author_payout.payout_account_id,
		create_author_payout.amount
	)
	ON CONFLICT (
		id
	)
	DO NOTHING
	RETURNING
		*;
$$;


--
-- Name: subscription_level; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_level (
    id integer NOT NULL,
    name text NOT NULL,
    amount integer NOT NULL
);


--
-- Name: subscription_price; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_price (
    provider core.subscription_provider NOT NULL,
    provider_price_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    level_id integer,
    custom_amount integer,
    CONSTRAINT subscription_price_level_or_custom_amount_null_check CHECK ((((level_id IS NULL) AND (custom_amount IS NOT NULL) AND (provider = 'stripe'::core.subscription_provider)) OR ((level_id IS NOT NULL) AND (custom_amount IS NULL))))
);


--
-- Name: price_level; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.price_level AS
 SELECT price.provider,
    price.provider_price_id,
    price.date_created,
    price.level_id,
    level.name,
    COALESCE(level.amount, price.custom_amount) AS amount
   FROM (core.subscription_price price
     LEFT JOIN core.subscription_level level ON ((price.level_id = level.id)));


--
-- Name: create_custom_price_level(text, text, timestamp without time zone, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_custom_price_level(provider text, provider_price_id text, date_created timestamp without time zone, amount integer) RETURNS SETOF subscriptions.price_level
    LANGUAGE plpgsql
    AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
BEGIN
	-- insert the new price
	INSERT INTO
		core.subscription_price (
			provider,
			provider_price_id,
			date_created,
			custom_amount
		)
	VALUES (
		create_custom_price_level.provider::core.subscription_provider,
		create_custom_price_level.provider_price_id,
		create_custom_price_level.date_created,
		create_custom_price_level.amount
	)
	ON CONFLICT (
		provider,
		custom_amount
	)
	DO NOTHING;
	-- return the price_level
	RETURN QUERY
	SELECT
		*
	FROM
		subscriptions.get_custom_price_level_for_provider(
			provider := create_custom_price_level.provider,
			amount := create_custom_price_level.amount
		);
END;
$$;


--
-- Name: subscription_period_distribution; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_period_distribution (
    provider core.subscription_provider NOT NULL,
    provider_period_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    platform_amount integer NOT NULL,
    provider_amount integer NOT NULL,
    unknown_author_minutes_read integer NOT NULL,
    unknown_author_amount integer NOT NULL
);


--
-- Name: create_distribution_for_period(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_distribution_for_period(provider text, provider_period_id text) RETURNS SETOF core.subscription_period_distribution
    LANGUAGE plpgsql
    AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
<<locals>>
DECLARE
	calculation subscriptions.subscription_distribution_calculation;
	distribution core.subscription_period_distribution;
BEGIN
	-- first run the calculation
	SELECT
		result.*
	INTO
		locals.calculation
	FROM
		subscriptions.calculate_distribution_for_period(
			provider := create_distribution_for_period.provider,
			provider_period_id := create_distribution_for_period.provider_period_id
		) AS result;
	-- attempt to insert the period distribution
	INSERT INTO
		core.subscription_period_distribution (
			provider,
			provider_period_id,
			date_created,
			platform_amount,
			provider_amount,
			unknown_author_minutes_read,
			unknown_author_amount
		)
	VALUES (
		create_distribution_for_period.provider::core.subscription_provider,
		create_distribution_for_period.provider_period_id,
		core.utc_now(),
		locals.calculation.platform_amount,
		locals.calculation.provider_amount,
		locals.calculation.unknown_author_minutes_read,
		locals.calculation.unknown_author_amount
	)
	ON CONFLICT (
		provider,
		provider_period_id
	)
	DO NOTHING
	RETURNING
		*
	INTO
		locals.distribution;
	-- check if the insert was successful
	IF
		NOT (locals.distribution IS NULL)
	THEN
		-- clear to insert author distributions
		INSERT INTO
			core.subscription_period_author_distribution (
				provider,
				provider_period_id,
				author_id,
				minutes_read,
				amount
			)
		SELECT
			locals.distribution.provider,
			locals.distribution.provider_period_id,
			author_distribution.author_id,
			author_distribution.minutes_read,
			author_distribution.amount
		FROM
			unnest(locals.calculation.author_distributions) AS author_distribution (
				author_id,
				minutes_read,
				amount
			);
		-- return distribution
		RETURN NEXT
			locals.distribution;
	END IF;
END;
$$;


--
-- Name: create_distributions_for_lapsed_periods(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_distributions_for_lapsed_periods(user_account_id bigint) RETURNS SETOF core.subscription_period_distribution
    LANGUAGE sql
    AS $$
	WITH completed_period AS (
		SELECT
			period.provider,
			period.provider_period_id
		FROM
			core.subscription_period AS period
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account ON
					subscription.provider = subscription_account.provider AND
					subscription.provider_account_id = subscription_account.provider_account_id
			LEFT JOIN
				core.subscription_period_distribution AS distribution ON
					period.provider = distribution.provider AND
					period.provider_period_id = distribution.provider_period_id
		WHERE
			CASE
				WHEN
					create_distributions_for_lapsed_periods.user_account_id IS NOT NULL
				THEN
					subscription_account.user_account_id = create_distributions_for_lapsed_periods.user_account_id
				ELSE
					TRUE
			END AND
			period.renewal_grace_period_end_date < core.utc_now() AND
			period.date_refunded IS NULL AND
			distribution.provider_period_id IS NULL
		)
	SELECT
		(distribution).*
	FROM
		(
			SELECT
				subscriptions.create_distribution_for_period(
					provider := completed_period.provider::text,
					provider_period_id := completed_period.provider_period_id
				)
			FROM
				completed_period
		) AS result (distribution);
$$;


--
-- Name: free_trial_credit; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.free_trial_credit (
    id bigint NOT NULL,
    date_created timestamp without time zone NOT NULL,
    user_account_id bigint NOT NULL,
    credit_trigger core.free_trial_credit_trigger NOT NULL,
    credit_type core.free_trial_credit_type NOT NULL,
    amount_credited integer NOT NULL,
    amount_remaining integer NOT NULL
);


--
-- Name: create_free_trial_credit(bigint, text, text, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_free_trial_credit(user_account_id bigint, credit_trigger text, credit_type text, credit_amount integer) RETURNS SETOF core.free_trial_credit
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.free_trial_credit (
			date_created,
			user_account_id,
			credit_trigger,
			credit_type,
			amount_credited,
			amount_remaining
		)
	VALUES (
		core.utc_now(),
		create_free_trial_credit.user_account_id,
		create_free_trial_credit.credit_trigger::core.free_trial_credit_trigger,
		create_free_trial_credit.credit_type::core.free_trial_credit_type,
		create_free_trial_credit.credit_amount,
		create_free_trial_credit.credit_amount
	)
	RETURNING
		*;
$$;


--
-- Name: subscription; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription (
    provider core.subscription_provider NOT NULL,
    provider_subscription_id text NOT NULL,
    provider_account_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    latest_receipt core.base64_text,
    CONSTRAINT subscription_latest_receipt_null_check CHECK (((latest_receipt IS NOT NULL) OR (provider = 'stripe'::core.subscription_provider)))
);


--
-- Name: create_or_update_subscription(text, text, text, timestamp without time zone, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_or_update_subscription(provider text, provider_subscription_id text, provider_account_id text, date_created timestamp without time zone, latest_receipt text) RETURNS SETOF core.subscription
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.subscription (
			provider,
			provider_subscription_id,
			provider_account_id,
			date_created,
			latest_receipt
		)
	VALUES (
		create_or_update_subscription.provider::core.subscription_provider,
		create_or_update_subscription.provider_subscription_id,
		create_or_update_subscription.provider_account_id,
		create_or_update_subscription.date_created,
		create_or_update_subscription.latest_receipt
	)
	ON CONFLICT (
		provider,
		provider_subscription_id
	)
	DO UPDATE
		SET
			latest_receipt = coalesce(create_or_update_subscription.latest_receipt, subscription.latest_receipt)
	RETURNING
		*;
$$;


--
-- Name: subscription_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_account (
    provider core.subscription_provider NOT NULL,
    provider_account_id text NOT NULL,
    user_account_id bigint,
    date_created timestamp without time zone NOT NULL,
    environment core.subscription_environment NOT NULL,
    CONSTRAINT subscription_account_user_account_null_check CHECK (((user_account_id IS NOT NULL) OR (provider = 'apple'::core.subscription_provider)))
);


--
-- Name: create_or_update_subscription_account(text, text, bigint, timestamp without time zone, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_or_update_subscription_account(provider text, provider_account_id text, user_account_id bigint, date_created timestamp without time zone, environment text) RETURNS SETOF core.subscription_account
    LANGUAGE sql
    AS $$
   INSERT INTO
   	core.subscription_account (
   		provider,
   		provider_account_id,
   		user_account_id,
   		date_created,
   		environment
   	)
   VALUES (
   	create_or_update_subscription_account.provider::core.subscription_provider,
   	create_or_update_subscription_account.provider_account_id,
   	create_or_update_subscription_account.user_account_id,
   	create_or_update_subscription_account.date_created,
   	create_or_update_subscription_account.environment::core.subscription_environment
	)
	ON CONFLICT (
		provider,
		provider_account_id
	)
	DO UPDATE
		SET
			user_account_id = coalesce(subscription_account.user_account_id, create_or_update_subscription_account.user_account_id)
	RETURNING
   	*;
$$;


--
-- Name: subscription_period; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_period (
    provider core.subscription_provider NOT NULL,
    provider_period_id text NOT NULL,
    provider_subscription_id text NOT NULL,
    provider_price_id text NOT NULL,
    provider_payment_method_id text,
    begin_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    renewal_grace_period_end_date timestamp without time zone NOT NULL,
    date_created timestamp without time zone NOT NULL,
    payment_status core.subscription_payment_status NOT NULL,
    date_paid timestamp without time zone,
    date_refunded timestamp without time zone,
    refund_reason text,
    next_provider_period_id text,
    prorated_price_amount integer,
    CONSTRAINT subscription_period_date_range_check CHECK ((begin_date < end_date)),
    CONSTRAINT subscription_period_payment_method_null_check CHECK (((provider_payment_method_id IS NOT NULL) OR (date_paid IS NULL) OR (provider = 'apple'::core.subscription_provider))),
    CONSTRAINT subscription_period_payment_status_check CHECK (
CASE payment_status
    WHEN 'succeeded'::core.subscription_payment_status THEN (date_paid IS NOT NULL)
    ELSE (date_paid IS NULL)
END),
    CONSTRAINT subscription_period_prorated_price_amount_null_check CHECK (((prorated_price_amount IS NULL) OR (next_provider_period_id IS NOT NULL))),
    CONSTRAINT subscription_period_refund_reason_null_check CHECK ((((date_refunded IS NULL) AND (refund_reason IS NULL)) OR ((date_refunded IS NOT NULL) AND (refund_reason IS NOT NULL))))
);


--
-- Name: create_or_update_subscription_period(text, text, text, text, text, timestamp without time zone, timestamp without time zone, timestamp without time zone, text, timestamp without time zone, timestamp without time zone, text, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_or_update_subscription_period(provider text, provider_period_id text, provider_subscription_id text, provider_price_id text, provider_payment_method_id text, begin_date timestamp without time zone, end_date timestamp without time zone, date_created timestamp without time zone, payment_status text, date_paid timestamp without time zone, date_refunded timestamp without time zone, refund_reason text, proration_discount integer) RETURNS SETOF core.subscription_period
    LANGUAGE plpgsql
    AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
<<locals>>
DECLARE
	user_account_id CONSTANT bigint := (
		SELECT
			subscription_account.user_account_id
		FROM
			core.subscription_account
			JOIN
				core.subscription ON
					subscription_account.provider = subscription.provider AND
					subscription_account.provider_account_id = subscription.provider_account_id
		WHERE
			subscription.provider = create_or_update_subscription_period.provider::core.subscription_provider AND
			subscription.provider_subscription_id = create_or_update_subscription_period.provider_subscription_id
	);
	current_period core.subscription_period;
	prev_unlinked_period core.subscription_period;
	current_status subscriptions.subscription_status;
BEGIN
	-- insert a new period or update an existing one
	INSERT INTO
		core.subscription_period (
			provider,
			provider_period_id,
			provider_subscription_id,
			provider_price_id,
			provider_payment_method_id,
			begin_date,
			end_date,
			renewal_grace_period_end_date,
			date_created,
			payment_status,
			date_paid,
			date_refunded,
			refund_reason
		)
	VALUES (
		create_or_update_subscription_period.provider::core.subscription_provider,
		create_or_update_subscription_period.provider_period_id,
		create_or_update_subscription_period.provider_subscription_id,
		create_or_update_subscription_period.provider_price_id,
		create_or_update_subscription_period.provider_payment_method_id,
		create_or_update_subscription_period.begin_date,
		create_or_update_subscription_period.end_date,
		create_or_update_subscription_period.end_date + '1 hour'::interval,
		create_or_update_subscription_period.date_created,
		create_or_update_subscription_period.payment_status::core.subscription_payment_status,
		create_or_update_subscription_period.date_paid,
		create_or_update_subscription_period.date_refunded,
		create_or_update_subscription_period.refund_reason
	)
	ON CONFLICT (
		provider,
		provider_period_id
	)
	DO UPDATE
		SET
			provider_payment_method_id = (
				CASE
					WHEN
						subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
					THEN
						subscription_period.provider_payment_method_id
					ELSE
						create_or_update_subscription_period.provider_payment_method_id
				END
			),
			payment_status = (
				CASE
					WHEN
						subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
					THEN
						subscription_period.payment_status
					ELSE
						create_or_update_subscription_period.payment_status::core.subscription_payment_status
				END
			),
			date_paid = coalesce(subscription_period.date_paid, create_or_update_subscription_period.date_paid),
			date_refunded = coalesce(subscription_period.date_refunded, create_or_update_subscription_period.date_refunded),
			refund_reason = coalesce(subscription_period.refund_reason, create_or_update_subscription_period.refund_reason)
	RETURNING
		*
	INTO
		locals.current_period;
	-- check for a previous period that is not linked to the current period
	SELECT
		period.*
	INTO
		locals.prev_unlinked_period
	FROM
		core.subscription_period AS period
	WHERE
		period.provider = locals.current_period.provider AND
		period.provider_subscription_id = locals.current_period.provider_subscription_id AND
		period.begin_date < locals.current_period.begin_date AND
		period.renewal_grace_period_end_date >= locals.current_period.begin_date AND
		period.date_paid IS NOT NULL AND
		period.date_refunded IS NULL AND
		period.next_provider_period_id IS NULL
	FOR UPDATE;
	IF
		NOT (locals.prev_unlinked_period IS NULL)
	THEN
		-- link the previous period to the current period and set the prorated price if necessary
		UPDATE
			core.subscription_period
		SET
			next_provider_period_id = locals.current_period.provider_period_id,
			prorated_price_amount = (
				CASE
					WHEN
						locals.current_period.begin_date < locals.prev_unlinked_period.end_date
					THEN
						(
							SELECT
								CASE
									WHEN
										create_or_update_subscription_period.proration_discount IS NOT NULL
									THEN
										price_level.amount - create_or_update_subscription_period.proration_discount
									ELSE
										round(
											(
												extract('epoch' FROM (locals.current_period.begin_date - locals.prev_unlinked_period.begin_date)) /
												extract('epoch' FROM (locals.prev_unlinked_period.end_date - locals.prev_unlinked_period.begin_date))
											) *
											price_level.amount
										)
								END
							FROM
								subscriptions.price_level
							WHERE
								price_level.provider = locals.prev_unlinked_period.provider AND
								price_level.provider_price_id = locals.prev_unlinked_period.provider_price_id
						)
				END
			)
		WHERE
			subscription_period.provider = locals.prev_unlinked_period.provider AND
			subscription_period.provider_period_id = locals.prev_unlinked_period.provider_period_id;
		-- create a distribution for the previous period
		PERFORM
			subscriptions.create_distribution_for_period(
				provider := locals.prev_unlinked_period.provider::text,
				provider_period_id := locals.prev_unlinked_period.provider_period_id
			);
	END IF;
	-- update the cached user_account column with the current status
	SELECT
		*
	INTO
		locals.current_status
	FROM
		subscriptions.get_current_subscription_status_for_user_account(
			user_account_id := locals.user_account_id
		);
	UPDATE
		core.user_account
	SET
		subscription_end_date = (
			CASE WHEN
				(locals.current_status.latest_period).payment_status = 'succeeded'::core.subscription_payment_status AND
				(locals.current_status.latest_period).date_refunded IS NULL
			THEN
				(locals.current_status.latest_period).renewal_grace_period_end_date
			ELSE
				NULL::timestamp
			END
		)
	WHERE
		user_account.id = locals.user_account_id;
	-- return the current period
	RETURN NEXT
		locals.current_period;
END;
$$;


--
-- Name: create_payment_method(text, text, text, timestamp without time zone, text, text, text, text, integer, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_payment_method(provider text, provider_payment_method_id text, provider_account_id text, date_created timestamp without time zone, wallet text, brand text, last_four_digits text, country text, expiration_month integer, expiration_year integer) RETURNS SETOF subscriptions.current_payment_method
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	version_timestamp CONSTANT timestamp := core.utc_now();
BEGIN
	SET CONSTRAINTS
		subscription_payment_method_current_version_fkey
	DEFERRED;
   INSERT INTO
   	core.subscription_payment_method (
   		provider,
   		provider_payment_method_id,
   		provider_account_id,
   		date_created,
   		wallet,
   		brand,
   		last_four_digits,
   		country,
   		current_version_date
   	)
   	VALUES (
			create_payment_method.provider::core.subscription_provider,
			create_payment_method.provider_payment_method_id,
			create_payment_method.provider_account_id,
			create_payment_method.date_created,
			create_payment_method.wallet::core.subscription_payment_method_wallet,
			create_payment_method.brand::core.subscription_payment_method_brand,
			create_payment_method.last_four_digits::char (4),
			create_payment_method.country::core.iso_alpha_2_country_code,
			locals.version_timestamp
		);
	INSERT INTO
		core.subscription_payment_method_version (
			provider,
			provider_payment_method_id,
			date_created,
			event_source,
			expiration_month,
			expiration_year
		)
	VALUES (
		create_payment_method.provider::core.subscription_provider,
		create_payment_method.provider_payment_method_id,
		locals.version_timestamp,
		'user_action'::core.subscription_event_source,
		create_payment_method.expiration_month,
		create_payment_method.expiration_year
	);
	RETURN QUERY
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = create_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = create_payment_method.provider_payment_method_id;
END;
$$;


--
-- Name: payout_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.payout_account (
    id text NOT NULL,
    user_account_id bigint NOT NULL,
    date_created timestamp without time zone NOT NULL,
    date_details_submitted timestamp without time zone,
    date_payouts_enabled timestamp without time zone
);


--
-- Name: create_payout_account(text, bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_payout_account(id text, user_account_id bigint) RETURNS SETOF core.payout_account
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.payout_account (
			id,
			user_account_id,
			date_created
		)
	VALUES (
		create_payout_account.id,
		create_payout_account.user_account_id,
		core.utc_now()
	)
	RETURNING
		*;
$$;


--
-- Name: subscription_renewal_status_change; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_renewal_status_change (
    id bigint NOT NULL,
    provider core.subscription_provider NOT NULL,
    provider_subscription_id text NOT NULL,
    date_created timestamp without time zone NOT NULL,
    auto_renew_enabled boolean NOT NULL,
    provider_price_id text,
    expiration_intent text
);


--
-- Name: create_subscription_renewal_status_change(text, text, timestamp without time zone, boolean, text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.create_subscription_renewal_status_change(provider text, provider_subscription_id text, date_created timestamp without time zone, auto_renew_enabled boolean, provider_price_id text, expiration_intent text) RETURNS SETOF core.subscription_renewal_status_change
    LANGUAGE sql
    AS $$
	INSERT INTO
		core.subscription_renewal_status_change (
			provider,
			provider_subscription_id,
			date_created,
			auto_renew_enabled,
			provider_price_id,
			expiration_intent
		)
	VALUES (
		create_subscription_renewal_status_change.provider::core.subscription_provider,
		create_subscription_renewal_status_change.provider_subscription_id,
		create_subscription_renewal_status_change.date_created,
		create_subscription_renewal_status_change.auto_renew_enabled,
		create_subscription_renewal_status_change.provider_price_id,
		create_subscription_renewal_status_change.expiration_intent
	)
	RETURNING
		*;
$$;


--
-- Name: latest_subscription_period; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.latest_subscription_period AS
 SELECT DISTINCT ON (period.provider, period.provider_subscription_id) period.provider,
    period.provider_period_id,
    period.provider_subscription_id,
    period.provider_price_id,
    period.provider_payment_method_id,
    period.begin_date,
    period.end_date,
    period.renewal_grace_period_end_date,
    period.date_created,
    period.payment_status,
    period.date_paid,
    period.date_refunded,
    period.refund_reason,
    period.next_provider_period_id,
    period.prorated_price_amount
   FROM core.subscription_period period
  ORDER BY period.provider, period.provider_subscription_id, GREATEST(period.date_created, period.date_paid) DESC;


--
-- Name: latest_subscription_renewal_status_change; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.latest_subscription_renewal_status_change AS
 SELECT DISTINCT ON (change.provider, change.provider_subscription_id) change.id,
    change.provider,
    change.provider_subscription_id,
    change.date_created,
    change.auto_renew_enabled,
    change.provider_price_id,
    change.expiration_intent
   FROM core.subscription_renewal_status_change change
  ORDER BY change.provider, change.provider_subscription_id, change.id DESC;


--
-- Name: subscription_status; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.subscription_status AS
 SELECT account.user_account_id,
    account.provider,
    account.provider_account_id,
    subscription.provider_subscription_id,
    subscription.date_created,
    subscription.latest_receipt,
    ROW(latest_period.provider_period_id, latest_period.provider_price_id, price_level.name, price_level.amount, latest_period.provider_payment_method_id, latest_period.begin_date, latest_period.end_date, latest_period.renewal_grace_period_end_date, latest_period.date_created, latest_period.payment_status, latest_period.date_paid, latest_period.date_refunded, latest_period.refund_reason)::subscriptions.subscription_status_latest_period AS latest_period,
        CASE
            WHEN (latest_renewal_change.id IS NOT NULL) THEN ROW(latest_renewal_change.date_created, latest_renewal_change.auto_renew_enabled, latest_renewal_change.provider_price_id, renewal_price_level.name, renewal_price_level.amount)::subscriptions.subscription_status_latest_renewal_status_change
            ELSE NULL::subscriptions.subscription_status_latest_renewal_status_change
        END AS latest_renewal_status_change
   FROM (((((core.subscription
     JOIN core.subscription_account account ON (((subscription.provider = account.provider) AND (subscription.provider_account_id = account.provider_account_id))))
     JOIN subscriptions.latest_subscription_period latest_period ON (((subscription.provider = latest_period.provider) AND (subscription.provider_subscription_id = latest_period.provider_subscription_id))))
     JOIN subscriptions.price_level ON (((latest_period.provider = price_level.provider) AND (latest_period.provider_price_id = price_level.provider_price_id))))
     LEFT JOIN subscriptions.latest_subscription_renewal_status_change latest_renewal_change ON (((subscription.provider = latest_renewal_change.provider) AND (subscription.provider_subscription_id = latest_renewal_change.provider_subscription_id) AND (tsrange(latest_period.begin_date, latest_period.end_date) @> latest_renewal_change.date_created))))
     LEFT JOIN subscriptions.price_level renewal_price_level ON (((latest_renewal_change.provider = renewal_price_level.provider) AND (latest_renewal_change.provider_price_id = renewal_price_level.provider_price_id))));


--
-- Name: get_current_subscription_status_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_current_subscription_status_for_user_account(user_account_id bigint) RETURNS SETOF subscriptions.subscription_status
    LANGUAGE sql STABLE
    AS $$
	SELECT
		status.*
	FROM
		subscriptions.user_account_subscription_status AS status
	WHERE
		status.user_account_id = get_current_subscription_status_for_user_account.user_account_id;
$$;


--
-- Name: get_custom_price_level_for_provider(text, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_custom_price_level_for_provider(provider text, amount integer) RETURNS SETOF subscriptions.price_level
    LANGUAGE sql STABLE
    AS $$
	SELECT
		price_level.*
	FROM
		subscriptions.price_level
	WHERE
		price_level.provider = get_custom_price_level_for_provider.provider::core.subscription_provider AND
		price_level.amount = get_custom_price_level_for_provider.amount;
$$;


--
-- Name: get_default_payment_method_for_subscription_account(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_default_payment_method_for_subscription_account(provider text, provider_account_id text) RETURNS SETOF subscriptions.current_payment_method
    LANGUAGE sql STABLE
    AS $$
	SELECT
		default_method.*
	FROM
		subscriptions.current_default_payment_method AS default_method
	WHERE
		default_method.provider = get_default_payment_method_for_subscription_account.provider::core.subscription_provider AND
		default_method.provider_account_id = get_default_payment_method_for_subscription_account.provider_account_id;
$$;


--
-- Name: donation_recipient; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.donation_recipient (
    id bigint NOT NULL,
    date_created timestamp without time zone NOT NULL,
    name text NOT NULL,
    website text NOT NULL,
    tax_id text NOT NULL
);


--
-- Name: get_donation_recipient_for_author(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_donation_recipient_for_author(author_id bigint) RETURNS SETOF core.donation_recipient
    LANGUAGE sql STABLE
    AS $$
	SELECT
		recipient.*
	FROM
		core.donation_account AS account
		JOIN
			core.donation_recipient AS recipient ON
				account.donation_recipient_id = recipient.id
	WHERE
		account.author_id = get_donation_recipient_for_author.author_id;
$$;


--
-- Name: get_free_article_views_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_free_article_views_for_user_account(user_account_id bigint) RETURNS SETOF subscriptions.free_trial_article_view
    LANGUAGE sql STABLE
    AS $$
	SELECT
		user_article.article_id,
		article.slug,
		user_article.date_viewed,
		user_article.free_trial_credit_id
	FROM
		core.user_article
		JOIN
			core.article ON
				user_article.article_id = article.id
	WHERE
		user_article.user_account_id = get_free_article_views_for_user_account.user_account_id AND
		user_article.free_trial_credit_id IS NOT NULL;
$$;


--
-- Name: get_free_trial_credits_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_free_trial_credits_for_user_account(user_account_id bigint) RETURNS SETOF core.free_trial_credit
    LANGUAGE sql STABLE
    AS $$
	SELECT
		free_trial_credit.*
	FROM
		core.free_trial_credit
	WHERE
		free_trial_credit.user_account_id = get_free_trial_credits_for_user_account.user_account_id;
$$;


--
-- Name: get_payment_method(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_payment_method(provider text, provider_payment_method_id text) RETURNS SETOF subscriptions.current_payment_method
    LANGUAGE sql STABLE
    AS $$
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = get_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = get_payment_method.provider_payment_method_id;
$$;


--
-- Name: get_payout_account(text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_payout_account(id text) RETURNS SETOF core.payout_account
    LANGUAGE sql
    AS $$
	SELECT
		payout_account.*
	FROM
		core.payout_account
	WHERE
		payout_account.id = get_payout_account.id;
$$;


--
-- Name: get_payout_account_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_payout_account_for_user_account(user_account_id bigint) RETURNS SETOF core.payout_account
    LANGUAGE sql
    AS $$
	SELECT
		payout_account.*
	FROM
		core.payout_account
	WHERE
		payout_account.user_account_id = get_payout_account_for_user_account.user_account_id;
$$;


--
-- Name: get_standard_price_levels_for_provider(text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_standard_price_levels_for_provider(provider text) RETURNS SETOF subscriptions.price_level
    LANGUAGE sql STABLE
    AS $$
	SELECT
		price_level.*
	FROM
		subscriptions.price_level
	WHERE
		price_level.provider = get_standard_price_levels_for_provider.provider::core.subscription_provider AND
		price_level.level_id IS NOT NULL;
$$;


--
-- Name: get_subscription_accounts_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_subscription_accounts_for_user_account(user_account_id bigint) RETURNS SETOF core.subscription_account
    LANGUAGE sql STABLE
    AS $$
   SELECT
   	subscription_account.*
   FROM
   	core.subscription_account
   WHERE
   	subscription_account.user_account_id = get_subscription_accounts_for_user_account.user_account_id;
$$;


--
-- Name: get_subscription_period(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_subscription_period(provider text, provider_period_id text) RETURNS SETOF core.subscription_period
    LANGUAGE sql STABLE
    AS $$
	SELECT
		period.*
	FROM
		core.subscription_period AS period
	WHERE
		period.provider = get_subscription_period.provider::core.subscription_provider AND
		period.provider_period_id = get_subscription_period.provider_period_id;
$$;


--
-- Name: get_subscription_status_for_subscription_account(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_subscription_status_for_subscription_account(provider text, provider_account_id text) RETURNS SETOF subscriptions.subscription_status
    LANGUAGE sql STABLE
    AS $$
	SELECT
		status.*
	FROM
		subscriptions.subscription_status AS status
	WHERE
		status.provider = get_subscription_status_for_subscription_account.provider::core.subscription_provider AND
		status.provider_account_id = get_subscription_status_for_subscription_account.provider_account_id;
$$;


--
-- Name: get_subscription_statuses_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.get_subscription_statuses_for_user_account(user_account_id bigint) RETURNS SETOF subscriptions.subscription_status
    LANGUAGE sql STABLE
    AS $$
	SELECT
		status.*
	FROM
		subscriptions.subscription_status AS status
	WHERE
		status.user_account_id = get_subscription_statuses_for_user_account.user_account_id;
$$;


--
-- Name: is_article_free_to_read(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.is_article_free_to_read(article_id bigint) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
	SELECT
		article.source_id = 48542 -- readup blog
	FROM
		core.article
	WHERE
		article.id = is_article_free_to_read.article_id;
$$;


--
-- Name: is_user_free_for_life(core.user_account); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.is_user_free_for_life(user_account core.user_account) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT
		is_user_free_for_life.user_account.date_created < '2021-05-06T04:00:00';
$$;


--
-- Name: is_user_subscribed(core.user_account, timestamp without time zone); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.is_user_subscribed(user_account core.user_account, as_of_date timestamp without time zone) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT
		is_user_subscribed.user_account.subscription_end_date IS NOT NULL AND
		is_user_subscribed.user_account.subscription_end_date > is_user_subscribed.as_of_date;
$$;


--
-- Name: is_user_subscribed_or_free_for_life(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.is_user_subscribed_or_free_for_life(user_account_id bigint) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
	SELECT
		subscriptions.is_user_free_for_life(
			user_account := user_account
		) OR
		subscriptions.is_user_subscribed(
			user_account := user_account,
			as_of_date := core.utc_now()
		)
	FROM
		core.user_account
	WHERE
		user_account.id = is_user_subscribed_or_free_for_life.user_account_id;
$$;


--
-- Name: run_author_distribution_report_for_period_distributions(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_author_distribution_report_for_period_distributions(author_id bigint) RETURNS subscriptions.subscription_distribution_author_report
    LANGUAGE sql STABLE
    AS $$
	WITH author_distribution_totals AS (
		SELECT
			coalesce(
				sum(author_distribution.minutes_read)::int,
				0
			) AS minutes_read,
			coalesce(
				sum(author_distribution.amount)::int,
				0
			) AS amount
		FROM
			core.subscription_period_author_distribution AS author_distribution
			JOIN
				core.subscription_period AS period ON
					author_distribution.provider = period.provider AND
					author_distribution.provider_period_id = period.provider_period_id
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
		WHERE
			author_distribution.author_id = run_author_distribution_report_for_period_distributions.author_id AND
			period.date_refunded IS NULL AND
			account.environment = 'production'::core.subscription_environment
	)
	SELECT
		author.id,
		author.name,
		author.slug,
		(
			SELECT
				author_distribution_totals.minutes_read
			FROM
				author_distribution_totals
		),
		(
			SELECT
				author_distribution_totals.amount
			FROM
				author_distribution_totals
		)
	FROM
		core.author
	WHERE
		author.id = run_author_distribution_report_for_period_distributions.author_id;
$$;


--
-- Name: run_authors_earnings_report(); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_authors_earnings_report() RETURNS SETOF subscriptions.author_earnings_report_line_item
    LANGUAGE sql STABLE
    AS $$
	SELECT
		author.id,
		author.name,
		author.slug,
		user_account.id,
		user_account.name,
		donation_recipient.id,
		donation_recipient.name,
		sum(author_distribution.minutes_read)::int,
		sum(author_distribution.amount)::int,
		0
	FROM
		core.subscription_period_author_distribution AS author_distribution
		JOIN
			core.subscription_period AS period ON
				author_distribution.provider = period.provider AND
				author_distribution.provider_period_id = period.provider_period_id AND
				period.date_refunded IS NULL
		JOIN
			core.subscription ON
				period.provider = subscription.provider AND
				period.provider_subscription_id = subscription.provider_subscription_id
		JOIN
			core.subscription_account AS account ON
				subscription.provider = account.provider AND
				subscription.provider_account_id = account.provider_account_id AND
				account.environment = 'production'::core.subscription_environment
		JOIN
			core.author ON
				author_distribution.author_id = author.id
		LEFT JOIN
			core.author_user_account_assignment AS user_account_assignment ON
				author.id = user_account_assignment.author_id
		LEFT JOIN
			core.user_account ON
				user_account_assignment.user_account_id = user_account.id
		LEFT JOIN
			core.donation_account ON
				author.id = donation_account.author_id OR
				user_account.id = donation_account.user_account_id
		LEFT JOIN
			core.donation_recipient ON
				donation_account.donation_recipient_id = donation_recipient.id
	GROUP BY
		author.id,
		user_account.id,
		donation_recipient.id;
$$;


--
-- Name: FUNCTION run_authors_earnings_report(); Type: COMMENT; Schema: subscriptions; Owner: -
--

COMMENT ON FUNCTION subscriptions.run_authors_earnings_report() IS 'DEPRECATED';


--
-- Name: run_authors_earnings_report(integer, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_authors_earnings_report(min_amount_earned integer, max_amount_earned integer) RETURNS TABLE(author_id bigint, amount_earned integer)
    LANGUAGE sql STABLE
    AS $$
	WITH author_distributions AS (
		SELECT
			author_distribution.author_id,
			sum(author_distribution.amount) AS distribution_total
		FROM
			core.subscription_period_author_distribution AS author_distribution
			JOIN
				core.subscription_period AS period ON
					author_distribution.provider = period.provider AND
					author_distribution.provider_period_id = period.provider_period_id AND
					period.date_refunded IS NULL
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account ON
					subscription.provider = subscription_account.provider AND
					subscription.provider_account_id = subscription_account.provider_account_id AND
					subscription_account.environment = 'production'::core.subscription_environment
		GROUP BY
			author_distribution.author_id
	)
	SELECT
		author_distributions.author_id::bigint,
		author_distributions.distribution_total::int
	FROM
		author_distributions
	WHERE
		CASE
			WHEN
				run_authors_earnings_report.min_amount_earned != 0 AND
				run_authors_earnings_report.max_amount_earned != 0
			THEN
				author_distributions.distribution_total BETWEEN
					run_authors_earnings_report.min_amount_earned AND
					run_authors_earnings_report.max_amount_earned
			WHEN
				 run_authors_earnings_report.min_amount_earned != 0
			THEN
				author_distributions.distribution_total >= run_authors_earnings_report.min_amount_earned
			WHEN
				 run_authors_earnings_report.max_amount_earned != 0
			THEN
				author_distributions.distribution_total <= run_authors_earnings_report.max_amount_earned
			ELSE
				TRUE
		END;
$$;


--
-- Name: run_distribution_report_for_period_calculation(text, text); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_distribution_report_for_period_calculation(provider text, provider_period_id text) RETURNS subscriptions.subscription_distribution_report
    LANGUAGE sql STABLE
    AS $$
	SELECT
		(
			SELECT
				coalesce(period.prorated_price_amount, price_level.amount)
			FROM
				core.subscription_period AS period
				JOIN
					subscriptions.price_level ON
						period.provider = price_level.provider AND
						period.provider_price_id = price_level.provider_price_id
			WHERE
				period.provider = run_distribution_report_for_period_calculation.provider::core.subscription_provider AND
				period.provider_period_id = run_distribution_report_for_period_calculation.provider_period_id
		),
		calculation.platform_amount,
		CASE
			WHEN
				run_distribution_report_for_period_calculation.provider = 'apple'
			THEN
				calculation.provider_amount
			ELSE
				0
		END,
		CASE
			WHEN
				run_distribution_report_for_period_calculation.provider = 'stripe'
			THEN
				calculation.provider_amount
			ELSE
				0
		END,
		calculation.unknown_author_minutes_read,
		calculation.unknown_author_amount,
		ARRAY (
			SELECT
				(
					author.id,
					author.name,
					author.slug,
					author_distribution.minutes_read,
					author_distribution.amount
				)::subscriptions.subscription_distribution_author_report
			FROM
				unnest(calculation.author_distributions) AS author_distribution (
					author_id,
					minutes_read,
					amount
				)
				JOIN
					core.author ON
						author_distribution.author_id = author.id
		)
	FROM
		subscriptions.calculate_distribution_for_period(
			provider := run_distribution_report_for_period_calculation.provider,
			provider_period_id := run_distribution_report_for_period_calculation.provider_period_id
		) AS calculation (
			platform_amount,
			provider_amount,
			unknown_author_minutes_read,
			unknown_author_amount,
			author_distributions
		);
$$;


--
-- Name: run_distribution_report_for_period_distributions(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_distribution_report_for_period_distributions(user_account_id bigint) RETURNS subscriptions.subscription_distribution_report
    LANGUAGE sql STABLE
    AS $$
	WITH user_distribution AS (
		SELECT
			distribution.provider,
			distribution.provider_period_id,
			coalesce(period.prorated_price_amount, price_level.amount) AS subscription_amount,
			distribution.platform_amount,
			CASE
				WHEN
					distribution.provider = 'apple'::core.subscription_provider
				THEN
					distribution.provider_amount
				ELSE
					0
			END AS apple_amount,
			CASE
				WHEN
					distribution.provider = 'stripe'::core.subscription_provider
				THEN
					distribution.provider_amount
				ELSE
					0
			END AS stripe_amount,
			distribution.unknown_author_minutes_read,
			distribution.unknown_author_amount
		FROM
			core.subscription_period_distribution AS distribution
			JOIN
				core.subscription_period AS period ON
					period.provider = distribution.provider AND
					period.provider_period_id = distribution.provider_period_id
			JOIN
				subscriptions.price_level ON
					period.provider = price_level.provider AND
					period.provider_price_id = price_level.provider_price_id
			JOIN
				core.subscription ON
					subscription.provider = period.provider AND
					subscription.provider_subscription_id = period.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
		WHERE
			account.user_account_id = run_distribution_report_for_period_distributions.user_account_id AND
			period.date_refunded IS NULL
	)
	SELECT
		coalesce(
			sum(user_distribution.subscription_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.platform_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.apple_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.stripe_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.unknown_author_minutes_read)::int,
			0
		),
		coalesce(
			sum(user_distribution.unknown_author_amount)::int,
			0
		),
		ARRAY (
			SELECT
				(
					author.id,
					author.name,
					author.slug,
					sum(author_distribution.minutes_read),
					sum(author_distribution.amount)
				)::subscriptions.subscription_distribution_author_report
			FROM
				user_distribution
				JOIN
					core.subscription_period_author_distribution AS author_distribution ON
						user_distribution.provider = author_distribution.provider AND
						user_distribution.provider_period_id = author_distribution.provider_period_id
				JOIN
					core.author ON
						author_distribution.author_id = author.id
			GROUP BY
				author.id
		)
	FROM
		user_distribution;
$$;


--
-- Name: run_payout_report(); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_payout_report() RETURNS TABLE(author_name text, total_earnings integer, total_payouts integer, total_donations integer, current_balance integer)
    LANGUAGE sql STABLE
    AS $$
	WITH earnings AS (
		SELECT
			author_id,
			amount_earned
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := 1000,
				max_amount_earned := 0
			)
	),
	payouts AS (
		SELECT
			assignment.author_id,
			sum(author_payout.amount)::int AS total_amount
		FROM
			core.payout_account
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
			JOIN
				core.author_user_account_assignment AS assignment ON
					payout_account.user_account_id = assignment.user_account_id
		GROUP BY
			assignment.author_id
	),
	donations AS (
		SELECT
			coalesce(donation_account.author_id, assignment.author_id) AS author_id,
			sum(donation_payout.amount)::int AS total_amount
		FROM
			core.donation_account
			JOIN
				core.donation_payout ON
					donation_account.id = donation_payout.donation_account_id
			LEFT JOIN
				core.author_user_account_assignment AS assignment ON
					donation_account.user_account_id = assignment.user_account_id
		GROUP BY
			donation_account.author_id,
			assignment.author_id
	)
	SELECT
		author.name,
		earnings.amount_earned AS total_earnings,
		coalesce(payouts.total_amount, 0) AS total_payouts,
		coalesce(donations.total_amount, 0) AS total_donations,
		(earnings.amount_earned - coalesce(payouts.total_amount, 0) - coalesce(donations.total_amount, 0)) AS current_balance
	FROM
		core.author
		JOIN
			earnings ON
				author.id = earnings.author_id
		LEFT JOIN
			payouts ON
				author.id = payouts.author_id
		LEFT JOIN
			donations ON
				author.id = donations.author_id
	WHERE
		payouts.author_id IS NOT NULL OR
		donations.author_id IS NOT NULL
	ORDER BY
		current_balance DESC;
$$;


--
-- Name: run_payout_totals_report(); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_payout_totals_report() RETURNS SETOF subscriptions.payout_totals_report
    LANGUAGE sql STABLE
    AS $$
	SELECT
		(
			SELECT
				sum(author_payout.amount)::int
			FROM
				core.author_payout
		),
		(
			SELECT
				sum(donation_payout.amount)::int
			FROM
				core.donation_payout
		);
$$;


--
-- Name: run_payout_totals_report_for_user_account(bigint); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.run_payout_totals_report_for_user_account(user_account_id bigint) RETURNS SETOF subscriptions.payout_totals_report
    LANGUAGE sql STABLE
    AS $$
	SELECT
		(
			SELECT
				sum(payout.amount)::int
			FROM
				core.author_payout AS payout
				JOIN
					core.payout_account AS account ON
						payout.payout_account_id = account.id
			WHERE
				account.user_account_id = run_payout_totals_report_for_user_account.user_account_id
		),
		(
			SELECT
				sum(payout.amount)::int
			FROM
				core.donation_payout AS payout
				JOIN
					core.donation_account AS account ON
						payout.donation_account_id = account.id
			WHERE
				account.user_account_id = run_payout_totals_report_for_user_account.user_account_id
		);
$$;


--
-- Name: update_payment_method(text, text, text, integer, integer); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.update_payment_method(provider text, provider_payment_method_id text, event_source text, expiration_month integer, expiration_year integer) RETURNS SETOF subscriptions.current_payment_method
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
	version_timestamp CONSTANT timestamp := core.utc_now();
BEGIN
	INSERT INTO
		core.subscription_payment_method_version (
			provider,
			provider_payment_method_id,
			date_created,
			event_source,
			expiration_month,
			expiration_year
		)
	VALUES (
		update_payment_method.provider::core.subscription_provider,
		update_payment_method.provider_payment_method_id,
		locals.version_timestamp,
		update_payment_method.event_source::core.subscription_event_source,
		update_payment_method.expiration_month,
		update_payment_method.expiration_year
	);
	UPDATE
		core.subscription_payment_method AS payment_method
	SET
		current_version_date = locals.version_timestamp
	WHERE
		payment_method.provider = update_payment_method.provider::core.subscription_provider AND
		payment_method.provider_payment_method_id = update_payment_method.provider_payment_method_id;
	RETURN QUERY
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = update_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = update_payment_method.provider_payment_method_id;
END;
$$;


--
-- Name: update_payout_account(text, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: subscriptions; Owner: -
--

CREATE FUNCTION subscriptions.update_payout_account(id text, date_details_submitted timestamp without time zone, date_payouts_enabled timestamp without time zone) RETURNS SETOF core.payout_account
    LANGUAGE sql
    AS $$
	UPDATE
		core.payout_account
	SET
		date_details_submitted = coalesce(payout_account.date_details_submitted, update_payout_account.date_details_submitted),
		date_payouts_enabled = coalesce(payout_account.date_payouts_enabled, update_payout_account.date_payouts_enabled)
	WHERE
		payout_account.id = update_payout_account.id
	RETURNING
		*;
$$;


--
-- Name: auth_service_access_token; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_access_token (
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    last_stored timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    identity_id bigint NOT NULL,
    request_id bigint NOT NULL,
    token_value text NOT NULL,
    token_secret text NOT NULL,
    date_revoked timestamp without time zone
);


--
-- Name: auth_service_association; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_association (
    date_associated timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    identity_id bigint NOT NULL,
    authentication_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    association_method core.auth_service_association_method NOT NULL,
    date_dissociated timestamp without time zone
);


--
-- Name: auth_service_identity; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_identity (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    provider core.auth_service_provider NOT NULL,
    provider_user_id text NOT NULL,
    real_user_rating core.auth_service_real_user_rating,
    sign_up_analytics jsonb
);


--
-- Name: auth_service_user; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_user (
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    identity_id bigint NOT NULL,
    email_address text,
    is_email_address_private boolean NOT NULL,
    name text,
    handle text,
    CONSTRAINT auth_service_user_identifier_check CHECK (((email_address IS NOT NULL) OR (handle IS NOT NULL)))
);


--
-- Name: current_auth_service_access_token; Type: VIEW; Schema: user_account_api; Owner: -
--

CREATE VIEW user_account_api.current_auth_service_access_token AS
 SELECT token.date_created,
    token.last_stored,
    token.identity_id,
    token.request_id,
    token.token_value,
    token.token_secret,
    token.date_revoked
   FROM (core.auth_service_access_token token
     LEFT JOIN core.auth_service_access_token newer_token ON (((newer_token.identity_id = token.identity_id) AND (newer_token.date_created > token.date_created))))
  WHERE (newer_token.date_created IS NULL);


--
-- Name: current_auth_service_user; Type: VIEW; Schema: user_account_api; Owner: -
--

CREATE VIEW user_account_api.current_auth_service_user AS
 SELECT service_user.date_created,
    service_user.identity_id,
    service_user.email_address,
    service_user.is_email_address_private,
    service_user.name,
    service_user.handle
   FROM (core.auth_service_user service_user
     LEFT JOIN core.auth_service_user newer_service_user ON (((newer_service_user.identity_id = service_user.identity_id) AND (newer_service_user.date_created > service_user.date_created))))
  WHERE (newer_service_user.date_created IS NULL);


--
-- Name: auth_service_account; Type: VIEW; Schema: user_account_api; Owner: -
--

CREATE VIEW user_account_api.auth_service_account AS
 SELECT identity.id AS identity_id,
    identity.date_created AS date_identity_created,
    identity.sign_up_analytics AS identity_sign_up_analytics,
    identity.provider,
    identity.provider_user_id,
    current_service_user.email_address AS provider_user_email_address,
    COALESCE(current_service_user.is_email_address_private, false) AS is_email_address_private,
    current_service_user.name AS provider_user_name,
    current_service_user.handle AS provider_user_handle,
    association.date_associated AS date_user_account_associated,
    association.user_account_id AS associated_user_account_id,
    current_active_access_token.token_value AS access_token_value,
    current_active_access_token.token_secret AS access_token_secret
   FROM (((core.auth_service_identity identity
     JOIN user_account_api.current_auth_service_user current_service_user ON ((current_service_user.identity_id = identity.id)))
     LEFT JOIN core.auth_service_association association ON (((association.identity_id = identity.id) AND (association.date_dissociated IS NULL))))
     LEFT JOIN user_account_api.current_auth_service_access_token current_active_access_token ON (((current_active_access_token.identity_id = identity.id) AND (current_active_access_token.date_revoked IS NULL))));


--
-- Name: associate_auth_service_account(bigint, bigint, bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.associate_auth_service_account(identity_id bigint, authentication_id bigint, user_account_id bigint, association_method text) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- insert the new association
    INSERT INTO
        core.auth_service_association (
            identity_id,
            authentication_id,
            user_account_id,
            association_method
        )
    VALUES (
        associate_auth_service_account.identity_id,
        associate_auth_service_account.authentication_id,
        associate_auth_service_account.user_account_id,
        associate_auth_service_account.association_method::core.auth_service_association_method
    );
    -- update cached user_account.has_linked_twitter_account if this is a twitter account
    IF (
        SELECT
            identity.provider = 'twitter'
        FROM
            auth_service_identity AS identity
        WHERE
            identity.id = associate_auth_service_account.identity_id
    ) THEN
        UPDATE
            core.user_account
        SET
            has_linked_twitter_account = true
        WHERE
            user_account.id = associate_auth_service_account.user_account_id;
    END IF;
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = associate_auth_service_account.identity_id;
END;
$$;


--
-- Name: auth_service_request_token; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_request_token (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    provider core.auth_service_provider NOT NULL,
    token_value text NOT NULL,
    token_secret text NOT NULL,
    date_cancelled timestamp without time zone,
    sign_up_analytics jsonb
);


--
-- Name: cancel_auth_service_request_token(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.cancel_auth_service_request_token(token_value text) RETURNS SETOF core.auth_service_request_token
    LANGUAGE sql
    AS $$
    UPDATE
        core.auth_service_request_token
    SET
        date_cancelled = core.utc_now()
    WHERE
        auth_service_request_token.token_value = cancel_auth_service_request_token.token_value
    RETURNING
        *;
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
-- Name: auth_service_authentication; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_authentication (
    id bigint NOT NULL,
    date_authenticated timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    identity_id bigint NOT NULL,
    session_id text
);


--
-- Name: create_auth_service_authentication(bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_auth_service_authentication(identity_id bigint, session_id text) RETURNS SETOF core.auth_service_authentication
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.auth_service_authentication (
            identity_id,
            session_id
        )
    VALUES (
        create_auth_service_authentication.identity_id,
        create_auth_service_authentication.session_id
    )
    RETURNING
        *;
$$;


--
-- Name: create_auth_service_identity(text, text, text, boolean, text, text, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_auth_service_identity(provider text, provider_user_id text, provider_user_email_address text, is_email_address_private boolean, provider_user_name text, provider_user_handle text, real_user_rating text, sign_up_analytics text) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    identity_id bigint;
BEGIN
	-- create the identity
    INSERT INTO
		core.auth_service_identity (
    		provider,
			provider_user_id,
			real_user_rating,
			sign_up_analytics
    	)
    VALUES (
      	create_auth_service_identity.provider::core.auth_service_provider,
        create_auth_service_identity.provider_user_id,
        create_auth_service_identity.real_user_rating::core.auth_service_real_user_rating,
        create_auth_service_identity.sign_up_analytics::jsonb
	)
	RETURNING
		id INTO locals.identity_id;
    -- create the user
    INSERT INTO
        core.auth_service_user (
        	identity_id,
        	email_address,
        	is_email_address_private,
        	name,
        	handle
		)
	VALUES (
	    locals.identity_id,
	    create_auth_service_identity.provider_user_email_address,
	    create_auth_service_identity.is_email_address_private,
	    create_auth_service_identity.provider_user_name,
	    create_auth_service_identity.provider_user_handle
    );
	-- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = locals.identity_id;
END;
$$;


--
-- Name: auth_service_post; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_post (
    id bigint NOT NULL,
    identity_id bigint NOT NULL,
    date_posted timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    comment_id bigint,
    silent_post_id bigint,
    content text NOT NULL,
    provider_post_id text NOT NULL,
    CONSTRAINT auth_service_post_reference_check CHECK (((comment_id IS NOT NULL) OR (silent_post_id IS NOT NULL)))
);


--
-- Name: create_auth_service_post(bigint, bigint, bigint, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_auth_service_post(identity_id bigint, comment_id bigint, silent_post_id bigint, content text, provider_post_id text) RETURNS SETOF core.auth_service_post
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.auth_service_post (
            identity_id,
            comment_id,
            silent_post_id,
            content,
            provider_post_id
        )
    VALUES (
        create_auth_service_post.identity_id,
        create_auth_service_post.comment_id,
        create_auth_service_post.silent_post_id,
        create_auth_service_post.content,
        create_auth_service_post.provider_post_id
    )
    RETURNING
        *;
$$;


--
-- Name: auth_service_refresh_token; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.auth_service_refresh_token (
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    identity_id bigint NOT NULL,
    raw_value text NOT NULL
);


--
-- Name: create_auth_service_refresh_token(bigint, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_auth_service_refresh_token(identity_id bigint, raw_value text) RETURNS SETOF core.auth_service_refresh_token
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.auth_service_refresh_token (
            identity_id,
            raw_value
        )
    VALUES (
        create_auth_service_refresh_token.identity_id,
        create_auth_service_refresh_token.raw_value
    )
    RETURNING
        *;
$$;


--
-- Name: create_auth_service_request_token(text, text, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_auth_service_request_token(provider text, token_value text, token_secret text, sign_up_analytics text) RETURNS SETOF core.auth_service_request_token
    LANGUAGE sql
    AS $$
    INSERT INTO
        core.auth_service_request_token (
            provider,
            token_value,
            token_secret,
            sign_up_analytics
        )
    VALUES (
        create_auth_service_request_token.provider::core.auth_service_provider,
        create_auth_service_request_token.token_value,
        create_auth_service_request_token.token_secret,
        create_auth_service_request_token.sign_up_analytics::jsonb
    )
    RETURNING
        *;
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
    date_completed timestamp without time zone,
    auth_service_authentication_id bigint
);


--
-- Name: create_password_reset_request(bigint, bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_password_reset_request(user_account_id bigint, auth_service_authentication_id bigint) RETURNS SETOF core.password_reset_request
    LANGUAGE sql
    AS $$
	INSERT INTO password_reset_request (
	    user_account_id,
	    email_address,
	    auth_service_authentication_id
	)
	VALUES (
	    user_account_id,
	    (
	        SELECT
	            email
	        FROM
	            core.user_account
	        WHERE
	            user_account.id = create_password_reset_request.user_account_id
	    ),
	    create_password_reset_request.auth_service_authentication_id
	)
	RETURNING
	    *;
$$;


--
-- Name: provisional_user_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.provisional_user_account (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    date_merged timestamp without time zone,
    merged_user_account_id bigint,
    creation_analytics jsonb,
    CONSTRAINT provisional_user_account_merge_check CHECK ((((date_merged IS NULL) AND (merged_user_account_id IS NULL)) OR ((date_merged IS NOT NULL) AND (merged_user_account_id IS NOT NULL))))
);


--
-- Name: create_provisional_user_account(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_provisional_user_account(analytics text) RETURNS SETOF core.provisional_user_account
    LANGUAGE sql
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


--
-- Name: create_user_account(text, text, bytea, bytea, bigint, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.create_user_account(name text, email text, password_hash bytea, password_salt bytea, time_zone_id bigint, theme text, analytics text) RETURNS SETOF core.user_account
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    new_user core.user_account;
BEGIN
    -- create new user
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
            trim(
                create_user_account.name
            ),
            trim(
                create_user_account.email
            ),
            create_user_account.password_hash,
            create_user_account.password_salt,
            create_user_account.time_zone_id,
            create_user_account.analytics::json
        )
    RETURNING
        *
    INTO
        locals.new_user;
    -- set initial notification preference
    INSERT INTO
        core.notification_preference (
            user_account_id
        )
	VALUES (
	    locals.new_user.id
    );
    -- set initial display preference if a theme is provided
     IF create_user_account.theme IS NOT NULL THEN
        PERFORM
            user_account_api.set_display_preference(
                user_account_id => locals.new_user.id,
                theme => create_user_account.theme,
                text_size => 1,
                hide_links => TRUE
            );
    END IF;
    -- return user
    RETURN NEXT
        locals.new_user;
END;
$$;


--
-- Name: delete_user_account(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.delete_user_account(user_account_id bigint) RETURNS SETOF core.user_account
    LANGUAGE plpgsql
    AS $$
BEGIN
	-- Update the user_account record, resetting the name, email and password and setting date_deleted.
	UPDATE
		core.user_account
	SET
		name = '[deleted_' || user_account.id || ']',
		email = '[deleted_' || user_account.id || ']',
		password_hash = E'\\xD78E59C4DC5CED432D999322DC0A773C5085D8D0F33D02EFFDB8AA1CD743E02A',
		password_salt = E'\\xE4522D33AB44B5C9026312450C9D2A19',
		creation_analytics = user_account.creation_analytics || jsonb_build_object(
			'deletion',
			jsonb_build_object('name', user_account.name, 'email', user_account.email)
		),
		date_deleted = core.utc_now()
	WHERE
		user_account.id = delete_user_account.user_account_id AND
		user_account.date_deleted IS NULL;

	-- Delete all comments.
	UPDATE
		core.comment
	SET
		date_deleted = core.utc_now()
	WHERE
		comment.user_account_id = delete_user_account.user_account_id AND
		comment.date_deleted IS NULL;

	-- Delete all silent posts.
	UPDATE
		core.silent_post
	SET
		date_deleted = core.utc_now()
	WHERE
		silent_post.user_account_id = delete_user_account.user_account_id AND
		silent_post.date_deleted IS NULL;

	-- Disable all followings.
	UPDATE
		core.following
	SET
		date_unfollowed = core.utc_now(),
		unfollow_analytics = jsonb_build_object('action', 'account_deletion')
	WHERE
		(
			following.follower_user_account_id = delete_user_account.user_account_id OR
			following.followee_user_account_id = delete_user_account.user_account_id
		) AND
		date_unfollowed IS NULL;

	-- Disable all notifications.
	PERFORM
		notifications.set_preference(
			user_account_id := delete_user_account.user_account_id,
			company_update_via_email := FALSE,
			aotd_via_email := FALSE,
			aotd_via_extension := FALSE,
			aotd_via_push := FALSE,
			aotd_digest_via_email := 'never',
			reply_via_email := FALSE,
			reply_via_extension := FALSE,
			reply_via_push := FALSE,
			reply_digest_via_email := 'never',
			loopback_via_email := FALSE,
			loopback_via_extension := FALSE,
			loopback_via_push := FALSE,
			loopback_digest_via_email := 'never',
			post_via_email := FALSE,
			post_via_extension := FALSE,
			post_via_push := FALSE,
			post_digest_via_email := 'never',
			follower_via_email := FALSE,
			follower_via_extension := FALSE,
			follower_via_push := FALSE,
			follower_digest_via_email := 'never'
		);

	-- Return the user_account.
	RETURN QUERY
	SELECT
		*
	FROM
		user_account_api.get_user_account_by_id(
			user_account_id := delete_user_account.user_account_id
		);
END;
$$;


--
-- Name: disassociate_auth_service_account(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.disassociate_auth_service_account(identity_id bigint) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    disassociated_user_account_id bigint;
BEGIN
    -- update the association
    UPDATE
        core.auth_service_association
    SET
        date_dissociated = core.utc_now()
    WHERE
        auth_service_association.identity_id = disassociate_auth_service_account.identity_id AND
        auth_service_association.date_dissociated IS NULL
    RETURNING
        auth_service_association.user_account_id INTO locals.disassociated_user_account_id;
    -- revoke access token if present
    UPDATE
        core.auth_service_access_token
    SET
        date_revoked = core.utc_now()
    FROM
        user_account_api.current_auth_service_access_token
    WHERE
        auth_service_access_token.identity_id = disassociate_auth_service_account.identity_id AND
        auth_service_access_token.identity_id = current_auth_service_access_token.identity_id AND
        auth_service_access_token.date_created = current_auth_service_access_token.date_created AND
        auth_service_access_token.date_revoked IS NULL;
    -- update cached user_account.has_linked_twitter_account if this was the last twitter account
    IF (
        NOT EXISTS (
            SELECT
                *
            FROM
                user_account_api.auth_service_account
            WHERE
                auth_service_account.associated_user_account_id = locals.disassociated_user_account_id AND
                auth_service_account.provider = 'twitter'
        )
    )
    THEN
        UPDATE
            core.user_account
        SET
            has_linked_twitter_account = false
        WHERE
            user_account.id = locals.disassociated_user_account_id;
    END IF;
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = disassociate_auth_service_account.identity_id;
END;
$$;


--
-- Name: get_auth_service_account_by_identity_id(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_auth_service_account_by_identity_id(identity_id bigint) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.identity_id = get_auth_service_account_by_identity_id.identity_id;
$$;


--
-- Name: get_auth_service_account_by_provider_user_id(text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_auth_service_account_by_provider_user_id(provider text, provider_user_id text) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.provider = get_auth_service_account_by_provider_user_id.provider::core.auth_service_provider AND
    	auth_service_account.provider_user_id = get_auth_service_account_by_provider_user_id.provider_user_id;
$$;


--
-- Name: get_auth_service_accounts_for_user_account(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_auth_service_accounts_for_user_account(user_account_id bigint) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE sql STABLE
    AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.associated_user_account_id = get_auth_service_accounts_for_user_account.user_account_id;
$$;


--
-- Name: get_auth_service_authentication_by_id(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_auth_service_authentication_by_id(authentication_id bigint) RETURNS SETOF core.auth_service_authentication
    LANGUAGE sql STABLE
    AS $$
    SELECT
        *
    FROM
        core.auth_service_authentication AS authentication
    WHERE
        authentication.id =  get_auth_service_authentication_by_id.authentication_id;
$$;


--
-- Name: get_auth_service_request_token(text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_auth_service_request_token(token_value text) RETURNS SETOF core.auth_service_request_token
    LANGUAGE sql
    AS $$
    SELECT
        *
    FROM
        core.auth_service_request_token
    WHERE
        auth_service_request_token.token_value = get_auth_service_request_token.token_value;
$$;


--
-- Name: display_preference; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.display_preference (
    id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    last_modified timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    theme core.display_theme NOT NULL,
    text_size integer NOT NULL,
    hide_links boolean NOT NULL
);


--
-- Name: get_display_preference(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.get_display_preference(user_account_id bigint) RETURNS SETOF core.display_preference
    LANGUAGE sql STABLE
    AS $$
    SELECT
        *
    FROM
        user_account_api.current_display_preference
    WHERE
        current_display_preference.user_account_id = get_display_preference.user_account_id;
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
-- Name: merge_provisional_user_account(bigint, bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.merge_provisional_user_account(provisional_user_account_id bigint, user_account_id bigint) RETURNS SETOF core.provisional_user_account
    LANGUAGE plpgsql
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
            date_viewed,
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
        provisional_user_article.date_viewed,
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


--
-- Name: register_orientation_completion(bigint); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.register_orientation_completion(user_account_id bigint) RETURNS SETOF core.user_account
    LANGUAGE sql
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


--
-- Name: set_display_preference(bigint, text, integer, boolean); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.set_display_preference(user_account_id bigint, theme text, text_size integer, hide_links boolean) RETURNS SETOF core.display_preference
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    existing_preference_id bigint;
BEGIN
    -- check for an existing record
	SELECT
		preference.id
    INTO
    	locals.existing_preference_id
    FROM
    	core.display_preference AS preference
    WHERE
    	preference.user_account_id = set_display_preference.user_account_id AND
    	preference.last_modified >= core.utc_now() - '1 hour'::interval
    ORDER BY
    	preference.last_modified DESC
    LIMIT
        1
    FOR UPDATE;
    -- update the existing record or create a new one
    IF locals.existing_preference_id IS NOT NULL THEN
        RETURN QUERY
		UPDATE
		    core.display_preference
        SET
            last_modified = core.utc_now(),
            theme = set_display_preference.theme::core.display_theme,
            text_size = set_display_preference.text_size,
            hide_links = set_display_preference.hide_links
        WHERE
        	display_preference.id = locals.existing_preference_id
        RETURNING
            *;
	ELSE
	    RETURN QUERY
    	INSERT INTO
    	    core.display_preference (
    	        user_account_id,
    	        theme,
    	        text_size,
    	        hide_links
			)
		VALUES (
		    set_display_preference.user_account_id,
		    set_display_preference.theme::core.display_theme,
		    set_display_preference.text_size,
		    set_display_preference.hide_links
		)
		RETURNING
		    *;
    END IF;
END;
$$;


--
-- Name: store_auth_service_access_token(bigint, bigint, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.store_auth_service_access_token(identity_id bigint, request_id bigint, token_value text, token_secret text) RETURNS SETOF core.auth_service_access_token
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    current_token_value CONSTANT text := (
        SELECT
            token.token_value
        FROM
            user_account_api.current_auth_service_access_token AS token
        WHERE
            token.identity_id = store_auth_service_access_token.identity_id
    );
BEGIN
    IF locals.current_token_value = store_auth_service_access_token.token_value THEN
        RETURN QUERY
        UPDATE
            core.auth_service_access_token AS access_token
        SET
            last_stored = core.utc_now()
        WHERE
            access_token.token_value = locals.current_token_value
        RETURNING
            *;
    ELSE
        IF locals.current_token_value IS NOT NULL THEN
            UPDATE
                core.auth_service_access_token
            SET
                date_revoked = core.utc_now()
            WHERE
                auth_service_access_token.token_value = locals.current_token_value;
        END IF;
        RETURN QUERY
        INSERT INTO
            core.auth_service_access_token (
                identity_id,
                request_id,
                token_value,
                token_secret
            )
        VALUES (
            store_auth_service_access_token.identity_id,
            store_auth_service_access_token.request_id,
            store_auth_service_access_token.token_value,
            store_auth_service_access_token.token_secret
        )
        RETURNING
            *;
    END IF;
END;
$$;


--
-- Name: update_auth_service_account_user(bigint, text, boolean, text, text); Type: FUNCTION; Schema: user_account_api; Owner: -
--

CREATE FUNCTION user_account_api.update_auth_service_account_user(identity_id bigint, email_address text, is_email_address_private boolean, name text, handle text) RETURNS SETOF user_account_api.auth_service_account
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- insert the new user
    INSERT INTO
        core.auth_service_user (
            identity_id,
            email_address,
            is_email_address_private,
            name,
            handle
        )
    VALUES (
        update_auth_service_account_user.identity_id,
        update_auth_service_account_user.email_address,
        update_auth_service_account_user.is_email_address_private,
        update_auth_service_account_user.name,
        update_auth_service_account_user.handle
    );
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = update_auth_service_account_user.identity_id;
END;
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
    name text NOT NULL,
    slug text NOT NULL
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
-- Name: article_pages; Type: VIEW; Schema: articles; Owner: -
--

CREATE VIEW articles.article_pages AS
 SELECT array_agg(page.url ORDER BY page.number) AS urls,
    count(*) AS count,
    sum(page.word_count) AS word_count,
    sum(page.readable_word_count) AS readable_word_count,
    page.article_id
   FROM core.page
  GROUP BY page.article_id;


--
-- Name: article_tags; Type: VIEW; Schema: articles; Owner: -
--

CREATE VIEW articles.article_tags AS
 SELECT array_agg(tag.name) AS names,
    article_tag.article_id
   FROM (core.tag
     JOIN core.article_tag ON ((article_tag.tag_id = tag.id)))
  GROUP BY article_tag.article_id;


--
-- Name: primary_article_image; Type: VIEW; Schema: articles; Owner: -
--

CREATE VIEW articles.primary_article_image AS
 SELECT DISTINCT ON (article_image.article_id) article_image.article_id,
    article_image.url
   FROM core.article_image
  ORDER BY article_image.article_id, article_image.date_created DESC;


--
-- Name: user_article_rating; Type: VIEW; Schema: articles; Owner: -
--

CREATE VIEW articles.user_article_rating AS
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
    flair core.article_flair,
    aotd_contender_rank integer DEFAULT 0 NOT NULL,
    community_read_timestamp timestamp without time zone,
    latest_read_timestamp timestamp without time zone,
    latest_post_timestamp timestamp without time zone
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
    article.average_rating_score,
    article.date_published,
    article.source_id,
    article.community_read_timestamp,
    article.latest_read_timestamp,
    article.latest_post_timestamp
   FROM core.article
  WHERE (article.community_read_timestamp IS NOT NULL);


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
-- Name: article_issue_report; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.article_issue_report (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    article_id bigint NOT NULL,
    user_account_id bigint NOT NULL,
    issue text NOT NULL,
    analytics jsonb
);


--
-- Name: article_issue_report_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.article_issue_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_issue_report_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.article_issue_report_id_seq OWNED BY core.article_issue_report.id;


--
-- Name: auth_service_authentication_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.auth_service_authentication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_service_authentication_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.auth_service_authentication_id_seq OWNED BY core.auth_service_authentication.id;


--
-- Name: auth_service_identity_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.auth_service_identity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_service_identity_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.auth_service_identity_id_seq OWNED BY core.auth_service_identity.id;


--
-- Name: auth_service_post_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.auth_service_post_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_service_post_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.auth_service_post_id_seq OWNED BY core.auth_service_post.id;


--
-- Name: auth_service_request_token_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.auth_service_request_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_service_request_token_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.auth_service_request_token_id_seq OWNED BY core.auth_service_request_token.id;


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
-- Name: author_user_account_assignment_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.author_user_account_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: author_user_account_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.author_user_account_assignment_id_seq OWNED BY core.author_user_account_assignment.id;


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
-- Name: display_preference_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.display_preference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: display_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.display_preference_id_seq OWNED BY core.display_preference.id;


--
-- Name: donation_account; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.donation_account (
    id bigint NOT NULL,
    author_id bigint,
    user_account_id bigint,
    date_created timestamp without time zone NOT NULL,
    date_user_account_assigned timestamp without time zone,
    donation_recipient_id bigint NOT NULL,
    CONSTRAINT donation_account_principal_check CHECK ((((author_id IS NOT NULL) AND (user_account_id IS NULL) AND (date_user_account_assigned IS NULL)) OR ((author_id IS NULL) AND (user_account_id IS NOT NULL) AND (date_user_account_assigned IS NOT NULL))))
);


--
-- Name: donation_account_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.donation_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donation_account_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.donation_account_id_seq OWNED BY core.donation_account.id;


--
-- Name: donation_payout; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.donation_payout (
    id bigint NOT NULL,
    date_created timestamp without time zone NOT NULL,
    donation_account_id bigint NOT NULL,
    donation_recipient_id bigint NOT NULL,
    amount integer NOT NULL,
    receipt text NOT NULL
);


--
-- Name: donation_payout_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.donation_payout_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donation_payout_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.donation_payout_id_seq OWNED BY core.donation_payout.id;


--
-- Name: donation_recipient_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.donation_recipient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: donation_recipient_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.donation_recipient_id_seq OWNED BY core.donation_recipient.id;


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
-- Name: free_trial_credit_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.free_trial_credit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: free_trial_credit_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.free_trial_credit_id_seq OWNED BY core.free_trial_credit.id;


--
-- Name: new_platform_notification_request; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.new_platform_notification_request (
    id bigint NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    email_address character varying(512) NOT NULL,
    ip_address text NOT NULL,
    user_agent text NOT NULL
);


--
-- Name: new_platform_notification_request_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.new_platform_notification_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_platform_notification_request_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.new_platform_notification_request_id_seq OWNED BY core.new_platform_notification_request.id;


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
    bulk_email_body text,
    bulk_email_subscription_status_filter notifications.bulk_email_subscription_status_filter,
    bulk_email_free_for_life_filter boolean,
    bulk_email_user_created_after_filter timestamp without time zone,
    bulk_email_user_created_before_filter timestamp without time zone
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
-- Name: orientation_analytics; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.orientation_analytics (
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    user_account_id bigint NOT NULL,
    tracking_play_count integer NOT NULL,
    tracking_skipped boolean NOT NULL,
    tracking_duration integer NOT NULL,
    import_play_count integer NOT NULL,
    import_skipped boolean NOT NULL,
    import_duration integer NOT NULL,
    notifications_result core.notification_authorization_request_result NOT NULL,
    notifications_skipped boolean NOT NULL,
    notifications_duration integer NOT NULL,
    share_result_id uuid,
    share_skipped boolean NOT NULL,
    share_duration integer NOT NULL
);


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
-- Name: post; Type: VIEW; Schema: core; Owner: -
--

CREATE VIEW core.post AS
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
    silent_post.date_deleted
   FROM core.silent_post;


--
-- Name: provisional_user_account_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.provisional_user_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provisional_user_account_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.provisional_user_account_id_seq OWNED BY core.provisional_user_account.id;


--
-- Name: provisional_user_article_progress; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.provisional_user_article_progress (
    provisional_user_account_id bigint NOT NULL,
    article_id bigint NOT NULL,
    period timestamp without time zone NOT NULL,
    words_read integer NOT NULL,
    client_type text
);


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
-- Name: share_result; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.share_result (
    id uuid NOT NULL,
    date_created timestamp without time zone DEFAULT core.utc_now() NOT NULL,
    client_type text NOT NULL,
    user_account_id bigint,
    action text NOT NULL,
    activity_type text NOT NULL,
    completed boolean,
    error text
);


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
-- Name: subscription_default_payment_method; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_default_payment_method (
    provider core.subscription_provider NOT NULL,
    provider_account_id text NOT NULL,
    date_assigned timestamp without time zone NOT NULL,
    date_unassigned timestamp without time zone,
    provider_payment_method_id text NOT NULL
);


--
-- Name: subscription_period_author_distribution; Type: TABLE; Schema: core; Owner: -
--

CREATE TABLE core.subscription_period_author_distribution (
    provider core.subscription_provider NOT NULL,
    provider_period_id text NOT NULL,
    author_id integer NOT NULL,
    minutes_read integer NOT NULL,
    amount integer NOT NULL
);


--
-- Name: subscription_renewal_status_change_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.subscription_renewal_status_change_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscription_renewal_status_change_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.subscription_renewal_status_change_id_seq OWNED BY core.subscription_renewal_status_change.id;


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
-- Name: twitter_bot_tweet_id_seq; Type: SEQUENCE; Schema: core; Owner: -
--

CREATE SEQUENCE core.twitter_bot_tweet_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: twitter_bot_tweet_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: -
--

ALTER SEQUENCE core.twitter_bot_tweet_id_seq OWNED BY core.twitter_bot_tweet.id;


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
     JOIN core.post ON ((post.article_id = article.id)))
     LEFT JOIN core.post earlier_post ON (((earlier_post.article_id = post.article_id) AND (earlier_post.date_created < post.date_created))))
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
-- Name: current_default_payment_method; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.current_default_payment_method AS
 SELECT current_method.provider,
    current_method.provider_payment_method_id,
    current_method.provider_account_id,
    current_method.date_created,
    current_method.wallet,
    current_method.brand,
    current_method.last_four_digits,
    current_method.country,
    current_method.expiration_month,
    current_method.expiration_year
   FROM (subscriptions.current_payment_method current_method
     JOIN core.subscription_default_payment_method default_method ON (((current_method.provider = default_method.provider) AND (current_method.provider_payment_method_id = default_method.provider_payment_method_id) AND (current_method.provider_account_id = default_method.provider_account_id))))
  WHERE (default_method.date_unassigned IS NULL);


--
-- Name: user_account_subscription_status; Type: VIEW; Schema: subscriptions; Owner: -
--

CREATE VIEW subscriptions.user_account_subscription_status AS
 SELECT DISTINCT ON (status.user_account_id) status.user_account_id,
    status.provider,
    status.provider_account_id,
    status.provider_subscription_id,
    status.date_created,
    status.latest_receipt,
    status.latest_period,
    status.latest_renewal_status_change
   FROM subscriptions.subscription_status status
  ORDER BY status.user_account_id, GREATEST((status.latest_period).date_created, (status.latest_period).date_paid) DESC;


--
-- Name: current_display_preference; Type: VIEW; Schema: user_account_api; Owner: -
--

CREATE VIEW user_account_api.current_display_preference AS
 SELECT current_preference.id,
    current_preference.user_account_id,
    current_preference.last_modified,
    current_preference.theme,
    current_preference.text_size,
    current_preference.hide_links
   FROM (core.display_preference current_preference
     LEFT JOIN core.display_preference later_preference ON (((later_preference.user_account_id = current_preference.user_account_id) AND (later_preference.last_modified > current_preference.last_modified))))
  WHERE (later_preference.id IS NULL);


--
-- Name: article id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article ALTER COLUMN id SET DEFAULT nextval('core.article_id_seq'::regclass);


--
-- Name: article_issue_report id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_issue_report ALTER COLUMN id SET DEFAULT nextval('core.article_issue_report_id_seq'::regclass);


--
-- Name: auth_service_authentication id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_authentication ALTER COLUMN id SET DEFAULT nextval('core.auth_service_authentication_id_seq'::regclass);


--
-- Name: auth_service_identity id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_identity ALTER COLUMN id SET DEFAULT nextval('core.auth_service_identity_id_seq'::regclass);


--
-- Name: auth_service_post id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_post ALTER COLUMN id SET DEFAULT nextval('core.auth_service_post_id_seq'::regclass);


--
-- Name: auth_service_request_token id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_request_token ALTER COLUMN id SET DEFAULT nextval('core.auth_service_request_token_id_seq'::regclass);


--
-- Name: author id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author ALTER COLUMN id SET DEFAULT nextval('core.author_id_seq'::regclass);


--
-- Name: author_user_account_assignment id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment ALTER COLUMN id SET DEFAULT nextval('core.author_user_account_assignment_id_seq'::regclass);


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
-- Name: display_preference id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.display_preference ALTER COLUMN id SET DEFAULT nextval('core.display_preference_id_seq'::regclass);


--
-- Name: donation_account id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_account ALTER COLUMN id SET DEFAULT nextval('core.donation_account_id_seq'::regclass);


--
-- Name: donation_payout id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_payout ALTER COLUMN id SET DEFAULT nextval('core.donation_payout_id_seq'::regclass);


--
-- Name: donation_recipient id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_recipient ALTER COLUMN id SET DEFAULT nextval('core.donation_recipient_id_seq'::regclass);


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
-- Name: free_trial_credit id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.free_trial_credit ALTER COLUMN id SET DEFAULT nextval('core.free_trial_credit_id_seq'::regclass);


--
-- Name: new_platform_notification_request id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.new_platform_notification_request ALTER COLUMN id SET DEFAULT nextval('core.new_platform_notification_request_id_seq'::regclass);


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
-- Name: provisional_user_account id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_account ALTER COLUMN id SET DEFAULT nextval('core.provisional_user_account_id_seq'::regclass);


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
-- Name: subscription_renewal_status_change id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_renewal_status_change ALTER COLUMN id SET DEFAULT nextval('core.subscription_renewal_status_change_id_seq'::regclass);


--
-- Name: tag id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag ALTER COLUMN id SET DEFAULT nextval('core.tag_id_seq'::regclass);


--
-- Name: twitter_bot_tweet id; Type: DEFAULT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.twitter_bot_tweet ALTER COLUMN id SET DEFAULT nextval('core.twitter_bot_tweet_id_seq'::regclass);


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
-- Name: article_image article_image_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_image
    ADD CONSTRAINT article_image_pkey PRIMARY KEY (article_id, url);


--
-- Name: article_issue_report article_issue_report_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_issue_report
    ADD CONSTRAINT article_issue_report_pkey PRIMARY KEY (id);


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
-- Name: auth_service_access_token auth_service_access_token_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_access_token
    ADD CONSTRAINT auth_service_access_token_pkey PRIMARY KEY (date_created, identity_id);


--
-- Name: auth_service_access_token auth_service_access_token_token_value_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_access_token
    ADD CONSTRAINT auth_service_access_token_token_value_key UNIQUE (token_value);


--
-- Name: auth_service_association auth_service_association_authentication_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_association
    ADD CONSTRAINT auth_service_association_authentication_id_key UNIQUE (authentication_id);


--
-- Name: auth_service_association auth_service_association_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_association
    ADD CONSTRAINT auth_service_association_pkey PRIMARY KEY (date_associated, identity_id);


--
-- Name: auth_service_authentication auth_service_authentication_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_authentication
    ADD CONSTRAINT auth_service_authentication_pkey PRIMARY KEY (id);


--
-- Name: auth_service_identity auth_service_identity_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_identity
    ADD CONSTRAINT auth_service_identity_pkey PRIMARY KEY (id);


--
-- Name: auth_service_identity auth_service_identity_provider_provider_user_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_identity
    ADD CONSTRAINT auth_service_identity_provider_provider_user_id_key UNIQUE (provider, provider_user_id);


--
-- Name: auth_service_post auth_service_post_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_post
    ADD CONSTRAINT auth_service_post_pkey PRIMARY KEY (id);


--
-- Name: auth_service_refresh_token auth_service_refresh_token_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_refresh_token
    ADD CONSTRAINT auth_service_refresh_token_pkey PRIMARY KEY (date_created, identity_id);


--
-- Name: auth_service_request_token auth_service_request_token_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_request_token
    ADD CONSTRAINT auth_service_request_token_pkey PRIMARY KEY (id);


--
-- Name: auth_service_request_token auth_service_request_token_token_value_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_request_token
    ADD CONSTRAINT auth_service_request_token_token_value_key UNIQUE (token_value);


--
-- Name: auth_service_user auth_service_user_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_user
    ADD CONSTRAINT auth_service_user_pkey PRIMARY KEY (date_created, identity_id);


--
-- Name: author_payout author_payout_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_payout
    ADD CONSTRAINT author_payout_pkey PRIMARY KEY (id);


--
-- Name: author author_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: author author_slug_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author
    ADD CONSTRAINT author_slug_key UNIQUE (slug);


--
-- Name: author_user_account_assignment author_user_account_assignment_author_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment
    ADD CONSTRAINT author_user_account_assignment_author_id_key UNIQUE (author_id);


--
-- Name: author_user_account_assignment author_user_account_assignment_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment
    ADD CONSTRAINT author_user_account_assignment_pkey PRIMARY KEY (id);


--
-- Name: author_user_account_assignment author_user_account_assignment_user_account_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment
    ADD CONSTRAINT author_user_account_assignment_user_account_id_key UNIQUE (user_account_id);


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
-- Name: donation_account donation_account_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_account
    ADD CONSTRAINT donation_account_pkey PRIMARY KEY (id);


--
-- Name: donation_payout donation_payout_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_payout
    ADD CONSTRAINT donation_payout_pkey PRIMARY KEY (id);


--
-- Name: donation_recipient donation_recipient_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_recipient
    ADD CONSTRAINT donation_recipient_pkey PRIMARY KEY (id);


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
-- Name: free_trial_credit free_trial_credit_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.free_trial_credit
    ADD CONSTRAINT free_trial_credit_pkey PRIMARY KEY (id);


--
-- Name: free_trial_credit free_trial_credit_user_account_credit_limit_idx; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.free_trial_credit
    ADD CONSTRAINT free_trial_credit_user_account_credit_limit_idx UNIQUE (user_account_id, credit_trigger);


--
-- Name: new_platform_notification_request new_platform_notification_request_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.new_platform_notification_request
    ADD CONSTRAINT new_platform_notification_request_pkey PRIMARY KEY (id);


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
-- Name: notification_event notification_event_type_reference; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_event
    ADD CONSTRAINT notification_event_type_reference UNIQUE (type, id);


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
-- Name: orientation_analytics orientation_analytics_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.orientation_analytics
    ADD CONSTRAINT orientation_analytics_pkey PRIMARY KEY (date_created, user_account_id);


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
-- Name: payout_account payout_account_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.payout_account
    ADD CONSTRAINT payout_account_pkey PRIMARY KEY (id);


--
-- Name: payout_account payout_account_user_account_id_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.payout_account
    ADD CONSTRAINT payout_account_user_account_id_key UNIQUE (user_account_id);


--
-- Name: provisional_user_account provisional_user_account_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_account
    ADD CONSTRAINT provisional_user_account_pkey PRIMARY KEY (id);


--
-- Name: provisional_user_article provisional_user_article_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article
    ADD CONSTRAINT provisional_user_article_pkey PRIMARY KEY (article_id, provisional_user_account_id);


--
-- Name: provisional_user_article_progress provisional_user_article_progress_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article_progress
    ADD CONSTRAINT provisional_user_article_progress_pkey PRIMARY KEY (provisional_user_account_id, article_id, period);


--
-- Name: rating rating_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.rating
    ADD CONSTRAINT rating_pkey PRIMARY KEY (id);


--
-- Name: share_result share_result_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.share_result
    ADD CONSTRAINT share_result_pkey PRIMARY KEY (id);


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
-- Name: subscription_account subscription_account_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_account
    ADD CONSTRAINT subscription_account_pkey PRIMARY KEY (provider, provider_account_id);


--
-- Name: subscription_default_payment_method subscription_default_payment_method_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_default_payment_method
    ADD CONSTRAINT subscription_default_payment_method_pkey PRIMARY KEY (provider, provider_account_id, date_assigned);


--
-- Name: subscription_level subscription_level_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_level
    ADD CONSTRAINT subscription_level_pkey PRIMARY KEY (id);


--
-- Name: subscription_payment_method subscription_payment_method_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_payment_method
    ADD CONSTRAINT subscription_payment_method_pkey PRIMARY KEY (provider, provider_payment_method_id);


--
-- Name: subscription_payment_method_version subscription_payment_method_version_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_payment_method_version
    ADD CONSTRAINT subscription_payment_method_version_pkey PRIMARY KEY (provider, provider_payment_method_id, date_created);


--
-- Name: subscription_period_author_distribution subscription_period_author_distribution_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period_author_distribution
    ADD CONSTRAINT subscription_period_author_distribution_pkey PRIMARY KEY (provider, provider_period_id, author_id);


--
-- Name: subscription_period_distribution subscription_period_distribution_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period_distribution
    ADD CONSTRAINT subscription_period_distribution_pkey PRIMARY KEY (provider, provider_period_id);


--
-- Name: subscription_period subscription_period_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period
    ADD CONSTRAINT subscription_period_pkey PRIMARY KEY (provider, provider_period_id);


--
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (provider, provider_subscription_id);


--
-- Name: subscription_price subscription_price_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_price
    ADD CONSTRAINT subscription_price_pkey PRIMARY KEY (provider, provider_price_id);


--
-- Name: subscription_price subscription_price_unique_custom_amount_idx; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_price
    ADD CONSTRAINT subscription_price_unique_custom_amount_idx UNIQUE (provider, custom_amount);


--
-- Name: subscription_price subscription_price_unique_level_idx; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_price
    ADD CONSTRAINT subscription_price_unique_level_idx UNIQUE (provider, level_id);


--
-- Name: subscription_renewal_status_change subscription_renewal_status_change_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_renewal_status_change
    ADD CONSTRAINT subscription_renewal_status_change_pkey PRIMARY KEY (id);


--
-- Name: tag tag_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);


--
-- Name: tag tag_slug_key; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.tag
    ADD CONSTRAINT tag_slug_key UNIQUE (slug);


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
-- Name: twitter_bot_tweet twitter_bot_tweet_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.twitter_bot_tweet
    ADD CONSTRAINT twitter_bot_tweet_pkey PRIMARY KEY (id);


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
-- Name: user_article user_article_unique_article_id_user_account_id; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_article_unique_article_id_user_account_id UNIQUE (article_id, user_account_id);


--
-- Name: user_article user_page_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_page_pkey PRIMARY KEY (id);


--
-- Name: website_traffic_weekly_total website_traffic_weekly_total_pkey; Type: CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.website_traffic_weekly_total
    ADD CONSTRAINT website_traffic_weekly_total_pkey PRIMARY KEY (week);


--
-- Name: article_aotd_timestamp_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_aotd_timestamp_idx ON core.article USING btree (aotd_timestamp DESC NULLS LAST);


--
-- Name: article_community_read_timestamp_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_community_read_timestamp_idx ON core.article USING btree (community_read_timestamp DESC);


--
-- Name: article_hot_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_hot_score_idx ON core.article USING btree (hot_score DESC);


--
-- Name: article_tag_tag_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_tag_tag_id_idx ON core.article_tag USING btree (tag_id);


--
-- Name: article_top_score_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_top_score_idx ON core.article USING btree (top_score DESC);


--
-- Name: article_word_count_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX article_word_count_idx ON core.article USING btree (word_count);


--
-- Name: auth_service_access_token_unique_valid_identity_id; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX auth_service_access_token_unique_valid_identity_id ON core.auth_service_access_token USING btree (identity_id) WHERE (date_revoked IS NULL);


--
-- Name: auth_service_association_unique_associated_identity_id; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX auth_service_association_unique_associated_identity_id ON core.auth_service_association USING btree (identity_id) WHERE (date_dissociated IS NULL);


--
-- Name: comment_article_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE INDEX comment_article_id_idx ON core.comment USING btree (article_id);


--
-- Name: following_follower_user_account_id_followee_user_account_id_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX following_follower_user_account_id_followee_user_account_id_idx ON core.following USING btree (follower_user_account_id, followee_user_account_id) WHERE (date_unfollowed IS NULL);


--
-- Name: notification_event_duplicate_user_account_event_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX notification_event_duplicate_user_account_event_idx ON core.notification_receipt USING btree (user_account_id, event_type) WHERE (event_type = ANY (ARRAY['free_trial_completion'::core.notification_event_type, 'initial_subscription'::core.notification_event_type]));


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
-- Name: subscription_account_user_account_unique_assignment_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX subscription_account_user_account_unique_assignment_idx ON core.subscription_account USING btree (user_account_id) WHERE (provider = 'stripe'::core.subscription_provider);


--
-- Name: subscription_default_payment_method_unique_assignment_idx; Type: INDEX; Schema: core; Owner: -
--

CREATE UNIQUE INDEX subscription_default_payment_method_unique_assignment_idx ON core.subscription_default_payment_method USING btree (provider, provider_account_id) WHERE (date_unassigned IS NULL);


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
-- Name: article_author article_author_assigned_by_user_account_id_fk; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_assigned_by_user_account_id_fk FOREIGN KEY (assigned_by_user_account_id) REFERENCES core.user_account(id);


--
-- Name: article_author article_author_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_author_id_fkey FOREIGN KEY (author_id) REFERENCES core.author(id);


--
-- Name: article_author article_author_unassigned_by_user_account_id_fk; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_author
    ADD CONSTRAINT article_author_unassigned_by_user_account_id_fk FOREIGN KEY (unassigned_by_user_account_id) REFERENCES core.user_account(id);


--
-- Name: article_image article_image_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_image
    ADD CONSTRAINT article_image_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: article_image article_image_creator_user_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_image
    ADD CONSTRAINT article_image_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES core.user_account(id);


--
-- Name: article_issue_report article_issue_report_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_issue_report
    ADD CONSTRAINT article_issue_report_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: article_issue_report article_issue_report_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.article_issue_report
    ADD CONSTRAINT article_issue_report_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


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
-- Name: auth_service_access_token auth_service_access_token_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_access_token
    ADD CONSTRAINT auth_service_access_token_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: auth_service_access_token auth_service_access_token_request_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_access_token
    ADD CONSTRAINT auth_service_access_token_request_id_fkey FOREIGN KEY (request_id) REFERENCES core.auth_service_request_token(id);


--
-- Name: auth_service_association auth_service_association_authentication_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_association
    ADD CONSTRAINT auth_service_association_authentication_id_fkey FOREIGN KEY (authentication_id) REFERENCES core.auth_service_authentication(id);


--
-- Name: auth_service_association auth_service_association_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_association
    ADD CONSTRAINT auth_service_association_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: auth_service_association auth_service_association_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_association
    ADD CONSTRAINT auth_service_association_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: auth_service_authentication auth_service_authentication_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_authentication
    ADD CONSTRAINT auth_service_authentication_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: auth_service_post auth_service_post_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_post
    ADD CONSTRAINT auth_service_post_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES core.comment(id);


--
-- Name: auth_service_post auth_service_post_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_post
    ADD CONSTRAINT auth_service_post_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: auth_service_post auth_service_post_silent_post_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_post
    ADD CONSTRAINT auth_service_post_silent_post_id_fkey FOREIGN KEY (silent_post_id) REFERENCES core.silent_post(id);


--
-- Name: auth_service_refresh_token auth_service_refresh_token_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_refresh_token
    ADD CONSTRAINT auth_service_refresh_token_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: auth_service_user auth_service_user_identity_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.auth_service_user
    ADD CONSTRAINT auth_service_user_identity_id_fkey FOREIGN KEY (identity_id) REFERENCES core.auth_service_identity(id);


--
-- Name: author_payout author_payout_payout_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_payout
    ADD CONSTRAINT author_payout_payout_account_id_fkey FOREIGN KEY (payout_account_id) REFERENCES core.payout_account(id);


--
-- Name: author_user_account_assignment author_user_account_assignment_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment
    ADD CONSTRAINT author_user_account_assignment_author_id_fkey FOREIGN KEY (author_id) REFERENCES core.author(id);


--
-- Name: author_user_account_assignment author_user_account_assignment_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.author_user_account_assignment
    ADD CONSTRAINT author_user_account_assignment_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


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
-- Name: display_preference display_preference_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.display_preference
    ADD CONSTRAINT display_preference_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: donation_account donation_account_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_account
    ADD CONSTRAINT donation_account_author_id_fkey FOREIGN KEY (author_id) REFERENCES core.author(id);


--
-- Name: donation_account donation_account_donation_recipient_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_account
    ADD CONSTRAINT donation_account_donation_recipient_id_fkey FOREIGN KEY (donation_recipient_id) REFERENCES core.donation_recipient(id);


--
-- Name: donation_account donation_account_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_account
    ADD CONSTRAINT donation_account_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: donation_payout donation_payout_donation_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_payout
    ADD CONSTRAINT donation_payout_donation_account_id_fkey FOREIGN KEY (donation_account_id) REFERENCES core.donation_account(id);


--
-- Name: donation_payout donation_payout_donation_recipient_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.donation_payout
    ADD CONSTRAINT donation_payout_donation_recipient_id_fkey FOREIGN KEY (donation_recipient_id) REFERENCES core.donation_recipient(id);


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
-- Name: free_trial_credit free_trial_credit_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.free_trial_credit
    ADD CONSTRAINT free_trial_credit_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


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
-- Name: notification_receipt notification_receipt_event_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt
    ADD CONSTRAINT notification_receipt_event_fkey FOREIGN KEY (event_id, event_type) REFERENCES core.notification_event(id, type);


--
-- Name: notification_receipt notification_receipt_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.notification_receipt
    ADD CONSTRAINT notification_receipt_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: orientation_analytics orientation_analytics_share_result_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.orientation_analytics
    ADD CONSTRAINT orientation_analytics_share_result_id_fkey FOREIGN KEY (share_result_id) REFERENCES core.share_result(id);


--
-- Name: orientation_analytics orientation_analytics_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.orientation_analytics
    ADD CONSTRAINT orientation_analytics_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: page page_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.page
    ADD CONSTRAINT page_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: password_reset_request password_reset_request_auth_service_authentication_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.password_reset_request
    ADD CONSTRAINT password_reset_request_auth_service_authentication_id_fkey FOREIGN KEY (auth_service_authentication_id) REFERENCES core.auth_service_authentication(id);


--
-- Name: password_reset_request password_reset_request_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.password_reset_request
    ADD CONSTRAINT password_reset_request_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: payout_account payout_account_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.payout_account
    ADD CONSTRAINT payout_account_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: provisional_user_account provisional_user_account_merged_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_account
    ADD CONSTRAINT provisional_user_account_merged_user_account_id_fkey FOREIGN KEY (merged_user_account_id) REFERENCES core.user_account(id);


--
-- Name: provisional_user_article provisional_user_article_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article
    ADD CONSTRAINT provisional_user_article_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: provisional_user_article_progress provisional_user_article_progr_provisional_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article_progress
    ADD CONSTRAINT provisional_user_article_progr_provisional_user_account_id_fkey FOREIGN KEY (provisional_user_account_id) REFERENCES core.provisional_user_account(id);


--
-- Name: provisional_user_article_progress provisional_user_article_progress_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article_progress
    ADD CONSTRAINT provisional_user_article_progress_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: provisional_user_article provisional_user_article_provisional_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.provisional_user_article
    ADD CONSTRAINT provisional_user_article_provisional_user_account_id_fkey FOREIGN KEY (provisional_user_account_id) REFERENCES core.provisional_user_account(id);


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
-- Name: share_result share_result_user_account_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.share_result
    ADD CONSTRAINT share_result_user_account_id_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


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
-- Name: subscription subscription_account_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription
    ADD CONSTRAINT subscription_account_fkey FOREIGN KEY (provider, provider_account_id) REFERENCES core.subscription_account(provider, provider_account_id);


--
-- Name: subscription_account subscription_account_user_account_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_account
    ADD CONSTRAINT subscription_account_user_account_fkey FOREIGN KEY (user_account_id) REFERENCES core.user_account(id);


--
-- Name: subscription_default_payment_method subscription_default_payment_method_account_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_default_payment_method
    ADD CONSTRAINT subscription_default_payment_method_account_fkey FOREIGN KEY (provider, provider_account_id) REFERENCES core.subscription_account(provider, provider_account_id);


--
-- Name: subscription_default_payment_method subscription_default_payment_method_payment_method_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_default_payment_method
    ADD CONSTRAINT subscription_default_payment_method_payment_method_fkey FOREIGN KEY (provider, provider_payment_method_id) REFERENCES core.subscription_payment_method(provider, provider_payment_method_id);


--
-- Name: subscription_payment_method subscription_payment_method_account_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_payment_method
    ADD CONSTRAINT subscription_payment_method_account_fkey FOREIGN KEY (provider, provider_account_id) REFERENCES core.subscription_account(provider, provider_account_id);


--
-- Name: subscription_payment_method subscription_payment_method_current_version_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_payment_method
    ADD CONSTRAINT subscription_payment_method_current_version_fkey FOREIGN KEY (provider, provider_payment_method_id, current_version_date) REFERENCES core.subscription_payment_method_version(provider, provider_payment_method_id, date_created) DEFERRABLE;


--
-- Name: subscription_payment_method_version subscription_payment_method_version_payment_method_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_payment_method_version
    ADD CONSTRAINT subscription_payment_method_version_payment_method_fkey FOREIGN KEY (provider, provider_payment_method_id) REFERENCES core.subscription_payment_method(provider, provider_payment_method_id);


--
-- Name: subscription_period_author_distribution subscription_period_author_distribution_author_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period_author_distribution
    ADD CONSTRAINT subscription_period_author_distribution_author_id_fkey FOREIGN KEY (author_id) REFERENCES core.author(id);


--
-- Name: subscription_period_author_distribution subscription_period_author_distribution_distribution_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period_author_distribution
    ADD CONSTRAINT subscription_period_author_distribution_distribution_fkey FOREIGN KEY (provider, provider_period_id) REFERENCES core.subscription_period_distribution(provider, provider_period_id);


--
-- Name: subscription_period_distribution subscription_period_distribution_period_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period_distribution
    ADD CONSTRAINT subscription_period_distribution_period_fkey FOREIGN KEY (provider, provider_period_id) REFERENCES core.subscription_period(provider, provider_period_id);


--
-- Name: subscription_period subscription_period_next_period_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period
    ADD CONSTRAINT subscription_period_next_period_fkey FOREIGN KEY (provider, next_provider_period_id) REFERENCES core.subscription_period(provider, provider_period_id);


--
-- Name: subscription_period subscription_period_payment_method_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period
    ADD CONSTRAINT subscription_period_payment_method_fkey FOREIGN KEY (provider, provider_payment_method_id) REFERENCES core.subscription_payment_method(provider, provider_payment_method_id);


--
-- Name: subscription_period subscription_period_price_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period
    ADD CONSTRAINT subscription_period_price_fkey FOREIGN KEY (provider, provider_price_id) REFERENCES core.subscription_price(provider, provider_price_id);


--
-- Name: subscription_period subscription_period_subscription_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_period
    ADD CONSTRAINT subscription_period_subscription_fkey FOREIGN KEY (provider, provider_subscription_id) REFERENCES core.subscription(provider, provider_subscription_id);


--
-- Name: subscription_price subscription_price_level_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_price
    ADD CONSTRAINT subscription_price_level_fkey FOREIGN KEY (level_id) REFERENCES core.subscription_level(id);


--
-- Name: subscription_renewal_status_change subscription_renewal_status_change_price_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_renewal_status_change
    ADD CONSTRAINT subscription_renewal_status_change_price_fkey FOREIGN KEY (provider, provider_price_id) REFERENCES core.subscription_price(provider, provider_price_id);


--
-- Name: subscription_renewal_status_change subscription_renewal_status_change_subscription_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.subscription_renewal_status_change
    ADD CONSTRAINT subscription_renewal_status_change_subscription_fkey FOREIGN KEY (provider, provider_subscription_id) REFERENCES core.subscription(provider, provider_subscription_id);


--
-- Name: twitter_bot_tweet twitter_bot_tweet_article_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.twitter_bot_tweet
    ADD CONSTRAINT twitter_bot_tweet_article_id_fkey FOREIGN KEY (article_id) REFERENCES core.article(id);


--
-- Name: twitter_bot_tweet twitter_bot_tweet_comment_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.twitter_bot_tweet
    ADD CONSTRAINT twitter_bot_tweet_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES core.comment(id);


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
-- Name: user_article user_article_free_trial_credit_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: -
--

ALTER TABLE ONLY core.user_article
    ADD CONSTRAINT user_article_free_trial_credit_id_fkey FOREIGN KEY (free_trial_credit_id) REFERENCES core.free_trial_credit(id);


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

