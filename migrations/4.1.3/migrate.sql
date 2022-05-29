-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE OR REPLACE FUNCTION article_api.get_percent_complete(readable_word_count numeric, words_read numeric) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT greatest(
	   least(
	      (coalesce(words_read, 0)::double precision / greatest(coalesce(readable_word_count, 0), 1)) * 100,
	      100
	   ),
	   0
	);
$$;