CREATE TABLE id_migration.tag AS (
	SELECT
		tag.id AS old_id,
		row_number() OVER (ORDER BY min(user_page.date_created)) AS new_id
	FROM
		tag
		LEFT JOIN article_tag ON article_tag.tag_id = tag.id
		LEFT JOIN page ON page.article_id = article_tag.article_id
		LEFT JOIN user_page ON user_page.page_id = page.id
	GROUP BY
		tag.id
);