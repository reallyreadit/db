CREATE FUNCTION article_api.get_aotd()
RETURNS SETOF article_api.article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date
	FROM article_api.article
	WHERE id = (
		SELECT id
		FROM core.article
		ORDER BY core.article.aotd_timestamp DESC NULLS LAST
		LIMIT 1
	);
$func$;