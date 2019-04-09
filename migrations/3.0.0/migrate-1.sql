-- add new cached columns with indexes
ALTER TABLE article
ADD COLUMN comment_count int NOT NULL DEFAULT 0;

ALTER TABLE article
ADD COLUMN read_count int NOT NULL DEFAULT 0;

ALTER TABLE article
ADD COLUMN average_rating_score numeric;