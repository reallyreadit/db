-- fix article_api.create_page
DROP FUNCTION article_api.create_page(
	article_id bigint,
	number integer,
	word_count integer,
	readable_word_count integer,
	url text
);
CREATE FUNCTION article_api.create_page(
	article_id bigint,
	number integer,
	word_count integer,
	readable_word_count integer,
	url text
)
RETURNS SETOF core.page
LANGUAGE plpgsql
AS $$
BEGIN
    -- set the cached word_count on article
    UPDATE article
    SET word_count = create_page.word_count
    WHERE id = create_page.article_id;
    -- create the new page and return it
	RETURN QUERY
   INSERT INTO page (article_id, number, word_count, readable_word_count, url)
	VALUES (article_id, number, word_count, readable_word_count, url)
	RETURNING *;
END;
$$;