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
	article.id,
   article.top_score,
   article.read_count,
   article.comment_count,
   article.average_rating_score,
   estimate_article_length(article.word_count) AS length,
   article.aotd_timestamp,
   article.title,
   'https://readup.com/comments/' || replace(article.slug, '_', '/') AS url
FROM
	core.article
WHERE
	article.aotd_timestamp > '2020-01-01' AND
	article.source_id NOT IN (
	   SELECT
	      source.id
	   FROM
			core.source
	   WHERE
	      source.hostname IN (
	         'blog.readup.com',
	      	'billloundy.com'
	      )
	) AND
	--article.word_count < (184 * 15)
	--article.word_count >= (184 * 15) AND article.word_count < (184 * 30)
	article.word_count >= (184 * 30)
ORDER BY
	article.top_score DESC NULLS LAST
LIMIT
	5;