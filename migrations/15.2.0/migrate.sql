-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE TABLE core.article_image (
    article_id bigint NOT NULL REFERENCES core.article (id),
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    creator_user_id bigint NOT NULL REFERENCES core.user_account (id),
    url text NOT NULL,
    PRIMARY KEY (article_id, url)
);
CREATE FUNCTION article_api.get_article_image(
    article_id bigint
)
RETURNS SETOF core.article_image
LANGUAGE sql
STABLE
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
CREATE FUNCTION article_api.set_article_image(
    article_id bigint,
    creator_user_id bigint,
    url text
)
RETURNS SETOF core.article_image
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