CREATE VIEW article_api.article AS (
	SELECT
		article.id,
		article.title,
		article.slug,
		article.source_id,
		source.name AS source,
		article.date_published,
		article.date_modified,
		article.section,
		article.description,
		article.aotd_timestamp,
		article.score,
		article_pages.urls[1] AS url,
		coalesce(authors.names, '{}') AS authors,
		coalesce(tags.names, '{}') AS tags,
		article_pages.word_count,
		article_pages.readable_word_count,
		article_pages.count AS page_count,
		coalesce(comments.count, 0) AS comment_count,
		comments.latest_date AS latest_comment_date,
		coalesce(reads.count, 0) AS read_count,
		reads.latest_date AS latest_read_date
	FROM
		article
		JOIN article_api.article_pages ON article_pages.article_id = article.id
		JOIN source ON source.id = article.source_id
		LEFT JOIN (
			SELECT
				array_agg(author.name) AS names,
				article_author.article_id
			FROM
				author
				JOIN article_author ON article_author.author_id = author.id
			GROUP BY article_id
		) AS authors ON authors.article_id = article.id
		LEFT JOIN (
			SELECT
				array_agg(tag.name) AS names,
				article_tag.article_id
			FROM
				tag
				JOIN article_tag ON article_tag.tag_id = tag.id
			GROUP BY article_id
		) AS tags ON tags.article_id = article.id
		LEFT JOIN (
			SELECT
				count(*) AS count,
				max(date_created) AS latest_date,
				article_id
			FROM comment
			GROUP BY article_id
		) AS comments ON comments.article_id = article.id
		LEFT JOIN (
			SELECT
				count(*) AS count,
				max(last_modified) AS latest_date,
				article_id
			FROM article_api.user_article_read
			GROUP BY article_id
		) AS reads ON reads.article_id = article.id
	GROUP BY
		article.id,
		source.id,
		article_pages.urls,
		article_pages.word_count,
		article_pages.readable_word_count,
		article_pages.count,
		authors.names,
		tags.names,
		comments.count,
		comments.latest_date,
		reads.count,
		reads.latest_date
);