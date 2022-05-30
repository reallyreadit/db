-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- handicap Bill Loundy author
CREATE OR REPLACE FUNCTION article_api.score_articles() RETURNS void
LANGUAGE sql
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
                        -- divide articles by Bill Loundy (id # 49) by 10
                        WHEN 49 = ANY(article_authors.author_ids)
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