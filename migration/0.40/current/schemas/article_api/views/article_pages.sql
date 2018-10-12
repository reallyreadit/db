CREATE VIEW article_api.article_pages AS (
	SELECT
		array_agg(url ORDER BY number) AS urls,
		count(*) AS count,
		sum(word_count) AS word_count,
		sum(readable_word_count) AS readable_word_count,
		article_id
	FROM page
	GROUP BY article_id
);