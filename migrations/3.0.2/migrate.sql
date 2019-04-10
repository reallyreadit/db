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