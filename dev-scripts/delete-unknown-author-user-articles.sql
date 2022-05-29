-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- remove "Unknown Author" from My Impact chart for product screenshots
DELETE FROM
	core.user_article AS user_article_to_delete
USING
	core.user_article
	LEFT JOIN
		core.article_author ON
			user_article.article_id = article_author.article_id
WHERE
	user_article_to_delete.id = user_article.id AND
	article_author.author_id IS NULL;