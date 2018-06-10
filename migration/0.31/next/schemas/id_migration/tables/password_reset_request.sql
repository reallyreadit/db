CREATE TABLE id_migration.password_reset_request AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY date_created) AS new_id
	FROM
		password_reset_request
);