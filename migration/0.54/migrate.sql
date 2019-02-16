-- article_api.article
ALTER TYPE article_api.article
ADD ATTRIBUTE average_rating_score numeric;

-- article_api.article_page_result
ALTER TYPE article_api.article_page_result
RENAME ATTRIBUTE total_count TO average_rating_score;

ALTER TYPE article_api.article_page_result
ALTER ATTRIBUTE average_rating_score TYPE numeric;

ALTER TYPE article_api.article_page_result
ADD ATTRIBUTE total_count bigint;

-- article_api.user_article
ALTER TYPE article_api.user_article
ADD ATTRIBUTE average_rating_score numeric;

ALTER TYPE article_api.user_article
ADD ATTRIBUTE rating_score rating_score;

-- article_api.user_article_page_result
ALTER TYPE article_api.user_article_page_result
RENAME ATTRIBUTE total_count TO average_rating_score;

ALTER TYPE article_api.user_article_page_result
ALTER ATTRIBUTE average_rating_score TYPE numeric;

ALTER TYPE article_api.user_article_page_result
ADD ATTRIBUTE rating_score rating_score;

ALTER TYPE article_api.user_article_page_result
ADD ATTRIBUTE total_count bigint;