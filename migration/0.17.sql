-- star objects
CREATE TABLE star (
	user_account_id	uuid		NOT NULL	REFERENCES user_account,
	article_id		uuid		NOT NULL	REFERENCES article,
	date_starred	timestamp	NOT NULL	DEFAULT utc_now(),
	PRIMARY KEY(user_account_id, article_id)
);
CREATE FUNCTION article_api.star_article(
	user_account_id uuid,
	article_id uuid
) RETURNS void
LANGUAGE SQL AS $func$
	INSERT INTO star (user_account_id, article_id) VALUES (user_account_id, article_id);
$func$;
CREATE FUNCTION article_api.unstar_article(
	user_account_id uuid,
	article_id uuid
) RETURNS void
LANGUAGE SQL AS $func$
	DELETE FROM star WHERE
		user_account_id = unstar_article.user_account_id AND
		article_id = unstar_article.article_id;
$func$;

-- reply list pagination
DROP FUNCTION article_api.list_replies(user_account_id uuid);
CREATE TYPE article_api.user_comment_page_result AS (
	id uuid,
	date_created timestamp,
	text text,
	article_id uuid,
	article_title text,
	article_slug text,
	user_account_id uuid,
	user_account text,
	parent_comment_id uuid,
	date_read timestamp,
	total_count bigint
);
CREATE FUNCTION article_api.list_replies(
	user_account_id uuid,
	page_number int,
	page_size int
) RETURNS SETOF article_api.user_comment_page_result
LANGUAGE SQL AS $func$
	SELECT
		reply.id,
		reply.date_created,
		reply.text,
		reply.article_id,
		reply.article_title,
		reply.article_slug,
		reply.user_account_id,
		reply.user_account,
		reply.parent_comment_id,
		reply.date_read,
		count(*) OVER() AS total_count
	FROM
		article_api.user_comment AS reply
		JOIN comment AS parent ON reply.parent_comment_id = parent.id
	WHERE parent.user_account_id = list_replies.user_account_id
	ORDER BY reply.date_created DESC
	OFFSET (page_number - 1) * page_size
	LIMIT page_size;
$func$;

---- article view refactor
-- drop objects
DROP FUNCTION article_api.find_user_article(
	slug text,
	user_account_id uuid
);
DROP FUNCTION article_api.get_user_article(
	article_id uuid,
	user_account_id uuid
);
DROP FUNCTION article_api.list_user_articles(
	user_account_id uuid,
	min_comment_count int,
	min_percent_complete int,
	sort text
);
DROP TYPE article_api.user_article;
-- create objects
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		user_account_id,
		words_read,
		date_created,
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		user_account_id,
		words_read,
		date_created,
		date_starred
	FROM article_api.user_article
	WHERE
		id = article_id AND
		user_account_id = get_user_article.user_account_id;
$func$;
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
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	readable_word_count bigint,
	page_count bigint,
	comment_count bigint,
	latest_comment_date timestamp,
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
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	readable_word_count bigint,
	page_count bigint,
	comment_count bigint,
	latest_comment_date timestamp,
	user_account_id uuid,
	words_read bigint,
	date_created timestamp,
	date_starred timestamp,
	total_count	bigint
);
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		count(*) OVER() AS total_count
	FROM article_api.article
	WHERE comment_count > 0
	ORDER BY latest_comment_date DESC
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		user_account_id,
		words_read,
		date_created,
		date_starred,
		count(*) OVER() AS total_count
	FROM article_api.user_article
	WHERE
		user_account_id = list_user_hot_topics.user_account_id AND
		comment_count > 0
	ORDER BY latest_comment_date DESC
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
		url,
		authors,
		tags,
		word_count,
		readable_word_count,
		page_count,
		comment_count,
		latest_comment_date,
		user_account_id,
		words_read,
		date_created,
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
DROP FUNCTION article_api.create_article(
	title          text,
	slug           text,
	source_id      uuid,
	date_published timestamp,
	date_modified  timestamp,
	section        text,
	description    text,
	authors        article_api.create_article_author [],
	tags           text []
);
CREATE FUNCTION article_api.create_article(
	title text,
	slug text,
	source_id uuid,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	authors article_api.create_article_author[],
	tags text[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	article_id	 		uuid;
	current_author		article_api.create_article_author;
	current_author_id	uuid;
	current_tag			text;
	current_tag_id		uuid;
BEGIN
	INSERT INTO article (title, slug, source_id, date_published, date_modified, section, description)
		VALUES (title, slug, source_id, date_published, date_modified, section, description)
		RETURNING id INTO article_id;
	FOREACH current_author IN ARRAY authors
	LOOP
		SELECT id INTO current_author_id FROM author WHERE url = current_author.url;
		IF current_author_id IS NULL THEN
			INSERT INTO author (name, url) VALUES (current_author.name, current_author.url)
				RETURNING id INTO current_author_id;
		END IF;
		INSERT INTO article_author (article_id, author_id) VALUES (article_id, current_author_id);
	END LOOP;
	FOREACH current_tag IN ARRAY tags
	LOOP
		SELECT id INTO current_tag_id FROM tag WHERE name = current_tag;
		IF current_tag_id IS NULL THEN
			INSERT INTO tag (name) VALUES (current_tag) RETURNING id INTO current_tag_id;
		END IF;
		INSERT INTO article_tag (article_id, tag_id) VALUES (article_id, current_tag_id);
	END LOOP;
	RETURN article_id;
END;
$func$;