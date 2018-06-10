CREATE FUNCTION article_api.score_articles() RETURNS void
LANGUAGE SQL AS $func$
	UPDATE article
	SET score = article_score.score
	FROM article_api.article_score
	WHERE article_score.article_id = article.id;
$func$;