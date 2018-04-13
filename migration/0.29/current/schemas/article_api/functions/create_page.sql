CREATE FUNCTION article_api.create_page(
	article_id uuid,
	number int,
	word_count int,
	readable_word_count int,
	url text
) RETURNS page
LANGUAGE SQL AS $func$
	INSERT INTO page (article_id, number, word_count, readable_word_count, url)
		VALUES (article_id, number, word_count, readable_word_count, url)
		RETURNING *;
$func$;