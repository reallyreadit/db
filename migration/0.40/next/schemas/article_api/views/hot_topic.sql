CREATE VIEW article_api.hot_topic AS
SELECT
	id,
	score
FROM article
WHERE
	score > 0 AND
	(
		aotd_timestamp IS NULL OR
		aotd_timestamp != (SELECT max(aotd_timestamp) FROM article)
	);