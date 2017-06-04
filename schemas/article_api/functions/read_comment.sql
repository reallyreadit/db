CREATE FUNCTION article_api.read_comment(comment_id uuid) RETURNS VOID
LANGUAGE SQL AS $func$
	UPDATE comment SET date_read = utc_now() WHERE id = comment_id AND date_read IS NULL;
$func$;