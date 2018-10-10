CREATE VIEW article_api.user_article_pages AS (
  SELECT
    sum(user_page.words_read) AS words_read,
    min(user_page.date_created) AS date_created,
    max(user_page.last_modified) AS last_modified,
    max(user_page.date_completed) AS date_completed,
    user_page.user_account_id,
    page.article_id
  FROM
    user_page
    JOIN page ON page.id = user_page.page_id
  GROUP BY
    user_page.user_account_id,
    page.article_id
);