/***
	article
***/
-- add new fk cols
ALTER TABLE article
	ADD COLUMN new_source_id bigint NULL;
-- set new fk values
UPDATE article SET
	new_source_id = new_id
	FROM id_migration.source WHERE old_id = source_id;
-- convert fks
ALTER TABLE article
	DROP CONSTRAINT article_source_id_fkey,
	ALTER COLUMN source_id TYPE bigint USING new_source_id,
	DROP COLUMN new_source_id;

/***
	article_author
***/
-- add new fk cols
ALTER TABLE article_author
	ADD COLUMN new_article_id bigint NULL,
	ADD COLUMN new_author_id bigint NULL;
-- set new fk values
UPDATE article_author SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
UPDATE article_author SET
	new_author_id = new_id
	FROM id_migration.author WHERE old_id = author_id;
-- convert fks
ALTER TABLE article_author
	DROP CONSTRAINT article_author_article_id_fkey,
	DROP CONSTRAINT article_author_author_id_fkey,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	ALTER COLUMN author_id TYPE bigint USING new_author_id,
	DROP COLUMN new_article_id,
	DROP COLUMN new_author_id;

/***
	article_tag
***/
-- add new fk cols
ALTER TABLE article_tag
	ADD COLUMN new_article_id bigint NULL,
	ADD COLUMN new_tag_id bigint NULL;
-- set new fk values
UPDATE article_tag SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
UPDATE article_tag SET
	new_tag_id = new_id
	FROM id_migration.tag WHERE old_id = tag_id;
-- convert fks
ALTER TABLE article_tag
	DROP CONSTRAINT article_tag_article_id_fkey,
	DROP CONSTRAINT article_tag_tag_id_fkey,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	ALTER COLUMN tag_id TYPE bigint USING new_tag_id,
	DROP COLUMN new_article_id,
	DROP COLUMN new_tag_id;

/***
	bulk_mailing
***/
-- add new fk cols
ALTER TABLE bulk_mailing
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE bulk_mailing SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE bulk_mailing
	DROP CONSTRAINT bulk_mailing_user_account_id_fkey,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_user_account_id;

/***
	bulk_mailing_recipient
***/
-- add new fk cols
ALTER TABLE bulk_mailing_recipient
	ADD COLUMN new_bulk_mailing_id bigint NULL,
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE bulk_mailing_recipient SET
	new_bulk_mailing_id = new_id
	FROM id_migration.bulk_mailing WHERE old_id = bulk_mailing_id;
UPDATE bulk_mailing_recipient SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE bulk_mailing_recipient
	DROP CONSTRAINT bulk_mailing_recipient_bulk_mailing_id_fkey,
	DROP CONSTRAINT bulk_mailing_recipient_user_account_id_fkey,
	ALTER COLUMN bulk_mailing_id TYPE bigint USING new_bulk_mailing_id,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_bulk_mailing_id,
	DROP COLUMN new_user_account_id;

/***
	comment
***/
-- add new fk cols
ALTER TABLE comment
	ADD COLUMN new_article_id bigint NULL,
	ADD COLUMN new_user_account_id bigint NULL,
	ADD COLUMN new_parent_comment_id bigint NULL;
-- set new fk values
UPDATE comment SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
UPDATE comment SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
UPDATE comment SET
	new_parent_comment_id = new_id
	FROM id_migration.comment WHERE old_id = parent_comment_id;
-- convert fks
ALTER TABLE comment
	DROP CONSTRAINT comment_article_id_fkey,
	DROP CONSTRAINT comment_user_account_id_fkey,
	DROP CONSTRAINT comment_parent_comment_id_fkey,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	ALTER COLUMN parent_comment_id TYPE bigint USING new_parent_comment_id,
	DROP COLUMN new_article_id,
	DROP COLUMN new_user_account_id,
	DROP COLUMN new_parent_comment_id;

/***
	email_bounce
***/
-- add new fk cols
ALTER TABLE email_bounce
	ADD COLUMN new_bulk_mailing_id bigint NULL;
-- set new fk values
UPDATE email_bounce SET
	new_bulk_mailing_id = new_id
	FROM id_migration.bulk_mailing WHERE old_id = bulk_mailing_id;
-- convert fks
ALTER TABLE email_bounce
	DROP CONSTRAINT email_bounce_bulk_mailing_id_fkey,
	ALTER COLUMN bulk_mailing_id TYPE bigint USING new_bulk_mailing_id,
	DROP COLUMN new_bulk_mailing_id;

/***
	email_confirmation
***/
-- add new fk cols
ALTER TABLE email_confirmation
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE email_confirmation SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE email_confirmation
	DROP CONSTRAINT email_confirmation_user_account_id_fkey,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_user_account_id;

/***
	email_share
***/
-- add new fk cols
ALTER TABLE email_share
	ADD COLUMN new_article_id bigint NULL,
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE email_share SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
UPDATE email_share SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE email_share
	DROP CONSTRAINT email_share_article_id_fkey,
	DROP CONSTRAINT email_share_user_account_id_fkey,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_article_id,
	DROP COLUMN new_user_account_id;

/***
	email_share_recipient
***/
-- add new fk cols
ALTER TABLE email_share_recipient
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE email_share_recipient SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE email_share_recipient
	DROP CONSTRAINT email_share_recipient_user_account_id_fkey,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_user_account_id;

/***
	page
***/
-- add new fk cols
ALTER TABLE page
	ADD COLUMN new_article_id bigint NULL;
-- set new fk values
UPDATE page SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
-- convert fks
ALTER TABLE page
	DROP CONSTRAINT page_article_id_fkey,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	DROP COLUMN new_article_id;

/***
	password_reset_request
***/
-- add new fk cols
ALTER TABLE password_reset_request
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE password_reset_request SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE password_reset_request
	DROP CONSTRAINT password_reset_request_user_account_id_fkey,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_user_account_id;

/***
	star
***/
-- add new fk cols
ALTER TABLE star
	ADD COLUMN new_user_account_id bigint NULL,
	ADD COLUMN new_article_id bigint NULL;
-- set new fk values
UPDATE star SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
UPDATE star SET
	new_article_id = new_id
	FROM id_migration.article WHERE old_id = article_id;
-- convert fks
ALTER TABLE star
	DROP CONSTRAINT star_user_account_id_fkey,
	DROP CONSTRAINT star_article_id_fkey,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	ALTER COLUMN article_id TYPE bigint USING new_article_id,
	DROP COLUMN new_user_account_id,
	DROP COLUMN new_article_id;

/***
	user_page
***/
-- add new fk cols
ALTER TABLE user_page
	ADD COLUMN new_page_id bigint NULL,
	ADD COLUMN new_user_account_id bigint NULL;
-- set new fk values
UPDATE user_page SET
	new_page_id = new_id
	FROM id_migration.page WHERE old_id = page_id;
UPDATE user_page SET
	new_user_account_id = new_id
	FROM id_migration.user_account WHERE old_id = user_account_id;
-- convert fks
ALTER TABLE user_page
	DROP CONSTRAINT user_page_page_id_fkey,
	DROP CONSTRAINT user_page_user_account_id_fkey,
	ALTER COLUMN page_id TYPE bigint USING new_page_id,
	ALTER COLUMN user_account_id TYPE bigint USING new_user_account_id,
	DROP COLUMN new_page_id,
	DROP COLUMN new_user_account_id;