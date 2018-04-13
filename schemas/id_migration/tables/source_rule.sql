CREATE TABLE id_migration.source_rule AS (
	SELECT
		id AS old_id,
		row_number() OVER (ORDER BY array_to_string(
			ARRAY(SELECT (string_to_array(hostname, '.'))[i] FROM generate_subscripts(string_to_array(hostname, '.'), 1, TRUE) s(i)), '.'
		), priority) AS new_id
	FROM
		source_rule
);