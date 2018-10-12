CREATE FUNCTION article_api.set_aotd()
RETURNS void
LANGUAGE SQL
AS $func$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM
			article
			JOIN article_api.article_pages ON article_pages.article_id = article.id
		WHERE
			aotd_timestamp IS NULL AND
			word_count >= (184 * 5) AND
			score > 0
		ORDER BY score DESC
		LIMIT 1
	);
$func$;