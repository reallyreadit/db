CREATE FUNCTION article_api.set_aotd() RETURNS void
LANGUAGE SQL AS $func$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM article
		WHERE aotd_timestamp IS NULL
		ORDER BY score DESC
		LIMIT 1
	);
$func$;