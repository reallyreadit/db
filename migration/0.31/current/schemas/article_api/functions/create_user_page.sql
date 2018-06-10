CREATE FUNCTION article_api.create_user_page(
	page_id bigint,
	user_account_id bigint
) RETURNS user_page
LANGUAGE SQL AS $func$
	INSERT INTO user_page (page_id, user_account_id, read_state)
	VALUES (
		page_id,
		user_account_id,
		ARRAY[(SELECT -word_count FROM page WHERE id = page_id)]
	)
	RETURNING *;
$func$;