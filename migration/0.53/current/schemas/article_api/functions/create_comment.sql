CREATE FUNCTION article_api.create_comment(
  text text,
  article_id bigint,
  parent_comment_id bigint,
  user_account_id bigint
) RETURNS SETOF article_api.user_comment
LANGUAGE plpgsql AS $func$
DECLARE
  comment_id bigint;
BEGIN
	INSERT INTO comment
        (text, article_id, parent_comment_id, user_account_id) VALUES
        (text, article_id, parent_comment_id, user_account_id) RETURNING id INTO comment_id;
    RETURN QUERY SELECT * FROM article_api.user_comment WHERE id = comment_id;
END;
$func$;