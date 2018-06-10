CREATE FUNCTION article_api.get_user_aotd(
	user_account_id bigint
)
RETURNS SETOF article_api.user_article
LANGUAGE SQL AS $func$
	SELECT *
	FROM article_api.user_article
	WHERE
		id = (
			SELECT id
			FROM core.article
			ORDER BY core.article.aotd_timestamp DESC NULLS LAST
			LIMIT 1
		) AND
		user_account_id = get_user_aotd.user_account_id;
$func$;