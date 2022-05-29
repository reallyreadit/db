-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- set new cached column initial values
UPDATE article
SET
	comment_count = coalesce(
		(
			SELECT count
			FROM article_api.article_comment_count
			WHERE article_id = article.id
		),
	    0
	),
	read_count = coalesce(
		(
			SELECT count
			FROM article_api.article_read_count
			WHERE article_id = article.id
		),
	    0
	),
	average_rating_score = (
		SELECT score
		FROM article_api.average_article_rating
		WHERE article_id = article.id
	)
WHERE true;