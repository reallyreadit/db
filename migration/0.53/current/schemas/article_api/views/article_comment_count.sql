CREATE VIEW article_api.article_comment_count AS
SELECT
	count(*) AS count,
	article_id
FROM comment
GROUP BY article_id;