-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE OR REPLACE VIEW community_reads.listed_community_read
AS (
	SELECT
		id,
    	hot_score,
    	top_score,
    	comment_count,
    	read_count,
    	average_rating_score
	FROM community_reads.community_read
  	WHERE
  		aotd_timestamp IS DISTINCT FROM (
  			SELECT max(aotd_timestamp)
        	FROM article
  		)
);