-- replace queries to source from community_reads.community_read instead of core.article
CREATE OR REPLACE FUNCTION community_reads.get_highest_rated(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
AS $$
    WITH highest_rated AS (
		SELECT
			community_read.id,
			avg(user_article_rating.score) AS average_rating_score
		FROM
			community_reads.community_read
			JOIN article_api.user_article_rating ON user_article_rating.article_id = community_read.id
		WHERE
			since_date IS NOT NULL AND
			user_article_rating.timestamp >= since_date
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			average_rating_score
		FROM community_reads.community_read
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

CREATE OR REPLACE FUNCTION community_reads.get_most_commented(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
AS $$
    WITH most_commented AS (
		SELECT
			community_read.id,
			count(*) AS comment_count
		FROM
			community_reads.community_read
			JOIN comment ON comment.article_id = community_read.id
		WHERE
			since_date IS NOT NULL AND
			comment.date_created>= since_date
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			comment_count
		FROM community_reads.community_read
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

CREATE OR REPLACE FUNCTION community_reads.get_most_read(
	user_account_id bigint,
	page_number integer,
	page_size integer,
	since_date timestamp without time zone
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql
STABLE
    AS $$
    WITH most_read AS (
		SELECT
			community_read.id,
			count(*) AS read_count
		FROM
			community_reads.community_read
			JOIN page ON page.article_id = community_read.id
			JOIN user_page ON user_page.page_id = page.id
		WHERE
			since_date IS NOT NULL AND
			user_page.date_completed >= since_date
		GROUP BY
			community_read.id
		UNION ALL
		SELECT
			id,
			read_count
		FROM community_reads.community_read
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