CREATE FUNCTION article_api.list_hot_topics(
	page_number int,
	page_size int
) RETURNS SETOF article_api.article_page_result
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		count(*) OVER() AS total_count
	FROM article_api.article
	WHERE comment_count > 0
	ORDER BY latest_comment_date DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;