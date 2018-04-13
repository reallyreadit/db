CREATE FUNCTION article_api.get_user_article(
	article_id uuid,
	user_account_id uuid
) RETURNS SETOF article_api.user_article
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
		date_starred
	FROM article_api.user_article
	WHERE
		id = article_id AND
		user_account_id = get_user_article.user_account_id;
$func$;