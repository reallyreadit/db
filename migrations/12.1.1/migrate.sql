-- handicap billloundy.substack.com
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
				    -- divide articles from billloundy.com, blog.readup.com and billloundy.substack.com by 10
				    WHEN community_read.source_id IN (7038, 48542, 63802)
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