CREATE TABLE id_migration.email_confirmation AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY date_created) AS new_id
	FROM
		email_confirmation
);