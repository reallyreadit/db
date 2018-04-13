CREATE TABLE id_migration.email_bounce AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY date_received) AS new_id
	FROM
		email_bounce
);