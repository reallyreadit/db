SELECT
    *
FROM
    user_article
WHERE
    date_created = (SELECT min(date_created) FROM user_article) OR
    date_created = (SELECT max(date_created) FROM user_article);

SELECT
    period.local_timestamp,
    estimate_reading_time(sum(user_article.words_read) FILTER (WHERE user_article.date_completed IS NULL)) AS uncompleted_time,
    estimate_reading_time(sum(user_article.words_read) FILTER (WHERE user_article.date_completed IS NOT NULL)) AS completed_time
FROM
    generate_local_timestamp_to_utc_range_series(
        start => '2017-05-01',
        stop => '2020-05-01',
        step => '1 month',
        time_zone_name => 'America/New_York'
    ) AS period
    JOIN user_article ON
        user_article.last_modified <@ period.utc_range
WHERE
    user_article.analytics IS NULL OR
    user_article.analytics->'client'->>'type' = 'web/extension'
GROUP BY
    period.local_timestamp;