DROP FUNCTION article_api.score_articles();
DROP FUNCTION article_api.set_aotd();
DROP FUNCTION article_api.list_hot_topics(
	page_number int,
	page_size int
);
DROP FUNCTION article_api.list_user_hot_topics(
	user_account_id bigint,
	page_number int,
	page_size int
);
DROP VIEW article_api.article_score;
DROP VIEW article_api.hot_topic;