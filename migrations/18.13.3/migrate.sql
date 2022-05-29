-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
	Update source lookup to ignore www. host prefix.
*/

-- Add hostname_priority column in order to resolve duplicate matches.
ALTER TABLE
	core.source
ADD COLUMN
	hostname_priority int NOT NULL
		DEFAULT 0;

-- Set hostname_priority for duplicate sources.
WITH canonicalized_source AS (
	SELECT
		source.id,
		source.slug,
		source.hostname,
		regexp_replace(
			lower(source.hostname),
			'^www\.',
			''
		) AS canonical_hostname,
		coalesce(count(*), 0) AS article_count
	FROM
		core.source
		LEFT JOIN
			core.article ON
				source.id = article.source_id
	GROUP BY
		source.id
),
duplicate_source AS (
	SELECT
		DISTINCT ON (
			canonical.canonical_hostname
		)
		canonical.id AS canonical_id,
		canonical.slug AS canonical_slug,
		canonical.article_count AS canonical_count,
		duplicate.id AS duplicate_id,
		duplicate.slug AS duplicate_slug,
		duplicate.article_count AS duplicate_count
	FROM
		canonicalized_source AS canonical
		JOIN
			canonicalized_source AS duplicate ON
				canonical.canonical_hostname = duplicate.canonical_hostname AND
				canonical.id != duplicate.id
	ORDER BY
		canonical.canonical_hostname,
		CASE WHEN
			canonical.slug ILIKE '%com' OR
			canonical.slug ILIKE '%org' OR
			canonical.slug IN ('dh-lib', 'the-believer', 'generalcatalyst', 'ccpedu', 'people')
		THEN
			1
		ELSE
			0
		END,
		length(canonical.slug),
		canonical.article_count DESC
)
UPDATE
	core.source
SET
	hostname_priority = 1
FROM
	duplicate_source
WHERE
	source.id = duplicate_source.duplicate_id;

-- Update lookup function to ignore www. prefix and sort by priority.
CREATE OR REPLACE FUNCTION
	article_api.find_source(
		source_hostname text
	)
RETURNS
	SETOF core.source
LANGUAGE
	sql
AS $$
	SELECT
		source.*
	FROM
		core.source
	WHERE
		regexp_replace(source.hostname, '^www\.', '') = find_source.source_hostname
	ORDER BY
		source.hostname_priority
	LIMIT
		1;
$$;