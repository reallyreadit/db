CREATE FUNCTION article_api.get_page(page_id bigint) RETURNS SETOF page
LANGUAGE SQL AS $func$
	SELECT * FROM page WHERE id = page_id;
$func$;