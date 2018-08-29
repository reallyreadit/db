SELECT * FROM article WHERE title = 'Kansas Primary Election Results';

SELECT * FROM page WHERE article_id = 130021;

SELECT *
FROM article_author
WHERE article_id = 130021;

SELECT *
FROM article_tag
WHERE article_id = 130021;

SELECT *
FROM star
WHERE article_id = 130021;

SELECT *
FROM user_page
WHERE page_id IN (
	SELECT id
	FROM page
	WHERE article_id = 130021
);

SELECT *
FROM comment
WHERE article_id = 130021;

SELECT *
FROM email_share
WHERE article_id = 130021;