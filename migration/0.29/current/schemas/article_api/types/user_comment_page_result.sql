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