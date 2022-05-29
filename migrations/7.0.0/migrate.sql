-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- restructure existing user_account analytics
UPDATE
	user_account
SET
	analytics = analytics - 'context' || '{"marketing_screen_variant": 1, "referrer_url": null, "initial_path": null}'::jsonb;

-- rename analytics to creation_analytics
ALTER TABLE
	user_account
RENAME COLUMN
    analytics TO creation_analytics;

-- update create_user_account to use new column
CREATE OR REPLACE FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint,
	analytics text
)
RETURNS SETOF user_account_api.user_account
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

-- update key metrics report to use new column
CREATE OR REPLACE FUNCTION analytics.get_key_metrics(
	start_date timestamp,
	end_date timestamp
)
RETURNS TABLE(
    day timestamp,
    user_account_app_count bigint,
    user_account_browser_count bigint,
    user_account_unknown_count bigint,
    read_app_count bigint,
    read_browser_count bigint,
    read_unknown_count bigint,
    comment_app_count bigint,
    comment_browser_count bigint,
    comment_unknown_count bigint,
    extension_installation_count bigint,
    extension_removal_count bigint
)
LANGUAGE sql
STABLE
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

-- create new user_account analytics reporting function
CREATE FUNCTION analytics.get_user_account_creations(
	start_date timestamp,
	end_date timestamp
)
RETURNS TABLE (
    id bigint,
	name text,
	date_created timestamp,
	time_zone_name text,
	client_mode text,
	marketing_screen_variant int,
	referrer_url text,
	initial_path text
)
LANGUAGE sql
STABLE
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