CREATE FUNCTION article_api.list_comments(article_id uuid) RETURNS SETOF article_api.user_comment
LANGUAGE SQL AS $func$
	SELECT * FROM article_api.user_comment WHERE article_id = list_comments.article_id;
$func$;