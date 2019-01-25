CREATE FUNCTION article_api.update_page(
	page_id bigint,
	word_count int,
	readable_word_count int
)
RETURNS page
LANGUAGE SQL
AS $func$
	UPDATE page
	SET
	    word_count = update_page.word_count,
	    readable_word_count = update_page.readable_word_count
	WHERE page.id = update_page.page_id
	RETURNING *;
$func$;