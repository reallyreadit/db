-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

SELECT
	user_account.id,
    user_account.name,
    user_account.email,
    user_account.date_created,
    count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS article_completions,
    max(user_article.last_modified) AS latest_read_activity,
    mode() WITHIN GROUP (ORDER BY user_article.analytics->'client'->>'type') AS preferred_client_type,
    time_zone.name AS time_zone
FROM
	user_account
	LEFT JOIN time_zone
	    ON time_zone.id = user_account.time_zone_id
	LEFT JOIN user_article
		ON user_article.user_account_id = user_account.id
GROUP BY
	user_account.id,
    time_zone.id
ORDER BY
	user_account.id;