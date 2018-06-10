CREATE FUNCTION is_time_zone_name(
	name text
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $func$
BEGIN
	PERFORM now() AT TIME ZONE is_time_zone_name.name;
	RETURN TRUE;
EXCEPTION
	WHEN invalid_parameter_value THEN
		RETURN FALSE;
END;
$func$;