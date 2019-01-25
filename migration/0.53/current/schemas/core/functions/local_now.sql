CREATE FUNCTION local_now(time_zone_name text)
RETURNS timestamp
LANGUAGE SQL
STABLE
AS $func$
	SELECT now() AT TIME ZONE time_zone_name;
$func$;