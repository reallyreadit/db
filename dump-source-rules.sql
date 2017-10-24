SELECT hostname, path, priority, action FROM source_rule
	ORDER BY array_to_string(
		ARRAY(SELECT (string_to_array(hostname, '.'))[i] FROM generate_subscripts(string_to_array(hostname, '.'), 1, TRUE) s(i)), '.'
	), priority;