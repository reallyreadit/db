-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

WITH buckets AS (
	SELECT
		width_bucket(
			least((words_read / readable_word_count :: double precision) * 100, 100),
			0,
			100,
			19
		) AS bucket,
		count(*) AS bucket_count
	FROM article_api.user_article
	WHERE date_created IS NOT NULL
	GROUP BY bucket
	ORDER BY bucket
)
SELECT array_agg(bucket_count) FROM buckets;