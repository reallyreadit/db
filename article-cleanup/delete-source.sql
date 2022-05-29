-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

SELECT * FROM source WHERE id = 1757;
SELECT * FROM article WHERE source_id = 1757;
SELECT * FROM page WHERE article_id IN (SELECT id FROM article WHERE source_id = 1757);

SELECT *
FROM article_author
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM article_tag
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM star
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM user_page
WHERE page_id IN (
	SELECT id
	FROM page
	WHERE article_id IN (
		SELECT id
		FROM article
		WHERE source_id = 1757
	)
);

SELECT *
FROM comment
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM email_share
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);