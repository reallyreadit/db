CREATE FUNCTION article_api.find_page(url text) RETURNS SETOF page
LANGUAGE SQL AS $func$
	SELECT * FROM page WHERE url = find_page.url;
$func$