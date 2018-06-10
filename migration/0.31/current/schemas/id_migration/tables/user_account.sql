CREATE TABLE id_migration.user_account AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY date_created) AS new_id
	FROM
		user_account
);