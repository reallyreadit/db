-- add new columns to article table
ALTER TABLE article ADD COLUMN aotd_timestamp timestamp;
ALTER TABLE article ADD COLUMN score int NOT NULL DEFAULT 0;
-- drop everything necessary to refactor article_api views
DROP FUNCTION article_api.find_article(
	slug text
);
DROP FUNCTION article_api.find_user_article(
	slug text,
	user_account_id uuid
);
DROP FUNCTION article_api.get_user_article(
	article_id uuid,
	user_account_id uuid
);
DROP FUNCTION article_api.list_hot_topics(
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_starred_articles(
	user_account_id uuid,
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_user_article_history(
	user_account_id uuid,
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_user_hot_topics(
	user_account_id uuid,
	page_number int,
	page_size int
);
DROP TYPE article_api.article_page_result;
DROP TYPE article_api.user_article_page_result;
DROP VIEW article_api.user_article;
DROP VIEW article_api.article;
-- refactor article_api views
CREATE VIEW article_api.article_pages AS (
	SELECT
		array_agg(url ORDER BY number) AS urls,
		count(*) AS count,
		sum(word_count) AS word_count,
		sum(readable_word_count) AS readable_word_count,
		article_id
	FROM page
	GROUP BY article_id
);
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
CREATE VIEW article_api.user_article_read AS (
	SELECT
		words_read,
		date_created,
		last_modified,
		percent_complete,
		user_account_id,
		article_id
	FROM article_api.user_article_progress
	WHERE is_read
);
CREATE VIEW article_api.article_score AS (
	SELECT
		article.id AS article_id,
		coalesce(comments.score, 0) + coalesce(reads.score, 0) AS score
	FROM
		article
		LEFT JOIN (
			SELECT
				sum(
					CASE
						WHEN age < '36 hours' THEN 200
						WHEN age < '72 hours' THEN 150
						WHEN age < '1 week' THEN 100
						WHEN age < '2 weeks' THEN 50
						WHEN age < '1 month' THEN 5
						ELSE 1
					END
				) AS score,
				article_id
			FROM (
				SELECT
					article_id,
					utc_now() - date_created AS age
				FROM comment
			) AS comment
			GROUP BY article_id
		) AS comments ON comments.article_id = article.id
		LEFT JOIN (
			SELECT
				sum(
					CASE
						WHEN age < '36 hours' THEN 175
						WHEN age < '72 hours' THEN 125
						WHEN age < '1 week' THEN 75
						WHEN age < '2 weeks' THEN 25
						WHEN age < '1 month' THEN 5
						ELSE 1
					END
				) AS score,
				article_id
			FROM (
				SELECT
					article_id,
					utc_now() - last_modified AS age
				FROM article_api.user_article_read
			) AS read
			GROUP BY article_id
		) AS reads ON reads.article_id = article.id
	GROUP BY
		article.id,
		comments.score,
		reads.score
);
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
		star.date_starred
);
CREATE TYPE article_api.article_page_result AS (
	id uuid,
	title text,
	slug text,
	source_id uuid,
	source text,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	aotd_timestamp timestamp,
	score int,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	readable_word_count bigint,
	page_count bigint,
	comment_count bigint,
	latest_comment_date timestamp,
	read_count bigint,
	latest_read_date timestamp,
	total_count	bigint
);
CREATE TYPE article_api.user_article_page_result AS (
	id uuid,
	title text,
	slug text,
	source_id uuid,
	source text,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	aotd_timestamp timestamp,
	score int,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	readable_word_count bigint,
	page_count bigint,
	comment_count bigint,
	latest_comment_date timestamp,
	read_count bigint,
	latest_read_date timestamp,
	user_account_id uuid,
	words_read bigint,
	date_created timestamp,
	last_modified timestamp,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp,
	total_count	bigint
);
-- recreate dependants
CREATE FUNCTION article_api.find_article(
	slug text
) RETURNS SETOF article_api.article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date
	FROM article_api.article
	WHERE slug = find_article.slug;
$func$;
CREATE FUNCTION article_api.find_user_article(
	slug text,
	user_account_id uuid
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred
	FROM article_api.user_article
	WHERE
		slug = find_user_article.slug AND
		user_account_id = find_user_article.user_account_id;
$func$;
CREATE FUNCTION article_api.get_user_article(
	article_id uuid,
	user_account_id uuid
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred
	FROM article_api.user_article
	WHERE
		id = article_id AND
		user_account_id = get_user_article.user_account_id;
$func$;
CREATE FUNCTION article_api.list_hot_topics(
	page_number int,
	page_size int
) RETURNS SETOF article_api.article_page_result
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		count(*) OVER() AS total_count
	FROM article_api.article
	WHERE
		(comment_count > 0 OR read_count > 1) AND
		(aotd_timestamp IS NULL OR aotd_timestamp != (SELECT max(aotd_timestamp) FROM article))
	ORDER BY score DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;
CREATE FUNCTION article_api.list_starred_articles(
	user_account_id uuid,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_starred_articles.user_account_id AND
		date_starred IS NOT NULL
	ORDER BY date_starred DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;
CREATE FUNCTION article_api.list_user_article_history(
	user_account_id uuid,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_user_article_history.user_account_id AND
		(date_starred IS NOT NULL OR date_created IS NOT NULL)
	ORDER BY greatest(date_starred, date_created) DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;
CREATE FUNCTION article_api.list_user_hot_topics(
	user_account_id uuid,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_article_page_result
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_user_hot_topics.user_account_id AND
		(comment_count > 0 OR read_count > 1) AND
		(aotd_timestamp IS NULL OR aotd_timestamp != (SELECT max(aotd_timestamp) FROM article))
	ORDER BY score DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;
-- create ranking functions
CREATE FUNCTION article_api.score_articles() RETURNS void
LANGUAGE SQL AS $func$
	UPDATE article
	SET score = article_score.score
	FROM article_api.article_score
	WHERE article_score.article_id = article.id;
$func$;
CREATE FUNCTION article_api.set_aotd() RETURNS void
LANGUAGE SQL AS $func$
	UPDATE article
	SET aotd_timestamp = utc_now()
	WHERE id = (
		SELECT id
		FROM article
		WHERE aotd_timestamp IS NULL
		ORDER BY score DESC
		LIMIT 1
	);
$func$;
CREATE FUNCTION article_api.get_aotd()
RETURNS SETOF article_api.article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date
	FROM article_api.article
	WHERE id = (
		SELECT id
		FROM core.article
		ORDER BY core.article.aotd_timestamp DESC NULLS LAST
		LIMIT 1
	);
$func$;
CREATE FUNCTION article_api.get_user_aotd(
	user_account_id uuid
) RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT
		id,
		title,
		slug,
		source_id,
		source,
		date_published,
		date_modified,
		section,
		description,
		aotd_timestamp,
		score,
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		read_count,
		latest_read_date,
		user_account_id,
		words_read,
		date_created,
		last_modified,
		percent_complete,
		is_read,
		date_starred
	FROM article_api.user_article
	WHERE
		id = (
			SELECT id
			FROM core.article
			ORDER BY core.article.aotd_timestamp DESC NULLS LAST
			LIMIT 1
		) AND
		user_account_id = get_user_aotd.user_account_id;
$func$;