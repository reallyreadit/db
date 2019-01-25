CREATE VIEW article_api.user_comment AS SELECT
	comment.id,
	comment.date_created,
	comment.text,
	comment.article_id,
	article.title as article_title,
	article.slug as article_slug,
	comment.user_account_id,
	user_account.name AS user_account,
	comment.parent_comment_id,
	comment.date_read
	FROM comment
	JOIN article ON comment.article_id = article.id
	JOIN user_account ON comment.user_account_id = user_account.id;