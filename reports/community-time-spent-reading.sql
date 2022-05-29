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
    *
FROM
    user_article
WHERE
    date_created = (SELECT min(date_created) FROM user_article) OR
    date_created = (SELECT max(date_created) FROM user_article);

SELECT
    period.local_timestamp,
    estimate_reading_time(sum(user_article.words_read) FILTER (WHERE user_article.date_completed IS NULL)) AS uncompleted_time,
    estimate_reading_time(sum(user_article.words_read) FILTER (WHERE user_article.date_completed IS NOT NULL)) AS completed_time
FROM
    generate_local_timestamp_to_utc_range_series(
        start => '2017-05-01',
        stop => '2020-05-01',
        step => '1 month',
        time_zone_name => 'America/New_York'
    ) AS period
    JOIN user_article ON
        user_article.last_modified <@ period.utc_range
WHERE
    user_article.analytics IS NULL OR
    user_article.analytics->'client'->>'type' = 'web/extension'
GROUP BY
    period.local_timestamp;