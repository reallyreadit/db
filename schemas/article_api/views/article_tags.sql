CREATE VIEW article_api.article_tags AS
SELECT
	array_agg(tag.name) AS names,
	article_tag.article_id
FROM
	tag
	JOIN article_tag ON article_tag.tag_id = tag.id
GROUP BY article_id;