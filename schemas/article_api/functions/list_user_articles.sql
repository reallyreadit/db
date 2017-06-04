CREATE FUNCTION article_api.list_user_articles(
	user_account_id uuid DEFAULT NULL,
	min_comment_count int DEFAULT 0,
	min_percent_complete int DEFAULT 0,
	sort text DEFAULT 'DateCreated'
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	WITH user_article AS (
		SELECT
			article.id,
			article.title,
			article.slug,
			article.source_id,
			(SELECT name FROM source WHERE id = article.source_id) AS source,
			article.date_published,
			article.date_modified,
			article.section,
			article.description,
			(SELECT url FROM page WHERE article_id = article.id ORDER BY number LIMIT 1),
			array(
				SELECT name FROM article_author
					JOIN author ON article_author.author_id = author.id
					WHERE article_id = article.id
			),
			array(
				SELECT name FROM article_tag
					JOIN tag ON article_tag.tag_id = tag.id
					WHERE article_id = article.id
			),
			(SELECT SUM(page.word_count)) as word_count,
			(SELECT SUM(page.readable_word_count)) as readable_word_count,
			COUNT (*) AS page_count,
			(SELECT (COALESCE(SUM(current_user_page.words_read), 0) * 100) / SUM((SELECT
				CASE
					WHEN page.readable_word_count > 0
					THEN page.readable_word_count
					ELSE (SELECT AVG(readable_word_count) FROM page WHERE article_id = article.id AND readable_word_count > 0)
			END))) AS percent_complete,
			(SELECT COUNT(*) FROM comment WHERE article_id = article.id) AS comment_count,
			MIN(current_user_page.date_created) as date_created
		FROM article
			JOIN page ON page.article_id = article.id
			LEFT JOIN (
				SELECT page_id, words_read, date_created FROM user_page WHERE user_account_id = list_user_articles.user_account_id
			) AS current_user_page ON current_user_page.page_id = page.id
		GROUP BY article.id
	) SELECT * FROM user_article
		WHERE comment_count >= min_comment_count AND percent_complete >= min_percent_complete
		ORDER BY CASE sort
			WHEN 'DateCreated' THEN date_created
			WHEN 'LastComment' THEN (SELECT MAX(date_created) FROM comment WHERE article_id = user_article.id)
			END
		DESC;
$func$;