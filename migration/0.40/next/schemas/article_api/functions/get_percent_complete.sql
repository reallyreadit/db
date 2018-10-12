CREATE FUNCTION article_api.get_percent_complete(
	readable_word_count numeric,
	words_read numeric
)
RETURNS double precision
LANGUAGE SQL
IMMUTABLE
AS $func$
	SELECT greatest(least((words_read::double precision / readable_word_count) * 100, 100), 0);
$func$;