WITH buckets AS (
	SELECT
		width_bucket(
			least((words_read / readable_word_count :: double precision) * 100, 100),
			0,
			100,
			19
		) AS bucket,
		count(*) AS bucket_count
	FROM article_api.user_article
	WHERE date_created IS NOT NULL
	GROUP BY bucket
	ORDER BY bucket
)
SELECT array_agg(bucket_count) FROM buckets;