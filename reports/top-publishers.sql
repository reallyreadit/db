SELECT
	source.name,
    source.url,
    count(*) AS impression_count,
    sum(page.word_count) / 184 AS minute_count,
    count(*) FILTER (WHERE user_page.date_completed IS NOT NULL) AS read_count,
    sum(page.word_count) FILTER (WHERE user_page.date_completed IS NOT NULL) / 184 AS read_minute_count,
	(
		(count(*) FILTER (WHERE user_page.date_completed IS NOT NULL)) /
		count(*)::double precision
	) AS read_impression_ratio
FROM
	user_article
	JOIN page ON user_page.page_id = page.id
	JOIN article ON page.article_id = article.id
	JOIN source ON article.source_id = source.id
WHERE
	page.readable_word_count >= (184 * 10)
GROUP BY
	source.id
HAVING
	count(*) >= 100
ORDER BY
	read_impression_ratio DESC NULLS LAST;