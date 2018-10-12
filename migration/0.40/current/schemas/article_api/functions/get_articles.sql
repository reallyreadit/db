CREATE FUNCTION article_api.get_articles(
	VARIADIC article_ids bigint[]
)
RETURNS TABLE (
	id bigint,
	title text,
	slug text,
	source text,
	date_published timestamp,
	section text,
	description text,
	aotd_timestamp timestamp,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	comment_count bigint,
	read_count bigint
)
LANGUAGE SQL AS $func$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name AS source,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1] AS url,
		coalesce(authors.names, '{}') AS authors,
		coalesce(tags.names, '{}') AS tags,
		article_pages.word_count,
		coalesce(comments.count, 0) AS comment_count,
		coalesce(reads.count, 0) AS read_count
	FROM
		article
		JOIN article_api.article_pages ON (
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (article_ids)
		)
		JOIN source ON source.id = article.source_id
		LEFT JOIN (
			SELECT
				array_agg(author.name) AS names,
				article_author.article_id
			FROM
				author
				JOIN article_author ON article_author.author_id = author.id
			GROUP BY article_id
		) AS authors ON (
			authors.article_id = article.id AND
			authors.article_id = ANY (article_ids)
		)
		LEFT JOIN (
			SELECT
				array_agg(tag.name) AS names,
				article_tag.article_id
			FROM
				tag
				JOIN article_tag ON article_tag.tag_id = tag.id
			GROUP BY article_id
		) AS tags ON (
			tags.article_id = article.id AND
			tags.article_id = ANY (article_ids)
		)
		LEFT JOIN (
			SELECT
				count(*) AS count,
				article_id
			FROM comment
			GROUP BY article_id
		) AS comments ON (
			comments.article_id = article.id AND
			comments.article_id = ANY (article_ids)
		)
		LEFT JOIN (
			SELECT
				count(*) AS count,
				user_article_pages.article_id
			FROM
				article_api.user_article_pages
				JOIN article_api.article_pages ON (
					article_pages.article_id = user_article_pages.article_id AND
					((user_article_pages.words_read::double precision / article_pages.readable_word_count) * 100) >= 90 AND
					article_pages.article_id = ANY (article_ids)
				)
			GROUP BY user_article_pages.article_id
		) AS reads ON (
			reads.article_id = article.id AND
			reads.article_id = ANY (article_ids)
		)
$func$;