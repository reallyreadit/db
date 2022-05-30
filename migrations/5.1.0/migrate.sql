-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE TABLE core.extension_installation (
	id bigserial PRIMARY KEY,
	timestamp timestamp NOT NULL DEFAULT utc_now(),
	installation_id uuid NOT NULL UNIQUE,
	user_account_id bigint NULL REFERENCES core.user_account (id),
	platform text NOT NULL
);

CREATE TABLE core.extension_removal (
	id bigserial PRIMARY KEY,
	timestamp timestamp NOT NULL DEFAULT utc_now(),
	installation_id uuid NOT NULL UNIQUE REFERENCES core.extension_installation (installation_id),
	user_account_id bigint NULL REFERENCES core.user_account (id),
	reason text NULL
);

CREATE FUNCTION analytics.log_extension_installation(
	installation_id uuid,
	user_account_id bigint,
	platform text
)
RETURNS void
LANGUAGE SQL
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

CREATE FUNCTION analytics.log_extension_removal(
	installation_id uuid,
	user_account_id bigint
)
RETURNS void
LANGUAGE SQL
AS $$
    INSERT INTO
        extension_removal (installation_id, user_account_id)
    VALUES
    	(
    	 	log_extension_removal.installation_id,
    	 	log_extension_removal.user_account_id
		);
$$;

CREATE FUNCTION analytics.log_extension_removal_feedback(
	installation_id uuid,
	reason text
)
RETURNS void
LANGUAGE SQL
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

DROP FUNCTION analytics.get_key_metrics(
	start_date timestamp without time zone,
	end_date timestamp without time zone
);
CREATE FUNCTION analytics.get_key_metrics(
	start_date timestamp without time zone,
	end_date timestamp without time zone
)
RETURNS TABLE(
	day timestamp without time zone,
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
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
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