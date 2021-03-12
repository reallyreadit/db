/*
Start by truncating tables that either a) contain only private data or b) contain some private data but are not
important enough to selectively delete from for general general development purposes.
*/
TRUNCATE TABLE
	-- delete all auth service data (authentication data)
	core.auth_service_access_token,
	core.auth_service_association,
	core.auth_service_authentication,
	core.auth_service_identity,
	core.auth_service_post,
	core.auth_service_refresh_token,
	core.auth_service_request_token,
	core.auth_service_user,
	-- delete challenge response data
	core.challenge_response,
	-- delete client error report (can contain reading data)
	core.client_error_report,
	-- delete display preferences
	core.display_preference,
	-- delete email confirmations (contains email address)
	core.email_confirmation,
	-- delete email notifications (can contain reading data)
	core.email_notification,
	-- delete legacy email sharing data
	core.email_share,
	core.email_share_recipient,
	-- delete extension installation/removal analytics
	core.extension_installation,
	core.extension_removal,
	-- delete notification data
	core.notification_data,
	core.notification_event,
	core.notification_interaction,
	core.notification_preference,
	core.notification_push_auth_denial,
	core.notification_push_device,
	core.notification_receipt,
	-- delete legacy orientation analytics
	core.orientation_analytics,
	-- delete password reset requests (contains email address, references auth_service_authentication)
	core.password_reset_request,
	-- delete rating data (private)
	core.rating,
	-- delete legacy share result analytics
	core.share_result,
	-- delete star data (private)
	core.star,
	-- delete use subscription data (authentication data)
	core.subscription,
	core.subscription_account,
	core.subscription_default_payment_method,
	core.subscription_payment_method,
	core.subscription_payment_method_version,
	core.subscription_period,
	core.subscription_period_author_distribution,
	core.subscription_period_distribution;

/*
Insert required preferences with default values and disabling notifications.
*/
INSERT INTO
	core.display_preference (
		user_account_id,
		theme,
		text_size,
		hide_links
	)
SELECT
	user_account.id,
	'dark'::core.display_theme,
	1,
	TRUE
FROM
	core.user_account;

INSERT INTO
	core.notification_preference (
		user_account_id,
		company_update_via_email,
		aotd_via_email,
		aotd_via_extension,
		aotd_via_push,
		aotd_digest_via_email,
		reply_via_email,
		reply_via_extension,
		reply_via_push,
		reply_digest_via_email,
		loopback_via_email,
		loopback_via_extension,
		loopback_via_push,
		loopback_digest_via_email,
		post_via_email,
		post_via_extension,
		post_via_push,
		post_digest_via_email,
		follower_via_email,
		follower_via_extension,
		follower_via_push,
		follower_digest_via_email
	)
SELECT
	user_account.id,
	FALSE,
	FALSE,
	FALSE,
	FALSE,
	'never'::core.notification_event_frequency,
	FALSE,
	FALSE,
	FALSE,
	'never'::core.notification_event_frequency,
	FALSE,
	FALSE,
	FALSE,
	'never'::core.notification_event_frequency,
	FALSE,
	FALSE,
	FALSE,
	'never'::core.notification_event_frequency,
	FALSE,
	FALSE,
	FALSE,
	'never'::core.notification_event_frequency
FROM
	core.user_account;

/*
Anonymize specific columns that contain sensitive data.
*/
UPDATE
	core.author
SET
	email_address = NULL
WHERE
	author.email_address IS NOT NULL;

UPDATE
	core.new_platform_notification_request
SET
	email_address = 'anon@readup.com',
	ip_address = '0.0.0.0'
WHERE
	TRUE;

UPDATE
	core.provisional_user_account
SET
	-- deleting merge data means we don't have to delete any provisional reading data
	date_merged = NULL,
	merged_user_account_id = NULL,
	creation_analytics = NULL
WHERE
	TRUE;

UPDATE
	core.user_account
SET
	email = user_account.name || '@readup.com',
	-- sets password = 'password'
	password_hash = E'\\x4B0C6BA854E085CA2C6E014EE461000187C6D9C28FBDFC96AD7B203F8CC4E6BF',
	password_salt = E'\\x00000000000000000000000000000000',
	time_zone_id = NULL,
	creation_analytics = NULL,
	is_email_confirmed = FALSE,
	aotd_alert = FALSE,
	reply_alert_count = 0,
	loopback_alert_count = 0,
	post_alert_count = 0,
	has_linked_twitter_account = FALSE,
	date_deleted = NULL,
	date_orientation_completed = NULL
WHERE
	TRUE;

/*
Delete all user reading data that is not associated with a post.
*/
DELETE FROM
	core.user_article AS private_user_article
USING
	core.user_article
	LEFT JOIN
		core.comment ON
			user_article.article_id = comment.article_id AND
			user_article.user_account_id = comment.user_account_id
	LEFT JOIN
		core.silent_post ON
			user_article.article_id = silent_post.article_id AND
			user_article.user_account_id = silent_post.user_account_id
WHERE
	private_user_article.id = user_article.id AND
	comment.id IS NULL AND
	silent_post.id IS NULL;

DELETE FROM
	core.user_article_progress AS private_progress
USING
	core.user_article_progress AS progress
	LEFT JOIN
		core.user_article ON
			progress.article_id = user_article.article_id AND
			progress.user_account_id = user_article.user_account_id
WHERE
	private_progress.id = progress.id AND
	user_article.id IS NULL;

/*
As a general cleanup delete all articles, pages, authors, tags and sources that are no longer being referenced.
*/
CREATE TEMPORARY TABLE
	orphaned_article AS
WITH article_without_image AS (
	SELECT
		article.id
	FROM
		core.article
		LEFT JOIN
			core.article_image ON
				article.id = article_image.article_id
	WHERE
		article_image.article_id IS NULL
),
article_without_issue_report AS (
	SELECT
		article.id
	FROM
		core.article
		LEFT JOIN
			core.article_issue_report ON
				article.id = article_issue_report.article_id
	WHERE
		article_issue_report.id IS NULL
),
article_without_provisional_user_article AS (
	SELECT
		article.id
	FROM
		core.article
		LEFT JOIN
			core.provisional_user_article ON
				article.id = provisional_user_article.article_id
	WHERE
		provisional_user_article.article_id IS NULL
),
article_without_user_article AS (
	SELECT
		article.id
	FROM
		core.article
		LEFT JOIN
			core.user_article ON
				article.id = user_article.article_id
	WHERE
		user_article.id IS NULL
)
SELECT
	id
FROM
	article_without_image
INTERSECT
SELECT
	id
FROM
	article_without_issue_report
INTERSECT
SELECT
	id
FROM
	article_without_provisional_user_article
INTERSECT
SELECT
	id
FROM
	article_without_user_article;

DELETE FROM
	core.article_author
USING
	orphaned_article
WHERE
	article_author.article_id = orphaned_article.id;

CREATE INDEX
    article_author_author_id_idx ON
        core.article_author (author_id);

DELETE FROM
	core.author AS orphaned_author
USING
	core.author
	LEFT JOIN
		core.article_author ON
			author.id = article_author.author_id
WHERE
	orphaned_author.id = author.id AND
	article_author.article_id IS NULL;

DROP INDEX
	article_author_author_id_idx;

DELETE FROM
	core.article_tag
USING
	orphaned_article
WHERE
	article_tag.article_id = orphaned_article.id;

DELETE FROM
	core.tag AS orphaned_tag
USING
	core.tag
	LEFT JOIN
		core.article_tag ON
			tag.id = article_tag.tag_id
WHERE
	orphaned_tag.id = tag.id AND
	article_tag.article_id IS NULL;

DELETE FROM
	core.page
USING
	orphaned_article
WHERE
	page.article_id = orphaned_article.id;

CREATE INDEX
    article_author_article_id_idx ON
        core.article_author (article_id);
CREATE INDEX
    article_image_article_id_idx ON
        core.article_image (article_id);
CREATE INDEX
    article_issue_report_article_id_idx ON
        core.article_issue_report (article_id);
CREATE INDEX
    article_tag_article_id_idx ON
        core.article_tag (article_id);
CREATE INDEX
    provisional_user_article_article_id_idx ON
        core.provisional_user_article (article_id);
CREATE INDEX
    provisional_user_article_progress_article_id_idx ON
        core.provisional_user_article_progress (article_id);
CREATE INDEX
    user_article_progress_article_id_idx ON
        core.user_article_progress (article_id);

DELETE FROM
	core.article
USING
	orphaned_article
WHERE
	article.id = orphaned_article.id;

DROP INDEX
    article_author_article_id_idx;
DROP INDEX
    article_image_article_id_idx;
DROP INDEX
    article_issue_report_article_id_idx;
DROP INDEX
    article_tag_article_id_idx;
DROP INDEX
    provisional_user_article_article_id_idx;
DROP INDEX
    provisional_user_article_progress_article_id_idx;
DROP INDEX
    user_article_progress_article_id_idx;

CREATE INDEX
	article_source_id_idx
ON
	core.article (source_id);

DELETE FROM
	core.source AS orphaned_source
USING
	core.source
	LEFT JOIN
		core.article ON
			source.id = article.source_id
WHERE
	orphaned_source.id = source.id AND
	article.id IS NULL;

DROP INDEX
	article_source_id_idx;

DROP TABLE
	orphaned_article;