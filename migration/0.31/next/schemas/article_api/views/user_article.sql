CREATE VIEW article_api.user_article AS (
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
		article.aotd_timestamp,
		article.score,
		article.url,
		article.authors,
		article.tags,
		article.word_count,
		article.readable_word_count,
		article.page_count,
		article.comment_count,
		article.latest_comment_date,
		article.read_count,
		article.latest_read_date,
		user_account.id AS user_account_id,
		coalesce(user_article_progress.words_read, 0) AS words_read,
		user_article_progress.date_created,
		user_article_progress.last_modified,
		coalesce(user_article_progress.percent_complete, 0) AS percent_complete,
		coalesce(user_article_progress.is_read, FALSE) AS is_read,
		user_article_progress.date_completed,
		star.date_starred
	FROM
		article_api.article
		CROSS JOIN user_account
		LEFT JOIN article_api.user_article_progress ON
			user_article_progress.user_account_id = user_account.id AND
			user_article_progress.article_id = article.id
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
		article.aotd_timestamp,
		article.score,
		article.url,
		article.authors,
		article.tags,
		article.word_count,
		article.readable_word_count,
		article.page_count,
		article.comment_count,
		article.latest_comment_date,
		article.read_count,
		article.latest_read_date,
		user_account.id,
		user_article_progress.words_read,
		user_article_progress.date_created,
		user_article_progress.last_modified,
		user_article_progress.percent_complete,
		user_article_progress.is_read,
		user_article_progress.date_completed,
		star.date_starred
);