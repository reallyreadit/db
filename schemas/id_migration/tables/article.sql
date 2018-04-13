CREATE TABLE id_migration.article AS (
	SELECT
		article.id AS old_id,
		row_number() OVER (ORDER BY min(user_page.date_created)) AS new_id
	FROM
		article
		LEFT JOIN page ON page.article_id = article.id
		LEFT JOIN user_page ON user_page.page_id = page.id
	GROUP BY
		article.id
);