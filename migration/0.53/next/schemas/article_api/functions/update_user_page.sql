CREATE FUNCTION article_api.update_user_page(
	user_page_id bigint,
	readable_word_count int,
	read_state int[]
)
RETURNS user_page
LANGUAGE SQL
AS $func$
	UPDATE user_page
	SET
		readable_word_count = update_user_page.readable_word_count,
		read_state = update_user_page.read_state
	WHERE user_page.id = update_user_page.user_page_id
	RETURNING *;
$func$;