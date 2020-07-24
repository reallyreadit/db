CREATE OR REPLACE FUNCTION article_api.find_page(
    url text
)
RETURNS SETOF core.page
LANGUAGE sql
STABLE
AS $$
	SELECT
        page.*
    FROM
        core.page
    WHERE
        page.url LIKE ('%' || trim(LEADING 'https' FROM find_page.url))
$$;