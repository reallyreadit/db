-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
	This migration adds proper user account deletion.
*/

-- Drop the old delete_user_account function that was only invoked manually by a database admin.
DROP FUNCTION
	user_account_api.delete_user_account(email_address text);

-- Add date_deleted to silent_post.
ALTER TABLE
	core.silent_post
ADD COLUMN
	date_deleted timestamp;

-- Drop the now-unused generate_random_string function.
DROP FUNCTION
	core.generate_random_string(length int);

-- Update social.post to reference silent_post.date_deleted.
CREATE OR REPLACE VIEW
	social.post
AS
	SELECT
		comment.article_id,
		comment.user_account_id,
		comment.date_created,
		comment.id AS comment_id,
		comment.text AS comment_text,
		comment.addenda AS comment_addenda,
		NULL::bigint AS silent_post_id,
		comment.date_deleted
	FROM
		social.comment
	WHERE
		comment.parent_comment_id IS NULL
	UNION ALL
	SELECT
		silent_post.article_id,
		silent_post.user_account_id,
		silent_post.date_created,
		NULL::bigint AS comment_id,
		NULL::text AS comment_text,
		NULL::social.comment_addendum[] AS comment_addenda,
		silent_post.id AS silent_post_id,
		silent_post.date_deleted
	FROM
		core.silent_post;

-- Update user_account name and email constraints to allow special patterns for deleted accounts.
ALTER TABLE
	core.user_account
DROP CONSTRAINT
	user_account_name_valid,
ADD CONSTRAINT
	user_account_name_valid
CHECK (
	name SIMILAR TO '[A-Za-z0-9\-_]+' OR
	(
		name SIMILAR TO '\[deleted\_[0-9]+\]' AND
		date_deleted IS NOT NULL
	)
),
DROP CONSTRAINT
	user_account_email_valid,
ADD CONSTRAINT
	user_account_email_valid
CHECK (
	email LIKE '%@%' OR
	(
		email SIMILAR TO '\[deleted\_[0-9]+\]' AND
		date_deleted IS NOT NULL
	)
);

-- Create a new delete_user_account function to be used as an API endpoint.
CREATE FUNCTION
	user_account_api.delete_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF core.user_account
LANGUAGE
	plpgsql
AS $$
BEGIN
	-- Update the user_account record, resetting the name, email and password and setting date_deleted.
	UPDATE
		core.user_account
	SET
		name = '[deleted_' || user_account.id || ']',
		email = '[deleted_' || user_account.id || ']',
		password_hash = E'\\xD78E59C4DC5CED432D999322DC0A773C5085D8D0F33D02EFFDB8AA1CD743E02A',
		password_salt = E'\\xE4522D33AB44B5C9026312450C9D2A19',
		creation_analytics = user_account.creation_analytics || jsonb_build_object(
			'deletion',
			jsonb_build_object('name', user_account.name, 'email', user_account.email)
		),
		date_deleted = core.utc_now()
	WHERE
		user_account.id = delete_user_account.user_account_id AND
		user_account.date_deleted IS NULL;

	-- Delete all comments.
	UPDATE
		core.comment
	SET
		date_deleted = core.utc_now()
	WHERE
		comment.user_account_id = delete_user_account.user_account_id AND
		comment.date_deleted IS NULL;

	-- Delete all silent posts.
	UPDATE
		core.silent_post
	SET
		date_deleted = core.utc_now()
	WHERE
		silent_post.user_account_id = delete_user_account.user_account_id AND
		silent_post.date_deleted IS NULL;

	-- Disable all followings.
	UPDATE
		core.following
	SET
		date_unfollowed = core.utc_now(),
		unfollow_analytics = jsonb_build_object('action', 'account_deletion')
	WHERE
		(
			following.follower_user_account_id = delete_user_account.user_account_id OR
			following.followee_user_account_id = delete_user_account.user_account_id
		) AND
		date_unfollowed IS NULL;

	-- Disable all notifications.
	PERFORM
		notifications.set_preference(
			user_account_id := delete_user_account.user_account_id,
			company_update_via_email := FALSE,
			aotd_via_email := FALSE,
			aotd_via_extension := FALSE,
			aotd_via_push := FALSE,
			aotd_digest_via_email := 'never',
			reply_via_email := FALSE,
			reply_via_extension := FALSE,
			reply_via_push := FALSE,
			reply_digest_via_email := 'never',
			loopback_via_email := FALSE,
			loopback_via_extension := FALSE,
			loopback_via_push := FALSE,
			loopback_digest_via_email := 'never',
			post_via_email := FALSE,
			post_via_extension := FALSE,
			post_via_push := FALSE,
			post_digest_via_email := 'never',
			follower_via_email := FALSE,
			follower_via_extension := FALSE,
			follower_via_push := FALSE,
			follower_digest_via_email := 'never'
		);

	-- Return the user_account.
	RETURN QUERY
	SELECT
		*
	FROM
		user_account_api.get_user_account_by_id(
			user_account_id := delete_user_account.user_account_id
		);
END;
$$;