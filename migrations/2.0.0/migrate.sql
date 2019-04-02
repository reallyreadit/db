-- drop existing article/user_article query functions
DROP FUNCTION article_api.find_article(
	slug text
);
DROP FUNCTION article_api.find_user_article(
	slug text,
	user_account_id bigint
);
DROP FUNCTION article_api.get_aotd();
DROP FUNCTION article_api.get_article(
	article_id bigint
);
DROP FUNCTION article_api.get_user_aotd(
	user_account_id bigint
);
DROP FUNCTION article_api.get_user_article(
	article_id bigint,
	user_account_id bigint
);
DROP FUNCTION article_api.list_community_reads(
	page_number int,
	page_size int,
	sort text
);
DROP FUNCTION article_api.list_starred_articles(
	user_account_id bigint,
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_user_article_history(
	user_account_id bigint,
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_user_community_reads(
	user_account_id bigint,
	page_number int,
	page_size int,
	sort text
);
DROP FUNCTION article_api.get_articles(
	VARIADIC article_ids bigint[]
);
DROP FUNCTION article_api.get_user_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
);
DROP TYPE article_api.article;
DROP TYPE article_api.article_page_result;
DROP TYPE article_api.user_article;
DROP TYPE article_api.user_article_page_result;

-- recreate article query functions
CREATE TYPE article_api.article AS (
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
	read_count bigint,
	date_created timestamp,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp,
	average_rating_score numeric,
	rating_score rating_score
);
CREATE TYPE article_api.article_page_result AS (
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
	read_count bigint,
	date_created timestamp,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp,
	average_rating_score numeric,
	rating_score rating_score,
	total_count	bigint
);
CREATE FUNCTION article_api.get_articles(
	user_account_id bigint,
	VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $$
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
		coalesce(article_authors.names, '{}') AS authors,
		coalesce(article_tags.names, '{}') AS tags,
		article_pages.word_count,
		coalesce(article_comment_count.count, 0) AS comment_count,
		coalesce(article_read_count.count, 0) AS read_count,
		user_article_pages.date_created,
		coalesce(
		   article_api.get_percent_complete(
		      user_article_pages.readable_word_count,
		      user_article_pages.words_read
		   ),
		   0
		) AS percent_complete,
		coalesce(
		   user_article_pages.date_completed IS NOT NULL,
		   FALSE
		) AS is_read,
		star.date_starred,
	   average_article_rating.score AS average_rating_score,
	   user_article_rating.score AS rating_score
	FROM
		article
		JOIN article_api.article_pages ON (
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (article_ids)
		)
		JOIN source ON source.id = article.source_id
		LEFT JOIN article_api.article_authors ON (
			article_authors.article_id = article.id AND
			article_authors.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_tags ON (
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_comment_count ON (
			article_comment_count.article_id = article.id AND
			article_comment_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.article_read_count ON (
			article_read_count.article_id = article.id AND
			article_read_count.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.average_article_rating ON (
			average_article_rating.article_id = article.id AND
			average_article_rating.article_id = ANY (article_ids)
		)
		LEFT JOIN article_api.user_article_pages ON (
		   user_article_pages.user_account_id = get_articles.user_account_id AND
			user_article_pages.article_id = article.id AND
			user_article_pages.article_id = ANY (article_ids)
		)
		LEFT JOIN star ON (
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		)
		LEFT JOIN article_api.user_article_rating ON (
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (article_ids)
		)
	ORDER BY array_position(article_ids, article.id)
$$;
CREATE FUNCTION article_api.find_article(
	slug text,
	user_account_id bigint
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		(
		   SELECT id
		   FROM article
		   WHERE slug = find_article.slug
		)
	);
$$;
CREATE FUNCTION article_api.get_aotd(
	user_account_id bigint
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT 1
		)
	);
$$;
CREATE FUNCTION article_api.get_article(
	article_id bigint,
	user_account_id bigint
)
RETURNS SETOF article_api.article
LANGUAGE SQL
STABLE
AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		article_id
	);
$$;
CREATE FUNCTION article_api.get_article_history(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
	WITH history_article AS (
		SELECT
			greatest(article.date_created, article.last_modified, star.date_starred) AS history_date,
			coalesce(article.article_id, star.article_id) AS article_id
		FROM
			(
				SELECT
					date_created,
					last_modified,
					article_id
				FROM article_api.user_article_pages
				WHERE user_account_id = get_article_history.user_account_id
			) AS article
			FULL JOIN (
				SELECT
					date_starred,
					article_id
				FROM star
				WHERE user_account_id = get_article_history.user_account_id
			) AS star ON star.article_id = article.article_id
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM history_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM history_article
			ORDER BY history_date DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION article_api.get_community_reads(
	user_account_id bigint,
	page_number int,
	page_size int,
	sort text
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
	SELECT
		articles.*,
		(SELECT count(*) FROM article_api.community_read) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article_api.community_read
			ORDER BY CASE sort
				WHEN 'hot' THEN hot_score
				WHEN 'top' THEN top_score
			END DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;
CREATE FUNCTION article_api.get_starred_articles(
	user_account_id bigint,
	page_number int,
	page_size int
)
RETURNS SETOF article_api.article_page_result
LANGUAGE SQL
STABLE
AS $$
	WITH starred_article AS (
		SELECT
			article_id,
			date_starred
		FROM star
		WHERE user_account_id = get_starred_articles.user_account_id
	)
	SELECT
		articles.*,
		(SELECT count(*) FROM starred_article) AS total_count
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT article_id
			FROM starred_article
			ORDER BY date_starred DESC
			OFFSET (page_number - 1) * page_size
			LIMIT page_size
		)
	) AS articles;
$$;