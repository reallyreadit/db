DROP FUNCTION user_account_api.get_latest_reply_date(user_account_id uuid);
CREATE FUNCTION user_account_api.get_latest_unread_reply(user_account_id uuid) RETURNS SETOF article_api.user_comment
LANGUAGE SQL AS $func$
	SELECT reply.* FROM article_api.user_comment reply
		JOIN comment parent ON reply.parent_comment_id = parent.id
		JOIN user_account ON parent.user_account_id = user_account.id
		WHERE user_account.id = get_latest_unread_reply.user_account_id AND reply.date_read IS NULL
		ORDER BY reply.date_created DESC
		LIMIT 1;
$func$;
CREATE TYPE source_rule_action AS ENUM ('default', 'read', 'ignore');
CREATE TABLE source_rule (
	id 			uuid				PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	hostname	varchar(256)		NOT NULL,
	path		varchar(256)		NOT NULL,
	priority	int					NOT NULL	DEFAULT 0,
	action		source_rule_action	NOT NULL
);
CREATE FUNCTION article_api.get_source_rules() RETURNS SETOF source_rule
LANGUAGE SQL AS $func$
	SELECT * FROM source_rule;
$func$;
INSERT INTO source_rule (hostname, path, priority, action) VALUES
	('hosted.ap.org', '^/dynamic/stories/*', 0, 'read'),
	('craigslist.org', '^/*', 0, 'ignore'),
	('blog.craigslist.org', '^/*', 1, 'default'),
	('docs.google.com', '^/*', 0, 'ignore'),
	('imgur.com', '^/*', 0, 'ignore'),
	('blog.imgur.com', '^/\d{4}/\d{2}/\d{2}/*', 1, 'read'),
	('mysteriousuniverse.org', '^/\d{4}/\d{2}/*', 0, 'read'),
	('rawstory.com', '^/\d{4}/\d{2}/*', 0, 'read'),
	('twitter.com', '^/*', 0, 'ignore'),
	('blog.twitter.com', '^/*', 1, 'default'),
	('wunderground.com', '^/*', 0, 'ignore'),
	('wunderground.com', '^/(cat6|blog|news)/*', 1, 'default');