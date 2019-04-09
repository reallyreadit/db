-- update cached comment count when creating new comment
CREATE OR REPLACE FUNCTION article_api.create_comment(
	text text,
	article_id bigint,
	parent_comment_id bigint,
	user_account_id bigint
)
RETURNS SETOF article_api.user_comment
LANGUAGE plpgsql
AS $$
DECLARE
	comment_id bigint;
BEGIN
	-- insert the new comment, saving the id
	INSERT INTO comment
        (text, article_id, parent_comment_id, user_account_id)
	VALUES
    	(text, article_id, parent_comment_id, user_account_id)
	RETURNING id INTO comment_id;
	-- update the cached article comment count
	UPDATE article
	SET comment_count = comment_count + 1
	WHERE id = article_id;
	-- return the user_comment
	RETURN QUERY
	SELECT *
	FROM article_api.user_comment
	WHERE id = comment_id;
END;
$$;

-- update cached read count when a user finishes reading an article (and fix locking on user_page row)
CREATE OR REPLACE FUNCTION article_api.update_read_progress(
	user_page_id bigint,
	read_state int[]
)
RETURNS user_page
LANGUAGE plpgsql
STRICT
AS $$
<<locals>>
DECLARE
   -- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT sum(n)
		FROM unnest(read_state) AS n
		WHERE n > 0
	);
    -- local user_page
	current_user_page user_page;
BEGIN
    -- read and lock the existing user_page
    SELECT *
    INTO locals.current_user_page
	FROM user_page
	WHERE user_page.id = update_read_progress.user_page_id
	FOR UPDATE;
	-- only update if more words have been read
	IF words_read > locals.current_user_page.words_read
	THEN
		-- update the progress
		UPDATE user_page
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = utc_now()
		WHERE user_page.id = update_read_progress.user_page_id
		RETURNING *
		INTO locals.current_user_page;
		-- check if this update completed the page
		IF
			locals.current_user_page.date_completed IS NULL AND
			(
				SELECT article_api.get_percent_complete(
					locals.current_user_page.readable_word_count,
					locals.words_read
				) >= 90
			)
		THEN
			-- set date_completed
			UPDATE user_page
			SET date_completed = user_page.last_modified
			WHERE user_page.id = update_read_progress.user_page_id
			RETURNING *
			INTO locals.current_user_page;
			-- update the cached article read count
			UPDATE article
			SET read_count = read_count + 1
			WHERE id = (
					SELECT article_id
					FROM page
					WHERE id = locals.current_user_page.page_id
				);
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_page;
END;
$$;

-- update cached average rating score when a user rates an article
DROP FUNCTION article_api.rate_article(
	article_id bigint,
	user_account_id bigint,
	score rating_score
);

CREATE FUNCTION article_api.rate_article(
	article_id bigint,
	user_account_id bigint,
	score rating_score
)
RETURNS rating
LANGUAGE plpgsql
STRICT
AS $$
<<locals>>
DECLARE
   current_rating rating;
BEGIN
	-- insert the new rating
	INSERT INTO rating
		(score, article_id, user_account_id)
	VALUES
		(score, article_id, user_account_id)
	RETURNING *
	INTO locals.current_rating;
	-- update the cached article average rating score
	UPDATE article
	SET average_rating_score = (
	   	SELECT avg(user_article_rating.score)
	   	FROM article_api.user_article_rating
	   	WHERE user_article_rating.article_id = rate_article.article_id
	)
	WHERE id = rate_article.article_id;
	-- return
	RETURN locals.current_rating;
END;
$$;

-- update article_api.score_articles to include (optimized) hot/top calculations from the article_api.article_score view
CREATE OR REPLACE FUNCTION article_api.score_articles()
RETURNS void
LANGUAGE SQL
AS $$
	WITH score AS (
		SELECT
			article.id AS article_id,
			(
				(
				    coalesce(comments.score, 0) +
					(coalesce(reads.score, 0) * greatest(1, (article_pages.word_count::double precision / 184) / 5))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS hot,
			(
				(
					coalesce(comments.count, 0) +
					(coalesce(reads.count, 0) * greatest(1, (article_pages.word_count::double precision / 184) / 5))::int
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
			JOIN article_api.article_pages ON article_pages.article_id = article.id
			LEFT JOIN (
				SELECT
					count(*) AS count,
					sum(
						CASE
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

DROP VIEW article_api.article_score;

-- update article_api.get_articles to use cached article columns
CREATE OR REPLACE FUNCTION article_api.get_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.article
LANGUAGE SQL
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
		article_pages.word_count,
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

DROP VIEW article_api.article_comment_count;

DROP VIEW article_api.article_read_count;

DROP VIEW article_api.average_article_rating;

-- add timestamp to article_api.user_article_rating view
DROP VIEW article_api.user_article_rating;

CREATE VIEW article_api.user_article_rating
AS (
	SELECT
	    rating.article_id,
		rating.user_account_id,
		rating.score,
	    rating.timestamp
	FROM
		rating
		LEFT JOIN rating AS more_recent_rating
		    ON (
		    	rating.article_id = more_recent_rating.article_id AND
				rating.user_account_id = more_recent_rating.user_account_id AND
				rating.timestamp < more_recent_rating.timestamp
		    )
	WHERE more_recent_rating.id IS NULL
);

-- drop article_api community reads objects
DROP FUNCTION article_api.get_community_reads(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	sort text
);

DROP VIEW article_api.community_read;

-- create new community read schema
CREATE SCHEMA community_reads;

-- create new community read view
CREATE VIEW community_reads.community_read
AS (
    SELECT
    	id,
		aotd_timestamp,
		hot_score,
		top_score,
        comment_count,
        read_count,
        average_rating_score
    FROM article
    WHERE (
		comment_count > 0 OR
		read_count > 1 OR
		average_rating_score IS NOT NULL
	)
);

-- move get_aotd() from article_api to community_reads
DROP FUNCTION article_api.get_aotd(
	user_account_id bigint
);

CREATE FUNCTION community_reads.get_aotd(
	user_account_id bigint
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT 1
		)
	);
$$;

-- move set_aotd() from article_api to community_reads and use new community read view
DROP FUNCTION article_api.set_aotd();

CREATE FUNCTION community_reads.set_aotd()
RETURNS void
LANGUAGE SQL
AS $$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM
			community_reads.community_read
			JOIN article_api.article_pages ON article_pages.article_id = community_read.id
		WHERE
			aotd_timestamp IS NULL AND
			word_count >= (184 * 5)
		ORDER BY hot_score DESC
		LIMIT 1
	);
$$;

-- create listed community read view
CREATE VIEW community_reads.listed_community_read
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
        aotd_timestamp != (
        	SELECT max(aotd_timestamp)
        	FROM article
		)
);

-- create function to query hot listed community reads
CREATE FUNCTION community_reads.get_hot(
	user_account_id bigint,
	page_number integer,
	page_size integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH hot_read AS (
        SELECT
            id,
            hot_score
        FROM community_reads.listed_community_read
        WHERE hot_score > 0
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

-- create function to query most read listed community reads
CREATE FUNCTION community_reads.get_most_read(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH most_read AS (
		SELECT
			article.id,
			count(*) AS read_count
		FROM
			article
			JOIN page ON page.article_id = article.id
			JOIN user_page ON user_page.page_id = page.id
		WHERE
			since_date IS NOT NULL AND
			user_page.date_completed >= since_date
		GROUP BY
			article.id
		UNION ALL
		SELECT
			id,
			read_count
		FROM article
		WHERE
			since_date IS NULL AND
			read_count > 0
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

-- create function to query most commented listed community reads
CREATE FUNCTION community_reads.get_most_commented(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH most_commented AS (
		SELECT
			article.id,
			count(*) AS comment_count
		FROM
			article
			JOIN comment ON comment.article_id = article.id
		WHERE
			since_date IS NOT NULL AND
			comment.date_created>= since_date
		GROUP BY
			article.id
		UNION ALL
		SELECT
			id,
			comment_count
		FROM article
		WHERE
			since_date IS NULL AND
			comment_count > 0
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

-- create function to query highest rated listed community reads
CREATE FUNCTION community_reads.get_highest_rated(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH highest_rated AS (
		SELECT
			article.id,
			avg(user_article_rating.score) AS average_rating_score
		FROM
			article
			JOIN article_api.user_article_rating ON user_article_rating.article_id = article.id
		WHERE
			since_date IS NOT NULL AND
			user_article_rating.timestamp >= since_date
		GROUP BY
			article.id
		UNION ALL
		SELECT
			id,
			average_rating_score
		FROM article
		WHERE
			since_date IS NULL AND
			average_rating_score IS NOT NULL
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

-- create function to query top listed community reads
CREATE FUNCTION community_reads.get_top(
	user_account_id bigint,
	page_number integer,
	page_size integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
    WITH top_read AS (
        SELECT
            id,
            top_score
        FROM community_reads.listed_community_read
        WHERE top_score > 0
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