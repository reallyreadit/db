CREATE TABLE id_migration.author AS (
	SELECT
		author.id AS old_id,
		row_number() OVER (ORDER BY min(user_page.date_created)) AS new_id
	FROM
		author
		LEFT JOIN article_author ON article_author.author_id = author.id
		LEFT JOIN page ON page.article_id = article_author.article_id
		LEFT JOIN user_page ON user_page.page_id = page.id
	GROUP BY
		author.id
);