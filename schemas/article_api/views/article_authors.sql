CREATE VIEW article_api.article_authors AS
SELECT
	array_agg(author.name) AS names,
	article_author.article_id
FROM
	author
	JOIN article_author ON article_author.author_id = author.id
GROUP BY article_id;