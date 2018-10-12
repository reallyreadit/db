CREATE FUNCTION generate_local_to_utc_date_series(
	start date,
	stop date,
	day_step_count int,
	time_zone_name text
)
RETURNS TABLE (
	local_day date,
	utc_range tsrange
)
LANGUAGE SQL
IMMUTABLE
AS $func$
	WITH day_pair AS (
		SELECT
			cast(local_day AS date) AS local_day,
			make_timestamptz(
				extract(year FROM local_day)::int,
				extract(month FROM local_day)::int,
				extract(day FROM local_day)::int,
				extract(hour FROM local_day)::int,
				extract(minute FROM local_day)::int,
				extract(second FROM local_day)::int,
				generate_local_to_utc_date_series.time_zone_name
			) AT TIME ZONE 'UTC' AS utc_day
		FROM
			generate_series(
				start,
				stop,
				make_interval(
					days => generate_local_to_utc_date_series.day_step_count
				)
			) AS local_day
	)
	SELECT
		local_day,
		tsrange(
			utc_day,
			utc_day + '1 day'::interval
		)
	FROM day_pair;
$func$;