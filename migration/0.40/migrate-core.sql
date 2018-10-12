CREATE INDEX article_aotd_timestamp_idx ON article (aotd_timestamp DESC NULLS LAST);
CREATE INDEX article_score_idx ON article (score DESC);
CREATE INDEX comment_article_id_idx ON comment(article_id);
CREATE INDEX user_page_page_id_idx ON user_page(page_id);