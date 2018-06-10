CREATE FUNCTION article_api.update_user_page(
	user_page_id bigint,
	read_state int[]
) RETURNS user_page
LANGUAGE SQL AS $func$
	UPDATE user_page SET
			read_state = update_user_page.read_state,
			words_read = (SELECT SUM(n) FROM UNNEST(update_user_page.read_state) AS n WHERE n > 0),
			last_modified = utc_now()
		WHERE id = user_page_id
	RETURNING *;
$func$;