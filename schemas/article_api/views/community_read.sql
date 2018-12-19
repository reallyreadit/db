CREATE VIEW article_api.community_read AS
SELECT
	id,
	hot_score,
    top_score
FROM article
WHERE
	(
	    hot_score > 0 OR
	    top_score > 0
	) AND
	(
		aotd_timestamp IS NULL OR
		aotd_timestamp != (SELECT max(aotd_timestamp) FROM article)
	);