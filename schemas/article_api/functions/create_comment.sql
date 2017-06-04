CREATE FUNCTION article_api.create_comment(
  text text,
  article_id uuid,
  parent_comment_id uuid,
  user_account_id uuid
) RETURNS SETOF article_api.user_comment
LANGUAGE plpgsql AS $func$
DECLARE
  comment_id uuid;
BEGIN
	INSERT INTO comment
        (text, article_id, parent_comment_id, user_account_id) VALUES
        (text, article_id, parent_comment_id, user_account_id) RETURNING id INTO comment_id;
    RETURN QUERY SELECT * FROM article_api.user_comment WHERE id = comment_id;
END;
$func$;