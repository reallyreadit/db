-- set new cached column initial values
UPDATE article
SET
	comment_count = coalesce(
		(
			SELECT count
			FROM article_api.article_comment_count
			WHERE article_id = article.id
		),
	    0
	),
	read_count = coalesce(
		(
			SELECT count
			FROM article_api.article_read_count
			WHERE article_id = article.id
		),
	    0
	),
	average_rating_score = (
		SELECT score
		FROM article_api.average_article_rating
		WHERE article_id = article.id
	)
WHERE true;