CREATE DOMAIN rating_score
AS int
CHECK (
    VALUE >= 1 AND
    VALUE <= 10
);