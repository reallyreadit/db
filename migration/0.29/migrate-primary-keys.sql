/***
	article
***/
-- add new_id column
ALTER TABLE article
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE article
	SET new_id = m.new_id
	FROM id_migration.article m
	WHERE old_id = id;
-- convert id
ALTER TABLE article
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE article_id_seq OWNED BY article.id;
SELECT setval('article_id_seq', (SELECT max(id) FROM article));
ALTER TABLE article
	ALTER COLUMN id SET DEFAULT nextval('article_id_seq');

/***
	author
***/
-- add new_id column
ALTER TABLE author
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE author
	SET new_id = m.new_id
	FROM id_migration.author m
	WHERE old_id = id;
-- convert id
ALTER TABLE author
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE author_id_seq OWNED BY author.id;
SELECT setval('author_id_seq', (SELECT max(id) FROM author));
ALTER TABLE author
	ALTER COLUMN id SET DEFAULT nextval('author_id_seq');

/***
	bulk_mailing
***/
-- add new_id column
ALTER TABLE bulk_mailing
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE bulk_mailing
	SET new_id = m.new_id
	FROM id_migration.bulk_mailing m
	WHERE old_id = id;
-- convert id
ALTER TABLE bulk_mailing
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE bulk_mailing_id_seq OWNED BY bulk_mailing.id;
SELECT setval('bulk_mailing_id_seq', (SELECT max(id) FROM bulk_mailing));
ALTER TABLE bulk_mailing
	ALTER COLUMN id SET DEFAULT nextval('bulk_mailing_id_seq');

/***
	comment
***/
-- add new_id column
ALTER TABLE comment
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE comment
	SET new_id = m.new_id
	FROM id_migration.comment m
	WHERE old_id = id;
-- convert id
ALTER TABLE comment
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE comment_id_seq OWNED BY comment.id;
SELECT setval('comment_id_seq', (SELECT max(id) FROM comment));
ALTER TABLE comment
	ALTER COLUMN id SET DEFAULT nextval('comment_id_seq');

/***
	email_bounce
***/
-- add new_id column
ALTER TABLE email_bounce
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE email_bounce
	SET new_id = m.new_id
	FROM id_migration.email_bounce m
	WHERE old_id = id;
-- convert id
ALTER TABLE email_bounce
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE email_bounce_id_seq OWNED BY email_bounce.id;
SELECT setval('email_bounce_id_seq', (SELECT max(id) FROM email_bounce));
ALTER TABLE email_bounce
	ALTER COLUMN id SET DEFAULT nextval('email_bounce_id_seq');

/***
	email_confirmation
***/
-- add new_id column
ALTER TABLE email_confirmation
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE email_confirmation
	SET new_id = m.new_id
	FROM id_migration.email_confirmation m
	WHERE old_id = id;
-- convert id
ALTER TABLE email_confirmation
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE email_confirmation_id_seq OWNED BY email_confirmation.id;
SELECT setval('email_confirmation_id_seq', (SELECT max(id) FROM email_confirmation));
ALTER TABLE email_confirmation
	ALTER COLUMN id SET DEFAULT nextval('email_confirmation_id_seq');

/***
	page
***/
-- add new_id column
ALTER TABLE page
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE page
	SET new_id = m.new_id
	FROM id_migration.page m
	WHERE old_id = id;
-- convert id
ALTER TABLE page
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE page_id_seq OWNED BY page.id;
SELECT setval('page_id_seq', (SELECT max(id) FROM page));
ALTER TABLE page
	ALTER COLUMN id SET DEFAULT nextval('page_id_seq');

/***
	password_reset_request
***/
-- add new_id column
ALTER TABLE password_reset_request
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE password_reset_request
	SET new_id = m.new_id
	FROM id_migration.password_reset_request m
	WHERE old_id = id;
-- convert id
ALTER TABLE password_reset_request
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE password_reset_request_id_seq OWNED BY password_reset_request.id;
SELECT setval('password_reset_request_id_seq', (SELECT max(id) FROM password_reset_request));
ALTER TABLE password_reset_request
	ALTER COLUMN id SET DEFAULT nextval('password_reset_request_id_seq');

/***
	source
***/
-- add new_id column
ALTER TABLE source
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE source
	SET new_id = m.new_id
	FROM id_migration.source m
	WHERE old_id = id;
-- convert id
ALTER TABLE source
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE source_id_seq OWNED BY source.id;
SELECT setval('source_id_seq', (SELECT max(id) FROM source));
ALTER TABLE source
	ALTER COLUMN id SET DEFAULT nextval('source_id_seq');

/***
	source_rule
***/
-- add new_id column
ALTER TABLE source_rule
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE source_rule
	SET new_id = m.new_id
	FROM id_migration.source_rule m
	WHERE old_id = id;
-- convert id
ALTER TABLE source_rule
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE source_rule_id_seq OWNED BY source_rule.id;
SELECT setval('source_rule_id_seq', (SELECT max(id) FROM source_rule));
ALTER TABLE source_rule
	ALTER COLUMN id SET DEFAULT nextval('source_rule_id_seq');

/***
	tag
***/
-- add new_id column
ALTER TABLE tag
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE tag
	SET new_id = m.new_id
	FROM id_migration.tag m
	WHERE old_id = id;
-- convert id
ALTER TABLE tag
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE tag_id_seq OWNED BY tag.id;
SELECT setval('tag_id_seq', (SELECT max(id) FROM tag));
ALTER TABLE tag
	ALTER COLUMN id SET DEFAULT nextval('tag_id_seq');

/***
	user_account
***/
-- add new_id column
ALTER TABLE user_account
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE user_account
	SET new_id = m.new_id
	FROM id_migration.user_account m
	WHERE old_id = id;
-- convert id
ALTER TABLE user_account
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE user_account_id_seq OWNED BY user_account.id;
SELECT setval('user_account_id_seq', (SELECT max(id) FROM user_account));
ALTER TABLE user_account
	ALTER COLUMN id SET DEFAULT nextval('user_account_id_seq');

/***
	user_page
***/
-- add new_id column
ALTER TABLE user_page
	ADD COLUMN new_id bigint NULL;
-- set new_id value
UPDATE user_page
	SET new_id = m.new_id
	FROM id_migration.user_page m
	WHERE old_id = id;
-- convert id
ALTER TABLE user_page
	ALTER COLUMN id DROP DEFAULT,
	ALTER COLUMN id TYPE bigint USING new_id,
	DROP COLUMN new_id;
-- create and set sequence
CREATE SEQUENCE user_page_id_seq OWNED BY user_page.id;
SELECT setval('user_page_id_seq', (SELECT max(id) FROM user_page));
ALTER TABLE user_page
	ALTER COLUMN id SET DEFAULT nextval('user_page_id_seq');