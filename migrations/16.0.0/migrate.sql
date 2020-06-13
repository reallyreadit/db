-- stage 1: cleanup of existing author names
-- step 1: replace general whitespace chars with SP
UPDATE
    core.author
SET
    name = regexp_replace(
        author.name,
        '[\u0009-\u000D\u0085\u00A0\u2000-\u200A\u2028\u2029\u202F\u205F]',
        ' ',
        'g'
    )
WHERE
    author.name ~ '[\u0009-\u000D\u0085\u00A0\u2000-\u200A\u2028\u2029\u202F\u205F]';
-- step 2: remove control and joiner chars
UPDATE
    core.author
SET
    name = regexp_replace(
        author.name,
        '[\u0000-\u001F\u007F\u0080-\u009F\u200B-\u200D\u2060\uFEFF]',
        '',
        'g'
    )
WHERE
    author.name ~ '[\u0000-\u001F\u007F\u0080-\u009F\u200B-\u200D\u2060\uFEFF]';
-- step 3: replace punctuation connector chars with SP
UPDATE
    core.author
SET
    name = regexp_replace(
        author.name,
        '[\u005F\u203F\u2040\u2054\uFE33\uFE34\uFE4D\uFE4E\uFE4F\uFF3F]',
        ' ',
        'g'
    )
WHERE
    author.name ~ '[\u005F\u203F\u2040\u2054\uFE33\uFE34\uFE4D\uFE4E\uFE4F\uFF3F]';
-- step 4: merge contiguous whitespace
UPDATE
    core.author
SET
    name = regexp_replace(
        author.name,
        '\s+',
        ' ',
        'g'
    )
WHERE
    author.name ~ '\s{2,}';
-- step 5: trim whitespace
UPDATE
    core.author
SET
    name = trim(author.name)
WHERE
    author.name ~ '^\s' OR
    author.name ~ '\s$';
-- step 6: delete if name doesn't contain at least one word char (delete orphaned author later on using index)
DELETE FROM
    core.article_author
WHERE
    author_id IN (
        SELECT
            author.id
        FROM
            core.author
        WHERE
            author.name ~ '^(\W|_)*$'
    );

-- stage 2: assign slug
-- step 1: add slug column to author table
ALTER TABLE
    core.author
ADD COLUMN
    slug text;
-- step 2: assign slug
UPDATE
    core.author
SET
    slug = lower(
        trim(
            '-' FROM regexp_replace(
                author.name,
                '(\W|_)+',
                '-',
                'g'
            )
        )
    )
WHERE
    TRUE;

-- stage 3: re-merge authors based on slug (modified 13.1.0 migration script)
-- step 1: create temporary reference view
CREATE TEMPORARY VIEW merged_author AS
SELECT DISTINCT ON (author.slug)
    author.id,
    author.slug
FROM
    core.author
    JOIN (
        SELECT
            author.slug
        FROM
            core.author
        GROUP BY
            author.slug
        HAVING
            count(*) > 1
    ) AS duplicate_author ON
        author.slug = duplicate_author.slug
ORDER BY
    author.slug,
    -- prefer assigned twitter handle
    author.twitter_handle,
    -- prefer the shortest name in order to cut down on noise
    length(
        -- don't penalize spaces, apostrophes, commas and periods
        regexp_replace(
            author.name,
            '[\u0020\u0027\u002C\u002E\u2019]',
            '',
            'g'
        )
    ),
    -- prefer spaces over other separator characters
    array_length(
        regexp_split_to_array(author.name, '\s'),
        1
    ) DESC,
    -- prefer apostrophes, commas and periods
    length(author.name) DESC;
-- step 2: delete redundant article_authors (modified to use slug)
WITH slugged_article_author AS (
    SELECT
        article_author.article_id,
        article_author.author_id,
        author.slug AS author_slug
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
),
duplicate AS (
    SELECT
        slugged_article_author.article_id,
        merged_author.id AS primary_author_id,
        slugged_article_author.author_slug
    FROM
        slugged_article_author
        JOIN merged_author ON
            merged_author.slug = slugged_article_author.author_slug
    GROUP BY
        slugged_article_author.article_id,
        slugged_article_author.author_slug,
        merged_author.id
    HAVING
        count(*) > 1
)
DELETE FROM
    core.article_author
WHERE
    (article_id, author_id) IN (
        SELECT
            slugged_article_author.article_id,
            slugged_article_author.author_id
        FROM
            slugged_article_author
            JOIN duplicate ON
                duplicate.article_id = slugged_article_author.article_id AND
                duplicate.author_slug = slugged_article_author.author_slug
        WHERE
            slugged_article_author.author_id != duplicate.primary_author_id
    );
-- step 3: merge authors (modified to use slug)
WITH duplicate_article_author AS (
    SELECT
        article_author.article_id,
        article_author.author_id,
        merged_author.id AS merged_author_id
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
        JOIN merged_author ON
            merged_author.slug = author.slug AND
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
-- step 4: drop reference view
DROP VIEW merged_author;
-- step 5: delete orphaned authors
CREATE INDEX
    article_author_author_id_idx ON
        core.article_author (author_id);

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

-- stage 4: enforce slug is unique and not null
ALTER TABLE
    core.author
ALTER COLUMN
    slug SET NOT NULL;

ALTER TABLE
    core.author
ADD CONSTRAINT
    author_slug_key UNIQUE (slug);

-- stage 5: fix author reconciliation (again)
DROP FUNCTION article_api.create_article(
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
);
CREATE TYPE article_api.author_metadata AS (
    name text,
    url text,
    slug text
);
CREATE FUNCTION article_api.create_article(
    title text,
    slug text,
    source_id bigint,
    date_published timestamp,
    date_modified timestamp,
    section text,
    description text,
    authors article_api.author_metadata[],
    tags text[]
)
RETURNS bigint
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
	article_id bigint;
    current_author article_api.author_metadata;
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
	FOREACH locals.current_author IN ARRAY create_article.authors LOOP
		SELECT
		    author.id
		INTO
		    locals.current_author_id
		FROM
		    core.author
		WHERE
		    author.slug = locals.current_author.slug
		FOR UPDATE;
		IF locals.current_author_id IS NULL THEN
			INSERT INTO
			    core.author (
                    name,
                    url,
                    slug
                )
			VALUES (
			    locals.current_author.name,
			    locals.current_author.url,
			    locals.current_author.slug
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

-- stage 6: create author article query function
CREATE FUNCTION community_reads.get_articles_by_author_slug(
    slug text,
    user_account_id bigint,
    page_number integer,
    page_size integer,
    min_length integer,
    max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
AS $$
    WITH author_article AS (
        SELECT
            community_read.id,
            community_read.date_published
        FROM
        	community_reads.community_read
            JOIN core.article_author ON
                article_author.article_id = community_read.id
            JOIN core.author ON
                author.id = article_author.author_id AND
                author.slug = get_articles_by_author_slug.slug
        WHERE
			core.matches_article_length(
				community_read.word_count,
			    get_articles_by_author_slug.min_length,
			    get_articles_by_author_slug.max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        author_article
		)
    FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
				SELECT
					author_article.id
				FROM
					author_article
				ORDER BY
					author_article.date_published DESC NULLS LAST,
				    author_article.id DESC
				OFFSET
					(get_articles_by_author_slug.page_number - 1) * get_articles_by_author_slug.page_size
				LIMIT
					get_articles_by_author_slug.page_size
			)
		) AS articles;
$$;

-- stage 7: create authors schema
CREATE SCHEMA authors;

DROP FUNCTION article_api.assign_twitter_handle_to_author(
    author_id bigint,
    twitter_handle text,
    twitter_handle_assignment text
);
CREATE FUNCTION authors.assign_twitter_handle_to_author(
    author_id bigint,
    twitter_handle text,
    twitter_handle_assignment text
)
RETURNS SETOF core.author
LANGUAGE sql
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

DROP FUNCTION article_api.get_authors_of_article(
    article_id bigint
);
CREATE FUNCTION authors.get_authors_of_article(
    article_id bigint
)
RETURNS SETOF core.author
LANGUAGE sql
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

CREATE FUNCTION authors.get_author(
    slug text
)
RETURNS SETOF core.author
LANGUAGE sql
STABLE
AS $$
    SELECT
        author.*
    FROM
        core.author
    WHERE
        author.slug = get_author.slug;
$$;