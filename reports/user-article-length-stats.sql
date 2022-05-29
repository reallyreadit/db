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
		width_bucket(word_count, 184, 184 * 64, 20) AS bucket,
		count(*)                                    AS bucket_count,
		(count(*)
			 FILTER (WHERE (words_read / readable_word_count :: double precision) * 100 >= 90) /
		 count(*) :: double precision) * 100        AS percent_completed,
		avg(array_length(read_state, 1))            AS avg_read_state_len
	FROM user_page
		JOIN page ON user_page.page_id = page.id
	WHERE word_count >= 184 AND word_count <= 184 * 64
	GROUP BY bucket
	ORDER BY bucket
)
SELECT array_agg(avg_read_state_len) FROM buckets;