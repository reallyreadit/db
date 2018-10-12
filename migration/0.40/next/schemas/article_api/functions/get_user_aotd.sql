CREATE FUNCTION article_api.get_user_aotd(
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL
STABLE
AS $func$
	SELECT * FROM article_api.get_user_articles(
		user_account_id,
		(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT 1
		)
	);
$func$;