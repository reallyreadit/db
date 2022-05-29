-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- create new cached word_count column on article for fast filtering
ALTER TABLE article
ADD COLUMN word_count int NOT NULL DEFAULT 0;

-- populate from existing records
UPDATE article
SET word_count = article_pages.word_count
FROM article_api.article_pages
WHERE article_pages.article_id = article.id;

-- create index for faster filtering
CREATE INDEX ON article (word_count);

-- create new function to estimate article length
CREATE FUNCTION core.estimate_article_length(
	word_count integer
)
RETURNS integer
IMMUTABLE
LANGUAGE sql
AS $$
    -- using integer division is equivalent to floor
    SELECT greatest(1, word_count / 184);
$$;

-- update article_api.create_page to cache word_count
CREATE OR REPLACE FUNCTION article_api.create_page(
	article_id bigint,
	number integer,
	word_count integer,
	readable_word_count integer,
	url text
)
RETURNS core.page
LANGUAGE plpgsql
AS $$
BEGIN
    -- set the cached word_count on article
    UPDATE article
    SET word_count = create_page.word_count
    WHERE id = create_page.article_id;
    -- create the new page and return it
	INSERT INTO page (article_id, number, word_count, readable_word_count, url)
	VALUES (article_id, number, word_count, readable_word_count, url)
	RETURNING *;
END;
$$;

-- update article_api.update_page to cache word_count
CREATE OR REPLACE FUNCTION article_api.update_page(
	page_id bigint,
	word_count integer,
	readable_word_count integer
)
RETURNS core.page
LANGUAGE plpgsql
AS $$
DECLARE
    updated_page page;
BEGIN
    -- update the page and store it in the local variable
	UPDATE page
	SET
	    word_count = update_page.word_count,
	    readable_word_count = update_page.readable_word_count
	WHERE page.id = update_page.page_id
	RETURNING * INTO updated_page;
    -- update the cached word_count on article
    UPDATE article
    SET word_count = update_page.word_count
    WHERE id = updated_page.article_id;
    -- return the updated page
    RETURN updated_page;
END;
$$;

-- update article_api.get_articles to use cached word_count
CREATE OR REPLACE FUNCTION article_api.get_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.article
LANGUAGE sql
STABLE
    AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name AS source,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1] AS url,
		coalesce(article_authors.names, '{}') AS authors,
		coalesce(article_tags.names, '{}') AS tags,
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		user_article_pages.date_created,
		coalesce(
		   article_api.get_percent_complete(
		      user_article_pages.readable_word_count,
		      user_article_pages.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article_pages.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score AS rating_score
	FROM
		article
		JOIN article_api.article_pages ON (
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (article_ids)
		)
		JOIN source ON source.id = article.source_id
		LEFT JOIN article_api.article_authors ON (
			article_authors.article_id = article.id AND
			article_authors.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_tags ON (
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.user_article_pages ON (
			user_article_pages.user_account_id = get_articles.user_account_id AND
			user_article_pages.article_id = article.id AND
			user_article_pages.article_id = ANY (article_ids)
		)
		LEFT JOIN star ON (
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		)
		LEFT JOIN article_api.user_article_rating ON (
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (article_ids)
		)
	ORDER BY array_position(article_ids, article.id)
$$;

-- update article_api.score_articles to use cached word_count and estimate_article_length
CREATE OR REPLACE FUNCTION article_api.score_articles()
RETURNS void
LANGUAGE sql
AS $$
	WITH score AS (
		SELECT
			article.id AS article_id,
			(
				(
					coalesce(comments.score, 0) +
					(coalesce(reads.score, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS hot,
			(
				(
					coalesce(comments.count, 0) +
					(coalesce(reads.count, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS top
		FROM
			(
			   SELECT DISTINCT article_id AS id
				FROM comment
				WHERE date_created > utc_now() - '1 month'::interval
				UNION
				SELECT DISTINCT page.article_id AS id
				FROM
					page
					JOIN user_page ON user_page.page_id = page.id
				WHERE user_page.date_completed > utc_now() - '1 month'::interval
			) AS scorable_article
			JOIN article ON article.id = scorable_article.id
			LEFT JOIN (
				SELECT
					count(*) AS count,
					sum(
						CASE
						   WHEN age < '18 hours' THEN 400
							WHEN age < '36 hours' THEN 200
							WHEN age < '72 hours' THEN 150
							WHEN age < '1 week' THEN 100
							WHEN age < '2 weeks' THEN 50
							WHEN age < '1 month' THEN 5
							ELSE 1
						END
					) AS score,
					article_id
				FROM (
					SELECT
						article_id,
						utc_now() - date_created AS age
					FROM comment
				) AS comment
				GROUP BY article_id
			) AS comments ON comments.article_id = article.id
			LEFT JOIN (
				SELECT
					count(*) AS count,
					sum(
						CASE
						   WHEN age < '18 hours' THEN 350
							WHEN age < '36 hours' THEN 175
							WHEN age < '72 hours' THEN 125
							WHEN age < '1 week' THEN 75
							WHEN age < '2 weeks' THEN 25
							WHEN age < '1 month' THEN 5
							ELSE 1
						END
					) AS score,
					article_id
				FROM (
					SELECT
						article_id,
						utc_now() - date_completed AS age
					FROM article_api.user_article_pages
					WHERE date_completed IS NOT NULL
				) AS read
				GROUP BY article_id
			) AS reads ON reads.article_id = article.id
	)
	UPDATE article
	SET
		hot_score = score.hot,
		top_score = score.top
	FROM score
	WHERE score.article_id = article.id;
$$;

-- drop all the existing community_reads query functions so that we can recreate the views and include word_count
DROP FUNCTION community_reads.set_aotd();
DROP FUNCTION community_reads.get_hot(
	user_account_id bigint,
	page_number integer,
	page_size integer
);
DROP FUNCTION community_reads.get_top(
	user_account_id bigint,
	page_number integer,
	page_size integer
);
DROP FUNCTION community_reads.get_most_commented(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
);
DROP FUNCTION community_reads.get_most_read(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
);
DROP FUNCTION community_reads.get_highest_rated(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
);

-- drop the community_reads views
DROP VIEW community_reads.listed_community_read;
DROP VIEW community_reads.community_read;

-- recreate the views with word_count
CREATE VIEW community_reads.community_read AS
SELECT
	article.id,
	article.aotd_timestamp,
    article.word_count,
	article.hot_score,
	article.top_score,
	article.comment_count,
	article.read_count,
	article.average_rating_score
FROM core.article
WHERE (
    (article.comment_count > 0) OR
    (article.read_count > 1) OR
    (article.average_rating_score IS NOT NULL)
);
CREATE VIEW community_reads.listed_community_read AS
SELECT
    community_read.id,
    community_read.word_count,
	community_read.hot_score,
	community_read.top_score,
	community_read.comment_count,
	community_read.read_count,
	community_read.average_rating_score
FROM community_reads.community_read
WHERE (
	community_read.aotd_timestamp IS DISTINCT FROM (
	    SELECT max(article.aotd_timestamp) AS max
        FROM core.article
	)
);

-- create new article length filter function
CREATE FUNCTION core.matches_article_length(
	word_count integer,
	min_length integer,
	max_length integer
)
RETURNS boolean
IMMUTABLE
LANGUAGE sql
AS $$
    SELECT (
    	CASE WHEN min_length IS NOT NULL
        THEN (SELECT core.estimate_article_length(word_count)) >= min_length
        ELSE TRUE
        END
	) AND (
	    CASE WHEN max_length IS NOT NULL
	    THEN (SELECT core.estimate_article_length(word_count)) < max_length + 1
	    ELSE TRUE
	    END
	);
$$;

-- recreate the query functions
CREATE FUNCTION community_reads.set_aotd()
RETURNS void
LANGUAGE sql
AS $$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM community_reads.community_read
		WHERE
			aotd_timestamp IS NULL AND
			core.matches_article_length(word_count, 5, NULL)
		ORDER BY hot_score DESC
		LIMIT 1
	);
$$;
CREATE FUNCTION community_reads.get_hot(
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
    WITH hot_read AS (
        SELECT
            id,
            hot_score
        FROM community_reads.listed_community_read
        WHERE (
			hot_score > 0 AND
			core.matches_article_length(
				word_count,
			    min_length,
			    max_length
			)
		)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM hot_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM hot_read
			ORDER BY hot_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION community_reads.get_top(
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
    WITH top_read AS (
        SELECT
            id,
            top_score
        FROM community_reads.listed_community_read
        WHERE (
			top_score > 0 AND
			core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM top_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM top_read
			ORDER BY top_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION community_reads.get_most_commented(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone,
	min_length integer,
	max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
    AS $$
    WITH most_commented AS (
		SELECT
			listed_community_read.id,
			count(*) AS comment_count
		FROM
			community_reads.listed_community_read
			JOIN comment ON comment.article_id = listed_community_read.id
		WHERE
			since_date IS NOT NULL AND
			comment.date_created >= since_date AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		GROUP BY
			listed_community_read.id
		UNION ALL
		SELECT
			id,
			comment_count
		FROM community_reads.listed_community_read
		WHERE
			since_date IS NULL AND
			comment_count > 0 AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM most_commented
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM most_commented
			ORDER BY comment_count DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION community_reads.get_most_read(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone,
	min_length integer,
	max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
    AS $$
    WITH most_read AS (
		SELECT
			listed_community_read.id,
			count(*) AS read_count
		FROM
			community_reads.listed_community_read
			JOIN page ON page.article_id = listed_community_read.id
			JOIN user_page ON user_page.page_id = page.id
		WHERE
			since_date IS NOT NULL AND
			user_page.date_completed >= since_date AND
		    core.matches_article_length(
				listed_community_read.word_count,
				min_length,
				max_length
			)
		GROUP BY
			listed_community_read.id
		UNION ALL
		SELECT
			id,
			read_count
		FROM community_reads.listed_community_read
		WHERE
			since_date IS NULL AND
			read_count > 0 AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM most_read
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM most_read
			ORDER BY read_count DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION community_reads.get_highest_rated(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone,
	min_length integer,
	max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
    AS $$
    WITH highest_rated AS (
		SELECT
			listed_community_read.id,
			avg(user_article_rating.score) AS average_rating_score
		FROM
			community_reads.listed_community_read
			JOIN article_api.user_article_rating ON user_article_rating.article_id = listed_community_read.id
		WHERE
			since_date IS NOT NULL AND
			user_article_rating.timestamp >= since_date AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
		GROUP BY
			listed_community_read.id
		UNION ALL
		SELECT
			id,
			average_rating_score
		FROM community_reads.listed_community_read
		WHERE
			since_date IS NULL AND
			average_rating_score IS NOT NULL AND
		    core.matches_article_length(
				word_count,
				min_length,
				max_length
			)
	)
    SELECT
    	articles.*,
		(
		    SELECT count(*)
		    FROM highest_rated
		) AS total_count
    FROM article_api.get_articles(
        user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM highest_rated
			ORDER BY average_rating_score DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;

-- recreate starred and history query functions
DROP FUNCTION article_api.get_starred_articles(
	user_account_id bigint,
	page_number integer,
	page_size integer
);
CREATE FUNCTION article_api.get_starred_articles(
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
	WITH starred_article AS (
		SELECT
			article_id,
			date_starred
		FROM
			star
			JOIN article ON article.id = star.article_id
		WHERE
			star.user_account_id = get_starred_articles.user_account_id AND
		    core.matches_article_length(
				article.word_count,
				min_length,
				max_length
			)
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM starred_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM starred_article
			ORDER BY date_starred DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
DROP FUNCTION article_api.get_article_history(
	user_account_id bigint,
	page_number integer,
	page_size integer
);
CREATE FUNCTION article_api.get_article_history(
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
	WITH history_article AS (
		SELECT
			greatest(user_article.date_created, user_article.last_modified, star.date_starred) AS history_date,
			coalesce(user_article.article_id, star.article_id) AS article_id
		FROM
			(
				SELECT
					date_created,
					last_modified,
					article_id
				FROM article_api.user_article_pages
				WHERE user_account_id = get_article_history.user_account_id
			) AS user_article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE user_account_id = get_article_history.user_account_id
			) AS star ON star.article_id = user_article.article_id
	    	JOIN article ON (
				article.id = user_article.article_id OR
				article.id = star.article_id
			)
	    WHERE core.matches_article_length(
			article.word_count,
			min_length,
			max_length
		)
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM history_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM history_article
			ORDER BY history_date DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;