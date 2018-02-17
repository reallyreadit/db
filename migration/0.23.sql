CREATE OR REPLACE FUNCTION article_api.set_aotd() RETURNS void
LANGUAGE SQL AS $func$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM article_api.article
		WHERE
			aotd_timestamp IS NULL AND
			(comment_count > 0 OR read_count > 1)
		ORDER BY score DESC
		LIMIT 1
	);
$func$;