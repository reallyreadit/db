CREATE VIEW article_api.article_score AS
SELECT
	article_pages.article_id,
	CASE WHEN (comments.count > 0 OR reads.count > 1) THEN
		(
			coalesce(comments.score, 0) +
			(coalesce(reads.score, 0) * greatest(1, (article_pages.word_count::double precision / 184) / 5))::int
		)
		ELSE 0
	END AS score
FROM
	article_api.article_pages
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
	) AS comments ON comments.article_id = article_pages.article_id
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
				utc_now() - last_modified AS age
			FROM article_api.user_article_pages
			WHERE date_completed IS NOT NULL
		) AS read
		GROUP BY article_id
	) AS reads ON reads.article_id = article_pages.article_id;