CREATE OR REPLACE VIEW article_api.average_article_rating AS
SELECT
	article_id,
   avg(score) AS score
FROM
	article_api.user_article_rating
GROUP BY
	article_id;