-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- trim author names
UPDATE
    core.author
SET
    name = regexp_replace(name, '((^\s+)|(\s+$))', '', 'g')
WHERE
    name ~ '^\s' OR name ~ '\s$';

-- delete redundant article_authors
WITH named_article_author AS (
    SELECT
        article_author.article_id,
        article_author.author_id,
        lower(author.name) AS lowered_name
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
),
duplicate AS (
    SELECT
        named_article_author.article_id,
        min(named_article_author.author_id) AS first_author_id,
        named_article_author.lowered_name
    FROM
        named_article_author
    GROUP BY
        named_article_author.article_id,
        named_article_author.lowered_name
    HAVING
        count(*) > 1
)
DELETE FROM
    core.article_author
WHERE
    (article_id, author_id) IN (
        SELECT
            named_article_author.article_id,
            named_article_author.author_id
        FROM
            named_article_author
            JOIN duplicate ON
                duplicate.article_id = named_article_author.article_id AND
                duplicate.lowered_name = named_article_author.lowered_name
        WHERE
            named_article_author.author_id != duplicate.first_author_id
    );

-- merge authors
WITH merged_author AS (
    SELECT
        min(author.id) AS id,
        lower(name) AS lowered_name
    FROM
        core.author
    GROUP BY
        lower(name)
    HAVING
        count(*) > 1
),
duplicate_article_author AS (
    SELECT
        article_author.article_id,
        article_author.author_id,
        merged_author.id AS merged_author_id
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
        JOIN merged_author ON
            merged_author.lowered_name = lower(author.name) AND
            merged_author.id != article_author.author_id
)
UPDATE
    core.article_author
SET
    author_id = duplicate_article_author.merged_author_id
FROM
    duplicate_article_author
WHERE
    article_author.article_id = duplicate_article_author.article_id AND
    article_author.author_id = duplicate_article_author.author_id;

-- delete orphaned authors
CREATE INDEX article_author_author_id_idx ON core.article_author (author_id);

WITH orphaned_author AS (
    SELECT
        author.id
    FROM
        core.author
        LEFT JOIN core.article_author ON
            article_author.author_id = author.id
    WHERE
        article_author.article_id IS NULL
)
DELETE FROM
    core.author
USING
    orphaned_author
WHERE
    author.id = orphaned_author.id;

DROP INDEX article_author_author_id_idx;

-- fix author reconciliation
CREATE OR REPLACE FUNCTION article_api.create_article(
    title text,
    slug text,
    source_id bigint,
    date_published timestamp,
    date_modified timestamp,
    section text,
    description text,
    author_names text[],
    author_urls text[],
    tags text[]
)
RETURNS bigint
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
	article_id bigint;
	current_author_id bigint;
	current_tag text;
	current_tag_id bigint;
BEGIN
	INSERT INTO
	    core.article (
            title,
            slug,
            source_id,
            date_published,
            date_modified,
            section,
            description
        )
	VALUES (
	    create_article.title,
	    create_article.slug,
	    create_article.source_id,
	    create_article.date_published,
	    create_article.date_modified,
	    create_article.section,
	    create_article.description
	)
	RETURNING
	    id
	INTO
	    locals.article_id;
	FOR i IN 1..coalesce(array_length(create_article.author_names, 1), 0) LOOP
		SELECT
		    author.id
		INTO
		    locals.current_author_id
		FROM
		    core.author
		WHERE
		    lower(author.name) = lower(create_article.author_names[i]);
		IF locals.current_author_id IS NULL THEN
			INSERT INTO
			    core.author (
                    name,
                    url
                )
			VALUES (
			    create_article.author_names[i],
			    create_article.author_urls[i]
			)
			RETURNING
			    id
			INTO
			    locals.current_author_id;
		END IF;
		INSERT INTO
		    core.article_author (
                article_id,
                author_id
            )
		VALUES (
		    locals.article_id,
		    locals.current_author_id
		);
	END LOOP;
	FOREACH locals.current_tag IN ARRAY create_article.tags LOOP
		SELECT
		    tag.id
		INTO
		    locals.current_tag_id
		FROM
		    core.tag
		WHERE
		    tag.name = locals.current_tag;
		IF locals.current_tag_id IS NULL THEN
			INSERT INTO
			    core.tag (
			        name
			    )
			VALUES (
			    locals.current_tag
			)
			RETURNING
			    id
			INTO
			    locals.current_tag_id;
		END IF;
		INSERT INTO
		    core.article_tag (
		        article_id,
		        tag_id
		    )
		VALUES (
		    locals.article_id,
		    locals.current_tag_id
		);
	END LOOP;
	RETURN
	    locals.article_id;
END;
$$;

-- add twitter handle status enum
CREATE TYPE core.twitter_handle_assignment AS ENUM (
    'none',
    'manual',
    'name_search',
    'name_and_company_search'
);

-- add twitter handle columns to author and source
ALTER TABLE
    core.author
ADD COLUMN
    twitter_handle text,
ADD COLUMN
    twitter_handle_assignment core.twitter_handle_assignment NOT NULL DEFAULT 'none';

ALTER TABLE
    core.source
DROP COLUMN
    parser,
ADD COLUMN
    twitter_handle text,
ADD COLUMN
    twitter_handle_assignment core.twitter_handle_assignment NOT NULL DEFAULT 'none';

-- add functions
CREATE FUNCTION article_api.get_authors_of_article(
    article_id bigint
)
RETURNS SETOF core.author
LANGUAGE SQL
STABLE
AS $$
    SELECT
        author.*
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
    WHERE
        article_author.article_id = get_authors_of_article.article_id;
$$;

CREATE FUNCTION article_api.get_source_of_article(
    article_id bigint
)
RETURNS SETOF core.source
LANGUAGE SQL
STABLE
AS $$
    SELECT
        source.*
    FROM
        core.article
        JOIN core.source ON
            source.id = article.source_id
    WHERE
        article.id = get_source_of_article.article_id;
$$;

CREATE FUNCTION article_api.assign_twitter_handle_to_author(
    author_id bigint,
    twitter_handle text,
    twitter_handle_assignment text
)
RETURNS SETOF core.author
LANGUAGE SQL
AS $$
    UPDATE
        core.author
    SET
        twitter_handle = assign_twitter_handle_to_author.twitter_handle,
        twitter_handle_assignment = assign_twitter_handle_to_author.twitter_handle_assignment::core.twitter_handle_assignment
    WHERE
        author.id = assign_twitter_handle_to_author.author_id
    RETURNING
        *;
$$;

CREATE FUNCTION article_api.assign_twitter_handle_to_source(
    source_id bigint,
    twitter_handle text,
    twitter_handle_assignment text
)
RETURNS SETOF core.source
LANGUAGE SQL
AS $$
    UPDATE
        core.source
    SET
        twitter_handle = assign_twitter_handle_to_source.twitter_handle,
        twitter_handle_assignment = assign_twitter_handle_to_source.twitter_handle_assignment::core.twitter_handle_assignment
    WHERE
        source.id = assign_twitter_handle_to_source.source_id
    RETURNING
        *;
$$;

-- add twitter_bot_tweet table and function
CREATE TABLE core.twitter_bot_tweet (
    id bigserial PRIMARY KEY,
    handle text NOT NULL,
    date_tweeted timestamp NOT NULL DEFAULT core.utc_now(),
    article_id bigint REFERENCES core.article (id),
    comment_id bigint REFERENCES core.comment (id),
    content text NOT NULL,
    tweet_id text NOT NULL,
    CONSTRAINT twitter_bot_tweet_reference CHECK (
        article_id IS NOT NULL OR
        comment_id IS NOT NULL
    )
);

CREATE FUNCTION analytics.log_twitter_bot_tweet(
    handle text,
    article_id bigint,
    comment_id bigint,
    content text,
    tweet_id text
)
RETURNS SETOF core.twitter_bot_tweet
LANGUAGE SQL
AS $$
    INSERT INTO
        core.twitter_bot_tweet (
            handle,
            article_id,
            comment_id,
            content,
            tweet_id
        )
    VALUES (
        log_twitter_bot_tweet.handle,
        log_twitter_bot_tweet.article_id,
        log_twitter_bot_tweet.comment_id,
        log_twitter_bot_tweet.content,
        log_twitter_bot_tweet.tweet_id
    )
    RETURNING
        *;
$$;