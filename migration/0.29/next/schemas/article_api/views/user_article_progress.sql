CREATE VIEW article_api.user_article_progress AS (
	WITH user_article_pages AS (
		SELECT
			sum(user_page.words_read) AS words_read,
			min(user_page.date_created) AS date_created,
			max(user_page.last_modified) AS last_modified,
			user_page.user_account_id,
			page.article_id
		FROM
			user_page
			JOIN page ON page.id = user_page.page_id
		GROUP BY
			user_page.user_account_id,
			page.article_id
	)
	SELECT
		words_read,
		date_created,
		last_modified,
		percent_complete,
		percent_complete >= 90 AS is_read,
		user_account_id,
		article_id
	FROM (
		SELECT
			user_article_pages.words_read,
			user_article_pages.date_created,
			user_article_pages.last_modified,
			least(
				(user_article_pages.words_read::double precision / article_pages.readable_word_count) * 100,
				100
			) AS percent_complete,
			user_article_pages.user_account_id,
			user_article_pages.article_id
		FROM
			user_article_pages
			JOIN article_api.article_pages ON article_pages.article_id = user_article_pages.article_id
	) AS user_article_progress
	GROUP BY
		words_read,
		date_created,
		last_modified,
		percent_complete,
		user_account_id,
		article_id
);