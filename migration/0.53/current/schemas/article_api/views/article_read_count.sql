CREATE VIEW article_api.article_read_count AS
SELECT
	count(*) AS count,
	article_id
FROM article_api.user_article_pages
WHERE date_completed IS NOT NULL
GROUP BY article_id;