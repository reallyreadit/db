-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- add aotd_contender_rank column to article
ALTER TABLE
    core.article
ADD COLUMN
    aotd_contender_rank int NOT NULL DEFAULT 0;

-- drop hot_velocity from article_api.article, article_api.article_page_result and social.article_post_page_result
ALTER TYPE
    article_api.article
DROP ATTRIBUTE
    hot_velocity;

ALTER TYPE
    article_api.article_page_result
DROP ATTRIBUTE
    hot_velocity;

ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    hot_velocity;

-- add aotd_contender_rank to article_api.article, article_api.article_page_result and social.article_post_page_result
ALTER TYPE
    article_api.article
ADD ATTRIBUTE
    aotd_contender_rank int;

ALTER TYPE
    article_api.article_page_result
DROP ATTRIBUTE
    total_count;
ALTER TYPE
    article_api.article_page_result
ADD ATTRIBUTE
    aotd_contender_rank int;
ALTER TYPE
    article_api.article_page_result
ADD ATTRIBUTE
    total_count bigint;

ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    total_count;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    has_alert;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    date_deleted;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    silent_post_id;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    comment_addenda;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    comment_text;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    comment_id;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    user_name;
ALTER TYPE
    social.article_post_page_result
DROP ATTRIBUTE
    post_date_created;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    aotd_contender_rank int;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    post_date_created timestamp;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    user_name text;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    comment_id bigint;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    comment_text text;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    comment_addenda social.comment_addendum[];
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    silent_post_id bigint;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    date_deleted timestamp;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    has_alert bool;
ALTER TYPE
    social.article_post_page_result
ADD ATTRIBUTE
    total_count bigint;

-- update article_api.get_articles to return new columns
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
		coalesce(
		   article_api.get_percent_complete(
		      user_article.readable_word_count,
		      user_article.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score,
	    coalesce(posts.dates, '{}'),
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank
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
		LEFT JOIN user_article ON (
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id
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
		) AS posts
			ON posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster
			ON first_poster.id = article.first_poster_id
	ORDER BY
	    array_position(article_ids, article.id)
$$;

-- update article_api.score_articles to use correct cutoff, zeroing and set aotd_contender_rank
CREATE OR REPLACE FUNCTION article_api.score_articles()
RETURNS void
LANGUAGE sql
AS $$
    WITH scorable_criteria AS (
        SELECT
            core.utc_now() - '1 month'::interval - ('10 minutes'::interval) AS cutoff_date
    ),
	scored_article AS (
		SELECT
			community_read.id,
		    community_read.aotd_timestamp,
			(
				(
					coalesce(scored_first_user_comment.hot_score, 0) +
					(coalesce(scored_read.hot_score, 0) * greatest(1, core.estimate_article_length(community_read.word_count) / 7))::int
				) * (coalesce(community_read.average_rating_score, 5) / 5)
			) / (
				CASE
				    -- divide articles from billloundy.com and blog.readup.com by 10
				    WHEN community_read.source_id IN (7038, 48542)
				    THEN 10
				    ELSE 1
				END
			) AS hot_score,
			(
				(
					coalesce(scored_first_user_comment.count, 0) +
					(coalesce(scored_read.count, 0) * greatest(1, core.estimate_article_length(community_read.word_count) / 7))::int
				) * (coalesce(community_read.average_rating_score, 5) / 5)
			) AS top_score
		FROM
		    community_reads.community_read JOIN
			(
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
			) AS scorable_article ON
		        community_read.id = scorable_article.id
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

-- hard reset of all scores
UPDATE
    core.article
SET
    hot_score = 0,
    top_score = 0
WHERE
    hot_score != 0 OR
    top_score != 0;

-- rescore all articles
WITH scorable_criteria AS (
    SELECT
        least(
            (
                SELECT
                    min(date_completed)
                FROM
                    core.user_article
            ),
            (
                SELECT
                    min(date_created)
                FROM
                    core.comment
            )
        ) AS cutoff_date
),
scored_article AS (
    SELECT
        community_read.id,
        community_read.aotd_timestamp,
        (
            (
                coalesce(scored_first_user_comment.hot_score, 0) +
                (coalesce(scored_read.hot_score, 0) * greatest(1, core.estimate_article_length(community_read.word_count) / 7))::int
            ) * (coalesce(community_read.average_rating_score, 5) / 5)
        ) / (
            CASE
                -- divide articles from billloundy.com and blog.readup.com by 10
                WHEN community_read.source_id IN (7038, 48542)
                THEN 10
                ELSE 1
            END
        ) AS hot_score,
        (
            (
                coalesce(scored_first_user_comment.count, 0) +
                (coalesce(scored_read.count, 0) * greatest(1, core.estimate_article_length(community_read.word_count) / 7))::int
            ) * (coalesce(community_read.average_rating_score, 5) / 5)
        ) AS top_score
    FROM
        community_reads.community_read JOIN
        (
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
        ) AS scorable_article ON
            community_read.id = scorable_article.id
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