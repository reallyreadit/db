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
   average_rating_score numeric
);