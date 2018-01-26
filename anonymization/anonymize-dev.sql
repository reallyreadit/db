-- drop all transactional user records
---- drop all email_bounces
DELETE FROM email_bounce;
---- drop all bulk_mailing_recipients
DELETE FROM bulk_mailing_recipient;
---- drop all bulk_mailings
DELETE FROM bulk_mailing;
---- drop all email_confirmations
DELETE FROM email_confirmation;
---- drop all password_reset_requests
DELETE FROM password_reset_request;

-- drop all private user article history
---- drop all stars
DELETE FROM star;
---- mark all comments as unread
UPDATE comment
SET date_read = NULL;
---- drop all user_pages unless user commented on article
DELETE
FROM user_page
WHERE id IN (
	SELECT user_page.id
	FROM user_page
		JOIN page ON page.id = user_page.page_id
		JOIN article ON article.id = page.article_id
		LEFT JOIN comment ON
			comment.article_id = article.id AND
			comment.user_account_id = user_page.user_account_id
	WHERE comment IS NULL
	GROUP BY user_page.id
);
---- homogenize user_pages
UPDATE user_page
SET
	date_created = '1970-01-01T00:00:00',
	last_modified = '1970-01-01T00:00:00',
	read_state = array((SELECT sum(abs(n)) FROM unnest(read_state) AS n)),
	words_read = (SELECT sum(abs(n)) FROM unnest(read_state) AS n);
---- drop all pages without user_pages
DELETE
FROM page
WHERE id IN (
	SELECT page.id
	FROM page
		LEFT JOIN user_page ON user_page.page_id = page.id
	WHERE user_page IS NULL
	GROUP BY page.id
);
---- drop all articles without pages
CREATE TEMP VIEW articles_to_delete AS (
	SELECT article.id
	FROM article
		LEFT JOIN page ON page.article_id = article.id
	WHERE page IS NULL
	GROUP BY article.id
);
------ drop article_authors
DELETE
FROM article_author
WHERE article_id IN (
	SELECT id
	FROM articles_to_delete
);
------ drop article_tags
DELETE
FROM article_tag
WHERE article_id IN (
	SELECT id
	FROM articles_to_delete
);
------ drop articles
DELETE
FROM article
WHERE id IN (
	SELECT id
	FROM articles_to_delete
);
---- drop all authors without articles
DELETE
FROM author
WHERE id IN (
	SELECT author.id
	FROM author
		LEFT JOIN article_author ON article_author.author_id = author.id
	WHERE article_author IS NULL
	GROUP BY author.id
);
---- drop all tags without articles
DELETE
FROM tag
WHERE id IN (
	SELECT tag.id
	FROM tag
		LEFT JOIN article_tag ON article_tag.tag_id = tag.id
	WHERE article_tag IS NULL
	GROUP BY tag.id
);
---- drop all sources without articles
DELETE
FROM source
WHERE id IN (
	SELECT source.id
	FROM source
		LEFT JOIN article ON article.source_id = source.id
	WHERE article IS NULL
	GROUP BY source.id
);

-- anonymize user_accounts
---- change ids
------ create new ids
CREATE TEMP TABLE user_account_ids AS (
	SELECT
		id,
		pgcrypto.gen_random_uuid() AS new_id
	FROM user_account
);
------ change comment foreign key to cascade on update
ALTER TABLE comment
DROP CONSTRAINT comment_user_account_id_fkey;
ALTER TABLE comment
ADD CONSTRAINT comment_user_account_id_fkey
	FOREIGN KEY (user_account_id)
	REFERENCES user_account
	ON UPDATE CASCADE;
------ change user_page foreign key to cascade on update
ALTER TABLE user_page
DROP CONSTRAINT user_page_user_account_id_fkey;
ALTER TABLE user_page
ADD CONSTRAINT user_page_user_account_id_fkey
	FOREIGN KEY (user_account_id)
	REFERENCES user_account
	ON UPDATE CASCADE;
------ set new id
UPDATE user_account
SET id = (
	SELECT new_id
	FROM user_account_ids
	WHERE id = user_account.id
);
------ revert comment foreign key to no action on update
ALTER TABLE comment
DROP CONSTRAINT comment_user_account_id_fkey;
ALTER TABLE comment
ADD CONSTRAINT comment_user_account_id_fkey
	FOREIGN KEY (user_account_id)
	REFERENCES user_account;
------ revert user_page foreign key to no action on update
ALTER TABLE user_page
DROP CONSTRAINT user_page_user_account_id_fkey;
ALTER TABLE user_page
ADD CONSTRAINT user_page_user_account_id_fkey
	FOREIGN KEY (user_account_id)
	REFERENCES user_account;
---- set email
UPDATE user_account
SET email = name || '@localhost';
---- set password_hash and password_salt (password = 'password')
UPDATE user_account
SET
	password_hash = E'\\x4B0C6BA854E085CA2C6E014EE461000187C6D9C28FBDFC96AD7B203F8CC4E6BF',
	password_salt = E'\\x00000000000000000000000000000000';
---- set notification and contact preferences
UPDATE user_account
SET
	receive_reply_email_notifications = TRUE,
	receive_reply_desktop_notifications = TRUE,
	receive_website_updates = TRUE,
	receive_suggested_readings = TRUE;
---- set reply timestamps
UPDATE user_account
SET
	last_new_reply_ack = '1970-01-01T00:00:00',
	last_new_reply_desktop_notification = '1970-01-01T00:00:00';
---- set date_created
UPDATE user_account
SET date_created = '1970-01-01T00:00:00';
---- set role
UPDATE user_account
SET role = 'regular';
---- confirm email addresses
INSERT INTO email_confirmation
	(id, date_created, user_account_id, email_address, date_confirmed)
SELECT
	pgcrypto.gen_random_uuid(),
	'1970-01-01T00:00:00',
	id,
	email,
	'1970-01-01T00:00:00'
FROM user_account;