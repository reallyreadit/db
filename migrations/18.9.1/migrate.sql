/*
	This migration adds support for automating website traffic analytics.
*/

ALTER TABLE
	core.website_traffic_weekly_total
ADD COLUMN
	last_updated timestamp;

UPDATE
	core.website_traffic_weekly_total AS total
SET
	last_updated = total.week + '1 week 2 hours'::interval
WHERE
	total.last_updated IS NULL;

ALTER TABLE
	core.website_traffic_weekly_total
ALTER COLUMN
	last_updated SET NOT NULL;

CREATE FUNCTION
	analytics.create_or_update_website_traffic_weekly_total(
		week timestamp,
		unique_visit_count int
	)
RETURNS
	SETOF core.website_traffic_weekly_total
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.website_traffic_weekly_total (
			week,
			unique_visit_count,
			last_updated
		)
	VALUES (
		create_or_update_website_traffic_weekly_total.week,
		create_or_update_website_traffic_weekly_total.unique_visit_count,
		core.utc_now()
	)
	ON CONFLICT (
		week
	)
	DO UPDATE SET
		unique_visit_count = create_or_update_website_traffic_weekly_total.unique_visit_count,
		last_updated = core.utc_now()
	RETURNING
		*;
$$;