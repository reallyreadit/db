/***
	article
***/
ALTER TABLE article
	ADD CONSTRAINT article_source_id_fkey
		FOREIGN KEY (source_id) REFERENCES source(id);

/***
	article_author
***/
ALTER TABLE article_author
	ADD CONSTRAINT article_author_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id),
	ADD CONSTRAINT article_author_author_id_fkey
		FOREIGN KEY (author_id) REFERENCES author(id);

/***
	article_tag
***/
ALTER TABLE article_tag
	ADD CONSTRAINT article_tag_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id),
	ADD CONSTRAINT article_tag_tag_id_fkey
		FOREIGN KEY (tag_id) REFERENCES tag(id);

/***
	bulk_mailing
***/
ALTER TABLE bulk_mailing
	ADD CONSTRAINT bulk_mailing_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	bulk_mailing_recipient
***/
ALTER TABLE bulk_mailing_recipient
	ADD CONSTRAINT bulk_mailing_recipient_bulk_mailing_id_fkey
		FOREIGN KEY (bulk_mailing_id) REFERENCES bulk_mailing(id),
	ADD CONSTRAINT bulk_mailing_recipient_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	comment
***/
ALTER TABLE comment
	ADD CONSTRAINT comment_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id),
	ADD CONSTRAINT comment_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id),
	ADD CONSTRAINT comment_parent_comment_id_fkey
		FOREIGN KEY (parent_comment_id) REFERENCES comment(id);

/***
	email_bounce
***/
ALTER TABLE email_bounce
	ADD CONSTRAINT email_bounce_bulk_mailing_id_fkey
		FOREIGN KEY (bulk_mailing_id) REFERENCES bulk_mailing(id);

/***
	email_confirmation
***/
ALTER TABLE email_confirmation
	ADD CONSTRAINT email_confirmation_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	email_share
***/
ALTER TABLE email_share
	ADD CONSTRAINT email_share_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id),
	ADD CONSTRAINT email_share_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	email_share_recipient
***/
ALTER TABLE email_share_recipient
	ADD CONSTRAINT email_share_recipient_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	page
***/
ALTER TABLE page
	ADD CONSTRAINT page_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id);

/***
	password_reset_request
***/
ALTER TABLE password_reset_request
	ADD CONSTRAINT password_reset_request_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);

/***
	star
***/
ALTER TABLE star
	ADD CONSTRAINT star_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id),
	ADD CONSTRAINT star_article_id_fkey
		FOREIGN KEY (article_id) REFERENCES article(id);

/***
	user_page
***/
ALTER TABLE user_page
	ADD CONSTRAINT user_page_page_id_fkey
		FOREIGN KEY (page_id) REFERENCES page(id),
	ADD CONSTRAINT user_page_user_account_id_fkey
		FOREIGN KEY (user_account_id) REFERENCES user_account(id);