-- remove "Unknown Author" from My Impact chart for product screenshots
DELETE FROM
	core.user_article AS user_article_to_delete
USING
	core.user_article
	LEFT JOIN
		core.article_author ON
			user_article.article_id = article_author.article_id
WHERE
	user_article_to_delete.id = user_article.id AND
	article_author.author_id IS NULL;