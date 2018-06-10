CREATE VIEW article_api.user_article_read AS (
	SELECT
		words_read,
		date_created,
		last_modified,
		percent_complete,
		user_account_id,
		article_id
	FROM article_api.user_article_progress
	WHERE is_read
);