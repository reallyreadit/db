CREATE OR REPLACE VIEW article_api.user_article_rating AS
SELECT
	rating.article_id,
   rating.user_account_id,
	rating.score
FROM
	rating
	LEFT JOIN rating AS more_recent_rating
		ON (
			rating.article_id = more_recent_rating.article_id AND
			rating.user_account_id = more_recent_rating.user_account_id AND
			rating.timestamp < more_recent_rating.timestamp
		)
WHERE
	more_recent_rating.id IS NULL;