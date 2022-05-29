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
    article.title AS article_title,
    trim(source.name) AS publisher,
    (
        CASE WHEN count(author.*) > 0
            THEN array_to_string(array_agg(author.name ORDER BY author.name), ', ')
            ELSE ''
        END
    ) AS authors,
    core.estimate_reading_time(article.word_count) AS article_length,
    user_article.date_completed
FROM
    core.user_article
    JOIN core.article ON
        article.id = user_article.article_id
    JOIN core.source ON
        source.id = article.source_id
    LEFT JOIN core.article_author ON
        article_author.article_id = article.id
    LEFT JOIN core.author ON
        author.id = article_author.author_id
WHERE
    user_article.user_account_id = 2 AND
    user_article.date_completed IS NOT NULL
GROUP BY
    article.id,
    source.id,
    user_article.id
ORDER BY
    user_article.date_completed;