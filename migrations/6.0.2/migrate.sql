-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE OR REPLACE FUNCTION article_api.score_articles()
RETURNS void
LANGUAGE sql
AS $$
	WITH score AS (
		SELECT
			article.id AS article_id,
			(
				(
					coalesce(scored_first_comment.score, 0) +
					(coalesce(reads.score, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) / (
				CASE
				    -- divide articles from billloundy.com by 10
				    WHEN article.source_id = 7038
				    THEN 10
				    ELSE 1
				END
			) AS hot,
			(
				(
					coalesce(scored_first_comment.count, 0) +
					(coalesce(reads.count, 0) * greatest(1, core.estimate_article_length(article.word_count) / 7))::int
				) * (coalesce(article.average_rating_score, 5) / 5)
			) AS top
		FROM
			(
				SELECT DISTINCT article_id AS id
				FROM comment
				WHERE date_created > utc_now() - '1 month'::interval
				UNION
				SELECT DISTINCT article_id AS id
				FROM user_article
				WHERE date_completed > utc_now() - '1 month'::interval
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
						comment.article_id,
						utc_now() - comment.date_created AS age
					FROM
						comment
				    	LEFT JOIN comment AS earlier_comment ON (
				    		earlier_comment.article_id = comment.article_id AND
				    		earlier_comment.user_account_id = comment.user_account_id AND
				    		earlier_comment.date_created < comment.date_created
						)
				    WHERE
				    	earlier_comment.id IS NULL
				) AS first_comment
				GROUP BY article_id
			) AS scored_first_comment ON scored_first_comment.article_id = article.id
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
					FROM user_article
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