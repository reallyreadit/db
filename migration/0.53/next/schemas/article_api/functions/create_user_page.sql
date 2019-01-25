CREATE FUNCTION article_api.create_user_page(
	page_id bigint,
	user_account_id bigint,
	readable_word_count int
)
RETURNS user_page
LANGUAGE SQL
AS $func$
	INSERT INTO user_page (
	   page_id,
	   user_account_id,
	   read_state,
	   readable_word_count
	)
	VALUES (
		create_user_page.page_id,
		create_user_page.user_account_id,
		ARRAY[(SELECT -create_user_page.readable_word_count)],
	   create_user_page.readable_word_count
	)
	RETURNING *;
$func$;