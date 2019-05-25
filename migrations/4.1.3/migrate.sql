CREATE OR REPLACE FUNCTION article_api.get_percent_complete(readable_word_count numeric, words_read numeric) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $$
	SELECT greatest(
	   least(
	      (coalesce(words_read, 0)::double precision / greatest(coalesce(readable_word_count, 0), 1)) * 100,
	      100
	   ),
	   0
	);
$$;