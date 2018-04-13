CREATE FUNCTION article_api.list_user_article_history(
	user_account_id bigint,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_article_page_result
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
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_user_article_history.user_account_id AND
		(date_starred IS NOT NULL OR date_created IS NOT NULL)
	ORDER BY greatest(date_starred, date_created) DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;