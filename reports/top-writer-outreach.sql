-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

WITH top_writer AS (
    SELECT
        writer.name,
        writer.slug,
        writer.score,
        writer.rank,
        'week' AS category
    FROM
        stats.get_top_author_leaderboard(
            max_rank => 25,
            since_date => core.utc_now() - '7 days'::interval
        ) AS writer
    UNION ALL
    SELECT
        writer.name,
        writer.slug,
        writer.score,
        writer.rank,
        'month' AS category
    FROM
        stats.get_top_author_leaderboard(
            max_rank => 50,
            since_date => core.utc_now() - '30 days'::interval
        ) AS writer
    UNION ALL
    SELECT
        writer.name,
        writer.slug,
        writer.score,
        writer.rank,
        'year' AS category
    FROM
        stats.get_top_author_leaderboard(
            max_rank => 100,
            since_date => core.utc_now() - '365 days'::interval
        ) AS writer
    UNION ALL
    SELECT
        writer.name,
        writer.slug,
        writer.score,
        writer.rank,
        'all_time' AS category
    FROM
        stats.get_top_author_leaderboard(
            max_rank => 100,
            since_date => NULL
        ) AS writer
)
SELECT DISTINCT ON (top_writer.slug)
    top_writer.name AS full_name,
    (regexp_split_to_array(top_writer.name, '\s+'))[1] AS first_name,
    'https://readup.com/writers/' || top_writer.slug AS profile_url,
    top_writer.category,
    top_writer.score,
    top_writer.rank,
    author.twitter_handle,
    author.twitter_handle_assignment,
    author.email_address
FROM
    top_writer
    JOIN core.author ON
        author.slug = top_writer.slug
    /*LEFT JOIN (
        SELECT DISTINCT ON (article_author.author_id)
            article_author.author_id,
            source.name AS source_name
        FROM
            core.article_author
            JOIN core.article ON
                article.id = article_author.article_id
            JOIN core.source ON
                source.id = article.source_id
        ORDER BY
            article_author.author_id,
            article.top_score DESC
    ) AS top_article ON
        top_article.author_id = author.id*/
ORDER BY
    top_writer.slug,
    top_writer.rank
    /*CASE top_writer.category
        WHEN 'all_time' THEN 0
        WHEN 'year' THEN 1
        WHEN 'month' THEN 2
        WHEN 'week' THEN 3
    END*/;