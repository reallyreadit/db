SELECT
	user_account.id,
    user_account.name,
    user_account.email,
    user_account.date_created,
    count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS article_completions,
    max(user_article.last_modified) AS latest_read_activity,
    mode() WITHIN GROUP (ORDER BY user_article.analytics->'client'->>'type') AS preferred_client_type,
    time_zone.name AS time_zone
FROM
	user_account
	LEFT JOIN time_zone
	    ON time_zone.id = user_account.time_zone_id
	LEFT JOIN user_article
		ON user_article.user_account_id = user_account.id
GROUP BY
	user_account.id,
    time_zone.id
ORDER BY
	user_account.id;