-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- manual tag removal
WITH
    slug_to_delete (
        value
    ) AS (
        VALUES
            ('cnbc'),
            ('elevated-false'),
            ('lite-true'),
            ('make-it'),
            ('makeit'),
            ('source-tagname-cnbc-us-source')
        UNION ALL
        SELECT
            tag.slug
        FROM
            core.tag
        WHERE
            tag.slug ~ '^layercake\-' OR
            tag.slug ~ '^lockedpostsource\-'
    ),
deleted_article_tag AS (
    DELETE FROM
        core.article_tag
    USING
        (
            SELECT
                tag.id
            FROM
                slug_to_delete
                JOIN
                    core.tag ON
                    tag.slug = slug_to_delete.value
        ) AS tag_to_delete
    WHERE
        article_tag.tag_id = tag_to_delete.id
    RETURNING
        article_tag.tag_id,
        article_tag.article_id
)
DELETE FROM
    core.tag
USING
    slug_to_delete
WHERE
    slug_to_delete.value = tag.slug;

-- manual tag mergers
SELECT
    article_api.merge_tags('coronavirus', 'coronavirus-2019-ncov', 'covid-19', 'coronavirus-outbreak');
SELECT
    article_api.merge_tags('technology', 'tech');
SELECT
    article_api.merge_tags('donald-trump', 'trump-donald-j', 'trump', 'donald-j-trump');
SELECT
    article_api.merge_tags('news', 'type-news');
SELECT
    article_api.merge_tags('facebook', 'facebook-inc');
SELECT
    article_api.merge_tags('startups', 'startup');
SELECT
    article_api.merge_tags('united-states', 'us');

-- manual tag name cleanup
UPDATE
    core.tag
SET
    name = 'Culture'
WHERE
    tag.slug = 'culture';
UPDATE
    core.tag
SET
    name = 'Self'
WHERE
    tag.slug = 'self';
UPDATE
    core.tag
SET
    name = 'Computers and the Internet'
WHERE
    tag.slug = 'computers-and-the-internet';
UPDATE
    core.tag
SET
    name = 'United States'
WHERE
    tag.slug = 'united-states';
UPDATE
    core.tag
SET
    name = 'Books and Literature'
WHERE
    tag.slug = 'books-and-literature';
UPDATE
    core.tag
SET
    name = 'Life Lessons'
WHERE
    tag.slug = 'life-lessons';
UPDATE
    core.tag
SET
    name = 'Front Page'
WHERE
    tag.slug = 'front-page';
UPDATE
    core.tag
SET
    name = 'New York City'
WHERE
    tag.slug = 'new-york-city';
UPDATE
    core.tag
SET
    name = 'Twitter'
WHERE
    tag.slug = 'twitter';
UPDATE
    core.tag
SET
    name = 'Power'
WHERE
    tag.slug = 'power';
UPDATE
    core.tag
SET
    name = 'US News'
WHERE
    tag.slug = 'us-news';
UPDATE
    core.tag
SET
    name = 'Life'
WHERE
    tag.slug = 'life';
UPDATE
    core.tag
SET
    name = 'California'
WHERE
    tag.slug = 'california';
UPDATE
    core.tag
SET
    name = 'Entrepreneurship'
WHERE
    tag.slug = 'entrepreneurship';
UPDATE
    core.tag
SET
    name = 'Privacy'
WHERE
    tag.slug = 'privacy';
UPDATE
    core.tag
SET
    name = 'Article'
WHERE
    tag.slug = 'article';
UPDATE
    core.tag
SET
    name = 'Movies'
WHERE
    tag.slug = 'movies';
UPDATE
    core.tag
SET
    name = 'China'
WHERE
    tag.slug = 'china';
UPDATE
    core.tag
SET
    name = 'Health'
WHERE
    tag.slug = 'health';
UPDATE
    core.tag
SET
    name = 'Ideas'
WHERE
    tag.slug = 'ideas';
UPDATE
    core.tag
SET
    name = 'Donald Trump'
WHERE
    tag.slug = 'donald-trump';
UPDATE
    core.tag
SET
    name = 'Articles'
WHERE
    tag.slug = 'articles';
UPDATE
    core.tag
SET
    name = 'United States Politics and Government'
WHERE
    tag.slug = 'united-states-politics-and-government';
UPDATE
    core.tag
SET
    name = 'Business'
WHERE
    tag.slug = 'business';
UPDATE
    core.tag
SET
    name = 'Psychology'
WHERE
    tag.slug = 'psychology';
UPDATE
    core.tag
SET
    name = 'Parenting'
WHERE
    tag.slug = 'parenting';
UPDATE
    core.tag
SET
    name = 'Education'
WHERE
    tag.slug = 'education';
UPDATE
    core.tag
SET
    name = 'Mental Health'
WHERE
    tag.slug = 'mental-health';
UPDATE
    core.tag
SET
    name = 'Happiness'
WHERE
    tag.slug = 'happiness';