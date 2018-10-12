CREATE FUNCTION article_api.find_source(source_hostname text) RETURNS SETOF source
LANGUAGE SQL AS $func$
	SELECT * FROM source WHERE hostname = source_hostname;
$func$;