-- add date_completed column to user_page
ALTER TABLE user_page ADD COLUMN date_completed timestamp;
-- set date_completed value for pages >= 90%
UPDATE user_page
SET date_completed = user_page.last_modified
FROM page
WHERE (
	user_page.page_id = page.id AND
	((user_page.words_read :: double precision / page.readable_word_count) * 100) >= 90
);
-- create challenge_api schema
CREATE SCHEMA challenge_api;
-- add time_zone_id column to user_account
ALTER TABLE user_account ADD COLUMN time_zone_id bigint REFERENCES time_zone (id);
-- replace utc_now
CREATE OR REPLACE FUNCTION utc_now()
RETURNS timestamp
LANGUAGE SQL
STABLE
AS $func$
	SELECT local_now('UTC');
$func$;
-- create index on page (article_id)
CREATE INDEX ON page (article_id);