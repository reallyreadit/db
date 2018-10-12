CREATE FUNCTION article_api.get_source_rules() RETURNS SETOF source_rule
LANGUAGE SQL AS $func$
	SELECT * FROM source_rule;
$func$;