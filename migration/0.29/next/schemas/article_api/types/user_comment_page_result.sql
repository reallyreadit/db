CREATE TYPE article_api.user_comment_page_result AS (
	id bigint,
	date_created timestamp,
	text text,
	article_id bigint,
	article_title text,
	article_slug text,
	user_account_id bigint,
	user_account text,
	parent_comment_id bigint,
	date_read timestamp,
	total_count bigint
);