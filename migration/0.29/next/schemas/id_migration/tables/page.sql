CREATE TABLE id_migration.page AS (
	SELECT
		page.id AS old_id,
		row_number() OVER (ORDER BY min(user_page.date_created)) AS new_id
	FROM
		page
		LEFT JOIN user_page ON user_page.page_id = page.id
	GROUP BY
		page.id
);