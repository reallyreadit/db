CREATE VIEW article_api.user_article_progress AS (
  SELECT
    words_read,
    date_created,
    last_modified,
    percent_complete,
    percent_complete >= 90 AS is_read,
    CASE WHEN
      percent_complete >= 90 THEN
      date_completed ELSE
      NULL
    END AS date_completed,
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
      user_article_pages.date_completed,
      user_article_pages.user_account_id,
      user_article_pages.article_id
    FROM
      article_api.user_article_pages
      JOIN article_api.article_pages ON article_pages.article_id = user_article_pages.article_id
  ) AS user_article_progress
  GROUP BY
    words_read,
    date_created,
    last_modified,
    percent_complete,
    date_completed,
    user_account_id,
    article_id
);