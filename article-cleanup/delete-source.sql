SELECT * FROM source WHERE id = 1757;
SELECT * FROM article WHERE source_id = 1757;
SELECT * FROM page WHERE article_id IN (SELECT id FROM article WHERE source_id = 1757);

SELECT *
FROM article_author
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM article_tag
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM star
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM user_page
WHERE page_id IN (
	SELECT id
	FROM page
	WHERE article_id IN (
		SELECT id
		FROM article
		WHERE source_id = 1757
	)
);

SELECT *
FROM comment
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);

SELECT *
FROM email_share
WHERE article_id IN (
	SELECT id
	FROM article
	WHERE source_id = 1757
);