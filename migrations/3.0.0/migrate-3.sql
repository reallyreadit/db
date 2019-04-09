-- create indexes on cached columns
CREATE INDEX ON article (comment_count DESC);
CREATE INDEX ON article (read_count DESC);
CREATE INDEX ON article (average_rating_score DESC);