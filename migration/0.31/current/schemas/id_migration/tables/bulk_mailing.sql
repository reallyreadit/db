CREATE TABLE id_migration.bulk_mailing AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY date_sent) AS new_id
	FROM
		bulk_mailing
);