CREATE TABLE id_migration.source AS (
	SELECT
		source.id AS old_id,
		row_number() OVER (ORDER BY min(user_page.date_created)) AS new_id
	FROM
		source
		LEFT JOIN article ON article.source_id = source.id
		LEFT JOIN page ON page.article_id = article.id
		LEFT JOIN user_page ON user_page.page_id = page.id
	GROUP BY
		source.id
);