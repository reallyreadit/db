-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE OR REPLACE FUNCTION analytics.get_key_metrics(
	start_date timestamp without time zone,
	end_date timestamp without time zone
)
RETURNS TABLE(
    day timestamp without time zone,
    user_accounts_app_count bigint,
    user_accounts_browser_count bigint,
    user_accounts_unknown_count bigint,
    reads_app_count bigint,
    reads_browser_count bigint,
    reads_unknown_count bigint,
    comments_app_count bigint,
    comments_browser_count bigint,
    comments_unknown_count bigint
)
LANGUAGE sql
AS $$
	WITH range AS (
		SELECT
			date AS day,
			date + '1 day'::interval AS next_day
		FROM generate_series(
		    get_key_metrics.start_date,
		    get_key_metrics.end_date,
		    '1 day'::interval
		) AS series (date)
	)
	SELECT
		range.day,
		coalesce(user_accounts.app_count, 0) AS user_accounts_app_count,
		coalesce(user_accounts.browser_count, 0) AS user_accounts_browser_count,
		coalesce(user_accounts.unknown_count, 0) AS user_accounts_unknown_count,
		coalesce(reads.app_count, 0) AS reads_app_count,
		coalesce(reads.browser_count, 0) AS reads_browser_count,
		coalesce(reads.unknown_count, 0) AS reads_unknown_count,
		coalesce(comments.app_count, 0) AS comments_app_count,
		coalesce(comments.browser_count, 0) AS comments_browser_count,
		coalesce(comments.unknown_count, 0) AS comments_unknown_count
	FROM
		range
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_account
				JOIN range ON user_account.date_created >= range.day AND user_account.date_created < range.next_day
			GROUP BY range.day
		) AS user_accounts ON user_accounts.day = range.day
		LEFT JOIN (
			SELECT
				range.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_page
				JOIN range ON user_page.date_completed >= range.day AND user_page.date_completed < range.next_day
			GROUP BY range.day
		) AS reads ON reads.day = range.day
		LEFT JOIN (
			SELECT
				range.day,
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
				JOIN range ON comment.date_created >= range.day AND comment.date_created < range.next_day
			GROUP BY range.day
		) AS comments ON comments.day = range.day
	ORDER BY range.day DESC;
$$;