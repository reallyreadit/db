CREATE FUNCTION article_api.create_source(name text, url text, hostname text, slug text) RETURNS source
LANGUAGE SQL AS $func$
	INSERT INTO source (name, url, hostname, slug) VALUES (name, url, hostname, slug) RETURNING *;
$func$;