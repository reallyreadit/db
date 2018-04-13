CREATE FUNCTION article_api.get_comment(comment_id bigint) RETURNS SETOF article_api.user_comment
LANGUAGE SQL AS $func$
	SELECT * FROM article_api.user_comment WHERE id = comment_id;
$func$;