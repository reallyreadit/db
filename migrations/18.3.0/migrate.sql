/*
	Add date_assigned, date_unassigned, and assignment_method columns to article_author in order to track assignments over
	time.
*/
CREATE TYPE
	core.author_assignment_method
AS ENUM (
	'metadata',
	'manual'
);

ALTER TABLE
	core.article_author
ADD COLUMN
	date_assigned timestamp NOT NULL
DEFAULT
	core.utc_now(),
ADD COLUMN
	date_unassigned timestamp,
ADD COLUMN
	assignment_method core.author_assignment_method NOT NULL
DEFAULT
	'metadata'::core.author_assignment_method;

/*
	Add article_author type to article, article_page_result and article_post_page_result in order to return author names
	and slugs.
*/
CREATE TYPE
	article_api.article_author
AS (
	name text,
	slug text
);

ALTER TYPE
	article_api.article
ADD ATTRIBUTE
	article_authors article_api.article_author[];

ALTER TYPE
	article_api.article_page_result
DROP ATTRIBUTE
	total_count,
ADD ATTRIBUTE
	article_authors article_api.article_author[],
ADD ATTRIBUTE
	total_count bigint;

ALTER TYPE
	social.article_post_page_result
DROP ATTRIBUTE
	total_count,
DROP ATTRIBUTE
	has_alert,
DROP ATTRIBUTE
	date_deleted,
DROP ATTRIBUTE
	silent_post_id,
DROP ATTRIBUTE
	comment_addenda,
DROP ATTRIBUTE
	comment_text,
DROP ATTRIBUTE
	comment_id,
DROP ATTRIBUTE
	user_name,
DROP ATTRIBUTE
	post_date_created,
ADD ATTRIBUTE
	article_authors article_api.article_author[],
ADD ATTRIBUTE
	post_date_created timestamp,
ADD ATTRIBUTE
	user_name text,
ADD ATTRIBUTE
	comment_id bigint,
ADD ATTRIBUTE
	comment_text text,
ADD ATTRIBUTE
	comment_addenda social.comment_addendum[],
ADD ATTRIBUTE
	silent_post_id bigint,
ADD ATTRIBUTE
	date_deleted timestamp,
ADD ATTRIBUTE
	has_alert bool,
ADD ATTRIBUTE
	total_count bigint;

-- Update functions to filter unassigned authors and add article_authors array.
CREATE OR REPLACE FUNCTION
	article_api.get_article_for_provisional_user(
		article_id bigint,
		provisional_user_account_id bigint
	)
RETURNS
	SETOF article_api.article
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1],
		coalesce(article_authors.names, '{}'),
		coalesce(article_tags.names, '{}'),
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		provisional_user_article.date_created,
	    coalesce(
           article_api.get_percent_complete(
              provisional_user_article.readable_word_count,
              provisional_user_article.words_read
           ),
           0
        ),
	    provisional_user_article.date_completed IS NOT NULL,
		NULL::timestamp,
		article.average_rating_score,
		NULL::core.rating_score,
	    ARRAY[]::timestamp[],
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank,
	    coalesce(article_authors.authors, '{}')
	FROM
		core.article
		JOIN
		    article_api.article_pages ON
                article_pages.article_id = article.id
		JOIN
		    core.source ON
		        source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        array_agg((author.name, author.slug)::article_api.article_author) AS authors
		    FROM
		        core.article_author
		        JOIN
		            core.author ON
		                author.id = article_author.author_id
		    WHERE
		        article_author.article_id = get_article_for_provisional_user.article_id AND
		        article_author.date_unassigned IS NULL
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN
		    article_api.article_tags ON
                article_tags.article_id = article.id
		LEFT JOIN
		    core.provisional_user_article ON
		        provisional_user_article.article_id = article.id AND
                provisional_user_article.provisional_user_account_id = get_article_for_provisional_user.provisional_user_account_id
		LEFT JOIN
		    core.user_account AS first_poster ON
		        first_poster.id = article.first_poster_id
	WHERE
        article.id = get_article_for_provisional_user.article_id;
$$;

CREATE OR REPLACE FUNCTION
	article_api.get_articles(
		user_account_id bigint,
		VARIADIC article_ids bigint[]
	)
RETURNS
	SETOF article_api.article
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1],
		coalesce(article_authors.names, '{}'),
		coalesce(article_tags.names, '{}'),
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		user_article.date_created,
	    CASE WHEN article_authors.user_is_author
	        THEN 100
	        ELSE coalesce(
               article_api.get_percent_complete(
                  user_article.readable_word_count,
                  user_article.words_read
               ),
               0
            )
		END AS percent_complete,
	    CASE WHEN article_authors.user_is_author
	        THEN TRUE
	        ELSE user_article.date_completed IS NOT NULL
	    END AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score,
	    coalesce(posts.dates, '{}'),
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank,
	    coalesce(article_authors.authors, '{}')
	FROM
		core.article
		JOIN article_api.article_pages ON
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (get_articles.article_ids)
		JOIN source ON
		    source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        array_agg((author.name, author.slug)::article_api.article_author) AS authors,
		        count(author_user_account_assignment.id) > 0 AS user_is_author
		    FROM
		        core.article_author
		        JOIN core.author ON
		            author.id = article_author.author_id
		        LEFT JOIN author_user_account_assignment ON
		            author_user_account_assignment.author_id = author.id AND
		            author_user_account_assignment.user_account_id = get_articles.user_account_id
		    WHERE
		        article_author.article_id = ANY (get_articles.article_ids) AND
		        article_author.date_unassigned IS NULL
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN article_api.article_tags ON
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (get_articles.article_ids)
		LEFT JOIN core.user_article ON
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id
		LEFT JOIN core.star ON
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		LEFT JOIN article_api.user_article_rating ON
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (get_articles.article_ids)
		LEFT JOIN (
			SELECT
				post.article_id,
				array_agg(post.date_created) AS dates
		    FROM
		    	social.post
		    WHERE
		    	post.article_id = ANY (get_articles.article_ids) AND
		        post.user_account_id = get_articles.user_account_id
			GROUP BY
				post.article_id
		) AS posts ON
		    posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster ON
		    first_poster.id = article.first_poster_id
	ORDER BY
	    array_position(get_articles.article_ids, article.id)
$$;

-- Update functions to filter unassigned authors.
CREATE OR REPLACE FUNCTION
	article_api.score_articles()
RETURNS
	void
LANGUAGE
	sql
AS $$
    WITH scorable_criteria AS (
        SELECT
            core.utc_now() - '1 month'::interval - ('10 minutes'::interval) AS cutoff_date
    ),
    scorable_article AS (
        SELECT DISTINCT
            article_id AS id
        FROM
            core.comment
        WHERE
            comment.date_created >= (SELECT cutoff_date FROM scorable_criteria)
        UNION
        SELECT DISTINCT
            article_id AS id
        FROM
            core.user_article
        WHERE
            user_article.date_completed >= (SELECT cutoff_date FROM scorable_criteria)
    ),
	scored_article AS (
		SELECT
			community_read.id,
		    community_read.aotd_timestamp,
			round(
			    (
                    (coalesce(scored_first_user_comment.hot_score, 0) + coalesce(scored_read.hot_score, 0)) *
                    (
                        CASE
                            WHEN community_read.word_count <= 184 THEN 0.15
                            WHEN community_read.word_count <= 368 THEN 0.25
                            ELSE (least(core.estimate_article_length(community_read.word_count), 30) + 4)::double precision / 7
                        END
                    ) *
                    (coalesce(community_read.average_rating_score, 5) / 5)
                ) /
			    (
                    CASE
                        -- divide articles by Bill Loundy (id # 49) and Jeff Camera (id # 216185) by 10
                        WHEN
                           49 = ANY(article_authors.author_ids) OR
                           216185 = ANY(article_authors.author_ids)
                        THEN 10
                        ELSE 1
                    END
                )
			) AS hot_score,
			round(
                (coalesce(scored_first_user_comment.count, 0) + coalesce(scored_read.count, 0)) *
                (
                    CASE
                        WHEN community_read.word_count <= 184 THEN 0.15
                        WHEN community_read.word_count <= 368 THEN 0.25
                        ELSE (least(core.estimate_article_length(community_read.word_count), 30) + 4)::double precision / 7
                    END
                ) *
                (coalesce(community_read.average_rating_score, 5) / 5)
			) AS top_score
		FROM
		    community_reads.community_read
		    JOIN scorable_article ON
		        scorable_article.id = community_read.id
		    LEFT JOIN (
		        SELECT
		            article_author.article_id,
		            array_agg(article_author.author_id) AS author_ids
		        FROM
		            core.article_author
		            JOIN scorable_article ON
		                scorable_article.id = article_author.article_id
		        WHERE
		            article_author.date_unassigned IS NULL
		        GROUP BY
		            article_author.article_id
            ) AS article_authors ON
                article_authors.article_id = community_read.id
			LEFT JOIN (
				SELECT
					count(first_user_comment.*) AS count,
					sum(
						CASE
							WHEN first_user_comment.age < '18 hours' THEN 400
							WHEN first_user_comment.age < '36 hours' THEN 200
							WHEN first_user_comment.age < '72 hours' THEN 150
							WHEN first_user_comment.age < '1 week' THEN 100
							WHEN first_user_comment.age < '2 weeks' THEN 50
							WHEN first_user_comment.age < '1 month' THEN 5
							ELSE 0
						END
					) AS hot_score,
					first_user_comment.article_id
				FROM (
					SELECT
						first_user_comment.article_id,
						utc_now() - first_user_comment.date_created AS age
					FROM
						core.comment AS first_user_comment
						JOIN scorable_article ON
						    scorable_article.id = first_user_comment.article_id
				    	LEFT JOIN core.comment AS earlier_user_comment ON (
				    		earlier_user_comment.article_id = first_user_comment.article_id AND
				    		earlier_user_comment.user_account_id = first_user_comment.user_account_id AND
				    		earlier_user_comment.date_created < first_user_comment.date_created
						)
				    WHERE
				    	earlier_user_comment.id IS NULL
				) AS first_user_comment
				GROUP BY
				    first_user_comment.article_id
			) AS scored_first_user_comment ON
			    scored_first_user_comment.article_id = community_read.id
			LEFT JOIN (
				SELECT
					count(read.*) AS count,
					sum(
						CASE
							WHEN read.age < '18 hours' THEN 350
							WHEN read.age < '36 hours' THEN 175
							WHEN read.age < '72 hours' THEN 125
							WHEN read.age < '1 week' THEN 75
							WHEN read.age < '2 weeks' THEN 25
							WHEN read.age < '1 month' THEN 5
							ELSE 0
						END
					) AS hot_score,
					read.article_id
				FROM (
					SELECT
						user_article.article_id,
						utc_now() - user_article.date_completed AS age
					FROM
					    core.user_article
                        JOIN scorable_article ON
                            scorable_article.id = user_article.article_id
					WHERE
					    user_article.date_completed IS NOT NULL
				) AS read
				GROUP BY
				    read.article_id
			) AS scored_read ON
			    scored_read.article_id = community_read.id
	),
    aotd_contender AS (
        SELECT
            scored_article.id,
            rank() OVER (ORDER BY scored_article.hot_score DESC) AS rank
        FROM
            scored_article
        WHERE
            scored_article.hot_score > 0 AND
            scored_article.aotd_timestamp IS NULL
    )
	UPDATE
	    core.article
	SET
		hot_score = scored_article.hot_score,
		top_score = scored_article.top_score,
	    aotd_contender_rank = coalesce(aotd_contender.rank, 0)
	FROM
	    scored_article
        LEFT JOIN aotd_contender ON
            scored_article.id = aotd_contender.id
	WHERE
	    scored_article.id = article.id;
$$;

CREATE OR REPLACE FUNCTION
	authors.get_authors_of_article(
		article_id bigint
	)
RETURNS
	SETOF core.author
LANGUAGE
	sql
STABLE
    AS $$
    SELECT
        author.*
    FROM
        core.article_author
        JOIN core.author ON
            author.id = article_author.author_id
    WHERE
        article_author.article_id = get_authors_of_article.article_id AND
        article_author.date_unassigned IS NULL;
$$;

CREATE OR REPLACE FUNCTION
	community_reads.get_articles_by_author_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
)
RETURNS
	SETOF article_api.article_page_result
LANGUAGE
	sql
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
			) AND
			article_author.date_unassigned IS NULL
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

CREATE OR REPLACE FUNCTION
	community_reads.search_articles(
		user_account_id bigint,
		page_number integer,
		page_size integer,
		source_slugs text[],
		author_slugs text[],
		tag_slugs text[],
		min_length integer,
		max_length integer
)
RETURNS SETOF
	article_api.article_page_result
LANGUAGE
	sql
STABLE
AS $$
    WITH filtered_article AS (
        SELECT DISTINCT ON (
                community_read.id
            )
            community_read.id,
            community_read.latest_read_timestamp,
            community_read.latest_post_timestamp
        FROM
            community_reads.community_read
            JOIN core.source ON
                source.id = community_read.source_id
            LEFT JOIN core.article_author ON
                article_author.article_id = community_read.id
            LEFT JOIN core.author ON
                author.id = article_author.author_id
            LEFT JOIN core.article_tag ON
                article_tag.article_id = community_read.id
            LEFT JOIN core.tag ON
                tag.id = article_tag.tag_id
        WHERE
            CASE WHEN array_length(search_articles.source_slugs, 1) > 0
                THEN
                    source.slug = ANY (search_articles.source_slugs)
                ELSE
                    TRUE
            END AND
            CASE WHEN array_length(search_articles.author_slugs, 1) > 0
                THEN
                    author.slug = ANY (search_articles.author_slugs) AND
                    article_author.date_unassigned IS NULL
                ELSE
                    TRUE
            END AND
            CASE WHEN array_length(search_articles.tag_slugs, 1) > 0
                THEN
                    tag.slug = ANY (search_articles.tag_slugs)
                ELSE
                    TRUE
            END AND
			core.matches_article_length(
				community_read.word_count,
			    search_articles.min_length,
			    search_articles.max_length
			)
        ORDER BY
            community_read.id
    )
    SELECT
    	articles.*,
		(
		    SELECT
		        count(*)
		    FROM
		        filtered_article
		)
    FROM
		article_api.get_articles(
			search_articles.user_account_id,
			VARIADIC ARRAY(
				SELECT
					filtered_article.id
				FROM
					filtered_article
				ORDER BY
					filtered_article.latest_post_timestamp DESC NULLS LAST,
				    filtered_article.latest_read_timestamp DESC,
				    filtered_article.id DESC
				OFFSET
					(search_articles.page_number - 1) * search_articles.page_size
				LIMIT
					search_articles.page_size
			)
		) AS articles;
$$;

CREATE OR REPLACE FUNCTION
	stats.get_top_author_leaderboard(
		max_rank integer,
		since_date timestamp without time zone
)
RETURNS
	TABLE(name text, slug text, score integer, rank integer)
LANGUAGE
	sql
STABLE
AS $$
    WITH ranking AS (
        SELECT
            author.name,
            author.slug,
            core.estimate_reading_time(
                sum(community_read.word_count)
            ) AS score,
            dense_rank() OVER (
                ORDER BY sum(community_read.word_count) DESC
            )::int AS rank
        FROM
            core.user_article
            JOIN community_reads.community_read ON
                community_read.id = user_article.article_id
            JOIN core.article_author ON
                article_author.article_id = user_article.article_id
            JOIN core.author ON
                author.id = article_author.author_id
        WHERE
            CASE WHEN get_top_author_leaderboard.since_date IS NOT NULL
                THEN user_article.date_completed >= get_top_author_leaderboard.since_date
                ELSE user_article.date_completed IS NOT NULL
            END AND
            article_author.date_unassigned IS NULL
        GROUP BY
            author.id
    )
    SELECT
        ranking.name,
        ranking.slug,
        ranking.score,
        ranking.rank
    FROM
        ranking
    WHERE
        ranking.rank <= get_top_author_leaderboard.max_rank
    ORDER BY
        ranking.rank,
        ranking.name;
$$;