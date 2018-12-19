DROP INDEX article_score_idx;

ALTER TABLE article DROP COLUMN score;

ALTER TABLE article ADD COLUMN hot_score int NOT NULL DEFAULT 0;
ALTER TABLE article ADD COLUMN top_score int NOT NULL DEFAULT 0;

CREATE INDEX article_hot_score_idx ON article (hot_score DESC);
CREATE INDEX article_top_score_idx ON article (top_score DESC);