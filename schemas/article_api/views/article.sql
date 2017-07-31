CREATE VIEW article_api.article AS
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
		pages.url,
		coalesce(authors.names, '{}') AS authors,
		coalesce(tags.names, '{}') AS tags,
		pages.word_count,
		pages.readable_word_count,
		pages.page_count,
		coalesce(comments.comment_count, 0) AS comment_count,
		comments.latest_comment_date
	FROM
		article
		JOIN (
			SELECT
				url,
				count(*) OVER article AS page_count,
				sum(word_count) OVER article AS word_count,
				sum(readable_word_count) OVER article AS readable_word_count,
				article_id,
				number = min(number) OVER article AS is_first_page
			FROM page
			WINDOW article AS (PARTITION BY article_id)
		) AS pages ON pages.is_first_page AND pages.article_id = article.id
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
				count(*) AS comment_count,
				max(date_created) AS latest_comment_date,
				article_id
			FROM comment
			GROUP BY article_id
		) AS comments ON comments.article_id = article.id
	GROUP BY
		article.id,
		source.id,
		pages.url,
		pages.word_count,
		pages.readable_word_count,
		pages.page_count,
		authors.names,
		tags.names,
		comments.comment_count,
		comments.latest_comment_date;