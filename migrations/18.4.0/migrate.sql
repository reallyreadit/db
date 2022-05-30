-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/* Add new author view with user account assignment. */
CREATE VIEW
	authors.author
AS (
	SELECT
		author.id,
		author.name,
		author.url,
		author.twitter_handle,
		author.twitter_handle_assignment,
		author.slug,
		author.email_address,
		assignment.user_account_id
	FROM
		core.author
		LEFT JOIN
			core.author_user_account_assignment AS assignment ON
				author.id = assignment.author_id
);

/* Update author functions to return new view. */
DROP FUNCTION
	authors.assign_twitter_handle_to_author(
		author_id bigint,
		twitter_handle text,
		twitter_handle_assignment text
);
CREATE FUNCTION
	authors.assign_twitter_handle_to_author(
		author_id bigint,
		twitter_handle text,
		twitter_handle_assignment text
)
RETURNS
	SETOF authors.author
LANGUAGE
	plpgsql
AS $$
BEGIN
	-- update the author
    UPDATE
        core.author
    SET
        twitter_handle = assign_twitter_handle_to_author.twitter_handle,
        twitter_handle_assignment = assign_twitter_handle_to_author.twitter_handle_assignment::core.twitter_handle_assignment
    WHERE
        author.id = assign_twitter_handle_to_author.author_id;
	-- return from view
	RETURN QUERY
	SELECT
		*
	FROM
		authors.author
	WHERE
		author.id = assign_twitter_handle_to_author.author_id;
END;
$$;

DROP FUNCTION
	authors.get_author(
		slug text
	);
CREATE FUNCTION
	authors.get_author(
		slug text
	)
RETURNS
	SETOF authors.author
LANGUAGE
	sql
STABLE
AS $$
    SELECT
        author.*
    FROM
        authors.author
    WHERE
        author.slug = get_author.slug;
$$;

DROP FUNCTION authors.get_authors_of_article(
	article_id bigint
);
CREATE FUNCTION authors.get_authors_of_article(
	article_id bigint
)
RETURNS
	SETOF authors.author
LANGUAGE
	sql
STABLE
AS $$
    SELECT
        author.*
    FROM
        core.article_author
        JOIN authors.author ON
            author.id = article_author.author_id
    WHERE
        article_author.article_id = get_authors_of_article.article_id AND
        article_author.date_unassigned IS NULL;
$$;