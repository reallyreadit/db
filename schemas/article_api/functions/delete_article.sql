CREATE FUNCTION article_api.delete_article(id uuid) RETURNS void
LANGUAGE plpgsql AS $func$
BEGIN
	DELETE FROM user_page WHERE page_id IN (SELECT page.id FROM page WHERE article_id = delete_article.id);
	DELETE FROM page WHERE article_id = delete_article.id;
	DELETE FROM article_author WHERE article_id = delete_article.id;
	DELETE FROM article_tag WHERE article_id = delete_article.id;
	DELETE FROM article WHERE article.id = delete_article.id;
END;
$func$