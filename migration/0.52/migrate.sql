CREATE OR REPLACE FUNCTION article_api.star_article(
	user_account_id bigint,
	article_id bigint
) RETURNS void
LANGUAGE SQL AS $func$
	INSERT INTO star (user_account_id, article_id)
	VALUES (user_account_id, article_id)
	ON CONFLICT (user_account_id, article_id)
	   DO UPDATE SET date_starred = utc_now();
$func$;