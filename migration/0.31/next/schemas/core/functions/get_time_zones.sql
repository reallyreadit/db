CREATE FUNCTION get_time_zones()
RETURNS SETOF time_zone
LANGUAGE SQL
STABLE
AS $func$
	SELECT *
	FROM time_zone;
$func$;