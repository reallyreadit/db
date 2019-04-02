-- drop unused functions
DROP FUNCTION article_api.create_email_share(
	date_sent timestamp,
	article_id bigint,
	user_account_id bigint,
	message text,
	recipient_addresses text[],
	recipient_ids bigint[],
	recipient_results boolean[]
);
DROP FUNCTION article_api.delete_user_article(
	article_id bigint,
	user_account_id bigint
);