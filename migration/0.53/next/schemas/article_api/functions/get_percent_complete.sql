CREATE FUNCTION article_api.get_percent_complete(
	readable_word_count numeric,
	words_read numeric
)
RETURNS double precision
LANGUAGE SQL
IMMUTABLE
AS $func$
	SELECT greatest(
	   least(
	      (coalesce(words_read, 0)::double precision / coalesce(readable_word_count, 1)) * 100,
	      100
	   ),
	   0
	);
$func$;