CREATE FUNCTION utc_now()
RETURNS timestamp
LANGUAGE SQL
STABLE
AS $func$
	SELECT local_now('UTC');
$func$;