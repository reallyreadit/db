ALTER TYPE article_api.user_article
ADD ATTRIBUTE rating_score rating_score;

ALTER TYPE article_api.user_article_page_result
RENAME ATTRIBUTE total_count TO rating_score;

ALTER TYPE article_api.user_article_page_result
ALTER ATTRIBUTE rating_score TYPE rating_score;

ALTER TYPE article_api.user_article_page_result
ADD ATTRIBUTE total_count bigint;