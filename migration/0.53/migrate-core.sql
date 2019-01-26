-- move readable_word_count from page to user_page
ALTER TABLE user_page
ADD COLUMN readable_word_count int;

UPDATE user_page
SET
	readable_word_count = (
		SELECT sum(abs(n)) FROM unnest(read_state) AS n
	);

ALTER TABLE user_page
ALTER COLUMN readable_word_count SET NOT NULL;

-- drop challenge_api schema
DROP SCHEMA challenge_api;