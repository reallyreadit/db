SELECT
	id, top_score, read_count, comment_count, average_rating_score, estimate_article_length(word_count), aotd_timestamp, title
FROM
	core.article
WHERE
	aotd_timestamp > '2019-01-01' AND
    source_id NOT IN (SELECT id FROM source WHERE hostname IN ('blog.readup.com', 'billloundy.com')) AND
    --word_count < (184 * 15)
	--word_count >= (184 * 15) AND word_count < (184 * 30)
	word_count >= (184 * 30)
ORDER BY
	top_score DESC NULLS LAST
LIMIT
	5;