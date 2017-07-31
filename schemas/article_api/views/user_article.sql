CREATE VIEW article_api.user_article AS
	SELECT
		article.id,
		article.title,
		article.slug,
		article.source_id,
		article.source,
		article.date_published,
		article.date_modified,
		article.section,
		article.description,
		article.url,
		article.authors,
		article.tags,
		article.word_count,
		article.readable_word_count,
		article.page_count,
		article.comment_count,
		article.latest_comment_date,
		user_account.id AS user_account_id,
		coalesce(user_pages.words_read, 0) AS words_read,
		user_pages.date_created,
		star.date_starred
	FROM
		article_api.article
		CROSS JOIN user_account
		LEFT JOIN (
			SELECT
				sum(user_page.words_read) AS words_read,
				min(user_page.date_created) AS date_created,
				user_page.user_account_id,
				page.article_id
			FROM
				user_page
				JOIN page ON page.id = user_page.page_id
			GROUP BY
				user_page.user_account_id,
				page.article_id
		) AS user_pages ON
			user_pages.user_account_id = user_account.id AND
			user_pages.article_id = article.id
		LEFT JOIN star ON
			star.user_account_id = user_account.id AND
			star.article_id = article.id
	GROUP BY
		article.id,
		article.title,
		article.slug,
		article.source_id,
		article.source,
		article.date_published,
		article.date_modified,
		article.section,
		article.description,
		article.url,
		article.authors,
		article.tags,
		article.word_count,
		article.readable_word_count,
		article.page_count,
		article.comment_count,
		article.latest_comment_date,
		user_account.id,
		user_pages.words_read,
		user_pages.date_created,
		star.date_starred;