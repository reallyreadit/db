CREATE FUNCTION article_api.update_read_progress(
	user_page_id bigint,
	read_state int[]
)
RETURNS user_page
LANGUAGE plpgsql
AS $func$
<<locals>>
DECLARE
	words_read CONSTANT int NOT NULL := (SELECT sum(n) FROM unnest(read_state) AS n WHERE n > 0);
	page_id bigint;
	is_complete boolean;
	updated_user_page user_page;
BEGIN
	-- get the page_id and cache the completion state before updating the progress
	SELECT
		user_page.page_id,
		user_page.date_completed IS NOT NULL
	INTO
		locals.page_id,
		locals.is_complete
	FROM user_page
	WHERE user_page.id = update_read_progress.user_page_id;
	-- update the progress
	UPDATE user_page
	SET
		read_state = update_read_progress.read_state,
		words_read = locals.words_read,
		last_modified = utc_now()
	WHERE user_page.id = update_read_progress.user_page_id
	RETURNING * INTO locals.updated_user_page;
	-- check if this update completed the page
	IF
		NOT is_complete AND
		(
		   SELECT article_api.get_percent_complete(
		      locals.updated_user_page.readable_word_count,
		      locals.words_read
		   ) >= 90
		)
	THEN
		-- set date_completed
		UPDATE user_page
		SET date_completed = user_page.last_modified
		WHERE user_page.id = update_read_progress.user_page_id
		RETURNING * INTO locals.updated_user_page;
	END IF;
	-- return
	RETURN locals.updated_user_page;
END;
$func$;