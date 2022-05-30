-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- fix article_api.create_page
DROP FUNCTION article_api.create_page(
	article_id bigint,
	number integer,
	word_count integer,
	readable_word_count integer,
	url text
);
CREATE FUNCTION article_api.create_page(
	article_id bigint,
	number integer,
	word_count integer,
	readable_word_count integer,
	url text
)
RETURNS SETOF core.page
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