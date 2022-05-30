-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/* create new notification objects */
CREATE TYPE core.notification_event_type AS ENUM (
    'welcome',
    'email_confirmation',
	'email_confirmation_reminder',
    'password_reset',
    'company_update',
    'suggested_reading',
    'aotd',
    'aotd_digest',
    'reply',
    'reply_daily_digest',
    'reply_weekly_digest',
    'loopback',
    'loopback_daily_digest',
    'loopback_weekly_digest',
    'post',
    'post_daily_digest',
    'post_weekly_digest',
    'follower',
    'follower_daily_digest',
    'follower_weekly_digest'
);
CREATE TYPE core.notification_channel AS ENUM (
  	'email',
    'extension',
    'push'
);
CREATE TYPE core.notification_action AS ENUM (
  	'open',
    'view',
    'reply'
);
CREATE TABLE core.notification_event (
  	id bigserial PRIMARY KEY,
  	date_created timestamp NOT NULL DEFAULT utc_now(),
  	type core.notification_event_type NOT NULL,
  	bulk_email_author_id bigint REFERENCES core.user_account (id),
  	bulk_email_subject text,
  	bulk_email_body text
);
CREATE TABLE core.notification_receipt (
	id bigserial PRIMARY KEY,
	event_id bigint NOT NULL REFERENCES core.notification_event (id),
	user_account_id bigint NOT NULL REFERENCES core.user_account (id),
	date_alert_cleared timestamp,
	via_email bool NOT NULL DEFAULT false,
	via_extension bool NOT NULL DEFAULT false,
	via_push bool NOT NULL DEFAULT false
);
CREATE TABLE core.notification_data (
  	id bigserial PRIMARY KEY,
  	event_id bigint NOT NULL REFERENCES core.notification_event (id),
  	article_id bigint REFERENCES core.article (id),
  	comment_id bigint REFERENCES core.comment (id),
  	silent_post_id bigint REFERENCES core.silent_post (id),
  	following_id bigint REFERENCES core.following (id),
  	email_confirmation_id bigint REFERENCES core.email_confirmation (id),
  	password_reset_request_id bigint REFERENCES core.password_reset_request (id)
  	CHECK (
  	    article_id IS NOT NULL OR
  	    comment_id IS NOT NULL OR
  	    silent_post_id IS NOT NULL OR
  	    following_id IS NOT NULL OR
  	    email_confirmation_id IS NOT NULL OR
  	    password_reset_request_id IS NOT NULL
  	)
);
CREATE TABLE core.notification_interaction (
    id bigserial PRIMARY KEY,
  	receipt_id bigint NOT NULL REFERENCES notification_receipt (id),
  	channel core.notification_channel NOT NULL,
  	action core.notification_action NOT NULL,
  	date_created timestamp NOT NULL DEFAULT core.utc_now(),
  	url text,
  	reply_id bigint REFERENCES core.comment (id),
  	CHECK (
  		action = 'open' OR
  		(action = 'view' AND url IS NOT NULL) OR
  		(action = 'reply' AND reply_id IS NOT NULL)
	)
);
CREATE UNIQUE INDEX
    notification_interaction_unique_open ON
    	core.notification_interaction (receipt_id, channel, action)
WHERE
	action = 'open';
CREATE UNIQUE INDEX
    notification_interaction_unique_view ON
    	core.notification_interaction (receipt_id, channel, action, url);
CREATE TYPE core.notification_event_frequency AS ENUM (
    'never',
	'daily',
    'weekly'
);
CREATE TABLE core.notification_preference (
	id bigserial PRIMARY KEY,
	user_account_id bigint NOT NULL REFERENCES user_account (id),
	last_modified timestamp NOT NULL DEFAULT core.utc_now(),
	company_update_via_email bool NOT NULL DEFAULT TRUE,
	aotd_via_email bool NOT NULL DEFAULT TRUE,
	aotd_via_extension bool NOT NULL DEFAULT TRUE,
	aotd_via_push bool NOT NULL DEFAULT TRUE,
	aotd_digest_via_email core.notification_event_frequency NOT NULL CHECK (aotd_digest_via_email != 'daily') DEFAULT 'never',
	reply_via_email bool NOT NULL DEFAULT TRUE,
	reply_via_extension bool NOT NULL DEFAULT TRUE,
	reply_via_push bool NOT NULL DEFAULT TRUE,
	reply_digest_via_email core.notification_event_frequency NOT NULL DEFAULT 'never',
	loopback_via_email bool NOT NULL DEFAULT TRUE,
	loopback_via_extension bool NOT NULL DEFAULT TRUE,
	loopback_via_push bool NOT NULL DEFAULT TRUE,
	loopback_digest_via_email core.notification_event_frequency NOT NULL DEFAULT 'never',
	post_via_email bool NOT NULL DEFAULT TRUE,
	post_via_extension bool NOT NULL DEFAULT TRUE,
	post_via_push bool NOT NULL DEFAULT TRUE,
	post_digest_via_email core.notification_event_frequency NOT NULL DEFAULT 'never',
	follower_via_email bool NOT NULL DEFAULT TRUE,
	follower_via_extension bool NOT NULL DEFAULT TRUE,
	follower_via_push bool NOT NULL DEFAULT TRUE,
	follower_digest_via_email core.notification_event_frequency NOT NULL DEFAULT 'never'
);
CREATE TYPE core.notification_push_unregistration_reason AS ENUM (
	'sign_out',
    'user_change',
    'token_change',
    'service_unregistered'
);
CREATE TABLE core.notification_push_device (
	id bigserial PRIMARY KEY,
	date_registered timestamp NOT NULL DEFAULT core.utc_now(),
	date_unregistered timestamp,
	unregistration_reason core.notification_push_unregistration_reason,
	user_account_id bigint NOT NULL REFERENCES user_account (id),
	installation_id text NOT NULL,
	name text,
	token text NOT NULL
);
CREATE UNIQUE INDEX
    notification_push_device_unique_registered_installation_id ON
    	core.notification_push_device (installation_id)
WHERE
	date_unregistered IS NULL;
CREATE UNIQUE INDEX
    notification_push_device_unique_registered_token ON
    	core.notification_push_device (token)
WHERE
	date_unregistered IS NULL;
CREATE TABLE core.notification_push_auth_denial (
	id bigserial PRIMARY KEY,
    date_denied timestamp NOT NULL DEFAULT core.utc_now(),
    user_account_id bigint NOT NULL REFERENCES user_account (id),
    installation_id text,
    device_name text
);
/* add new cached columns to user_account for email confirmation and alert counts */
ALTER TABLE
	core.user_account
ADD COLUMN
    is_email_confirmed bool NOT NULL DEFAULT false;
ALTER TABLE
	core.user_account
ADD COLUMN
	aotd_alert bool NOT NULL DEFAULT false;
ALTER TABLE
	core.user_account
ADD COLUMN
    reply_alert_count int NOT NULL DEFAULT 0;
ALTER TABLE
	core.user_account
ADD COLUMN
    loopback_alert_count int NOT NULL DEFAULT 0;
ALTER TABLE
	core.user_account
ADD COLUMN
    post_alert_count int NOT NULL DEFAULT 0;
ALTER TABLE
	core.user_account
ADD COLUMN
    follower_alert_count int NOT NULL DEFAULT 0;
/* migrate existing bulk mailings */
INSERT INTO
    core.notification_event (
    	id,
    	date_created,
        type,
        bulk_email_author_id,
		bulk_email_subject,
		bulk_email_body
	)
	(
	    SELECT
	    	id,
	        date_sent,
	        CASE list
			    WHEN 'ConfirmationReminder'
			    	THEN 'email_confirmation_reminder'::core.notification_event_type
			    WHEN 'WebsiteUpdates'
			    	THEN 'company_update'::core.notification_event_type
			    WHEN 'SuggestedReadings'
			    	THEN 'suggested_reading'::core.notification_event_type
	    	END,
	        user_account_id,
	        subject,
	        body
	    FROM
	    	bulk_mailing
	);
SELECT
	setval(
	    'core.notification_event_id_seq',
	    (
	        SELECT
	        	max(id)
	        FROM
	        	core.notification_event
		)
	);
INSERT INTO
	core.notification_receipt (
		event_id,
	    user_account_id,
		via_email
	)
	(
	    SELECT
	        recipient.bulk_mailing_id,
	        recipient.user_account_id,
	        TRUE
	    FROM
	    	bulk_mailing_recipient AS recipient
	);
/* migrate existing preferences */
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
	(
		SELECT
			id,
			receive_website_updates,
			receive_suggested_readings,
			receive_suggested_readings,
			receive_suggested_readings,
			'never',
			receive_reply_email_notifications,
			receive_reply_desktop_notifications,
			receive_reply_email_notifications OR receive_reply_desktop_notifications,
		    'never',
			receive_reply_email_notifications,
			receive_reply_desktop_notifications,
			receive_reply_email_notifications OR receive_reply_desktop_notifications,
			'never',
			receive_reply_email_notifications,
			receive_reply_desktop_notifications,
			receive_reply_email_notifications OR receive_reply_desktop_notifications,
		    'never',
			receive_reply_email_notifications,
			receive_reply_desktop_notifications,
			receive_reply_email_notifications OR receive_reply_desktop_notifications,
		    'never'
		FROM
			core.user_account
	);
/* refactor bulk_mailing_api into notifications */
DROP FUNCTION bulk_mailing_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id bigint,
	recipient_ids bigint[],
	recipient_results boolean[]
);
DROP FUNCTION bulk_mailing_api.list_bulk_mailings();
CREATE FUNCTION bulk_mailing_api.get_bulk_mailings()
RETURNS TABLE(
    id bigint,
    date_sent timestamp without time zone,
    subject text,
    body text,
    type core.notification_event_type,
    user_account text,
    recipient_count bigint
)
LANGUAGE sql
AS $$
	SELECT
		event.id,
		event.date_created,
		event.bulk_email_subject,
		event.bulk_email_body,
		event.type,
		user_account.name AS user_account,
		count(*) AS recipient_count
	FROM
		notification_event AS event
		JOIN user_account ON user_account.id = event.bulk_email_author_id
		JOIN notification_receipt ON notification_receipt.event_id = event.id
	GROUP BY
		event.id, user_account.id;
$$;
DROP FUNCTION bulk_mailing_api.list_confirmation_reminder_recipients();
ALTER SCHEMA bulk_mailing_api RENAME TO notifications;
DROP TABLE core.bulk_mailing_recipient;
DROP TABLE core.bulk_mailing;
/* refactor and migrate email confirmation status from view to table */
CREATE OR REPLACE FUNCTION user_account_api.confirm_email_address(
	email_confirmation_id bigint
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    user_account_id bigint;
	rows_updated int;
BEGIN
	UPDATE
	    email_confirmation
	SET
		date_confirmed = utc_now()
	WHERE
		email_confirmation.id = confirm_email_address.email_confirmation_id AND
	    email_confirmation.date_confirmed IS NULL
	RETURNING
		email_confirmation.user_account_id INTO locals.user_account_id;
	GET DIAGNOSTICS rows_updated = ROW_COUNT;
	IF rows_updated = 1 THEN
		UPDATE
		    user_account
	    SET
	        is_email_confirmed = true
	    WHERE
	    	user_account.id = locals.user_account_id;
	END IF;
	RETURN rows_updated = 1;
END;
$$;
CREATE OR REPLACE FUNCTION user_account_api.create_email_confirmation(
	user_account_id bigint
)
RETURNS SETOF core.email_confirmation
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE
		user_account
	SET
		is_email_confirmed = false
	WHERE
		id = create_email_confirmation.user_account_id;
    RETURN QUERY
	INSERT INTO
	    email_confirmation (
			user_account_id,
	        email_address
	    )
	VALUES (
		create_email_confirmation.user_account_id,
		(
		    SELECT
		    	email
			FROM
				user_account
		    WHERE
		    	id = create_email_confirmation.user_account_id
		)
	)
	RETURNING *;
END;
$$;
UPDATE
    core.user_account
SET
	is_email_confirmed = api_user_account.is_email_confirmed
FROM
	user_account_api.user_account AS api_user_account
WHERE
	user_account.id = api_user_account.id;
/* refactor functions dependent on user_account view */
DROP FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint,
	analytics text
);
-- create_user_account also needs to create a notification_preference record
CREATE FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint,
	analytics text
)
RETURNS SETOF core.user_account
LANGUAGE sql
AS $$
    WITH new_user AS (
		INSERT INTO
			core.user_account (
				name,
				email,
				password_hash,
				password_salt,
				time_zone_id,
				creation_analytics
			)
		VALUES
			(
				trim(create_user_account.name),
				trim(create_user_account.email),
				create_user_account.password_hash,
				create_user_account.password_salt,
				create_user_account.time_zone_id,
				create_user_account.analytics::json
			)
		RETURNING *
    ),
	initial_preference AS (
		INSERT INTO
	    	core.notification_preference (user_account_id)
	    (SELECT id FROM new_user)
	)
    SELECT * FROM new_user;
$$;
DROP FUNCTION user_account_api.get_user_account_by_email(
	email text
);
CREATE FUNCTION user_account_api.get_user_account_by_email(
	email text
)
RETURNS SETOF core.user_account
LANGUAGE sql
STABLE
AS $$
	SELECT
		*
	FROM
		core.user_account
	WHERE
		lower(email) = lower(get_user_account_by_email.email);
$$;
DROP FUNCTION user_account_api.get_user_account_by_id(
	user_account_id bigint
);
CREATE FUNCTION user_account_api.get_user_account_by_id(
	user_account_id bigint
)
RETURNS SETOF core.user_account
LANGUAGE sql
STABLE
AS $$
	SELECT
		*
	FROM
		core.user_account
	WHERE
	    id = get_user_account_by_id.user_account_id;
$$;
DROP FUNCTION user_account_api.get_user_account_by_name(
	user_name text
);
CREATE FUNCTION user_account_api.get_user_account_by_name(
	user_name text
)
RETURNS SETOF core.user_account
LANGUAGE sql
STABLE
AS $$
	SELECT
	    *
	FROM
		core.user_account
	WHERE
		lower(name) = lower(get_user_account_by_name.user_name);
$$;
DROP FUNCTION user_account_api.list_user_accounts();
CREATE FUNCTION user_account_api.get_user_accounts()
RETURNS SETOF core.user_account
LANGUAGE sql
STABLE
AS $$
	SELECT
	    *
	FROM
	    core.user_account;
$$;
DROP FUNCTION user_account_api.update_time_zone(
	user_account_id bigint,
	time_zone_id bigint
);
CREATE FUNCTION user_account_api.update_time_zone(
	user_account_id bigint,
	time_zone_id bigint
)
RETURNS SETOF core.user_account
LANGUAGE sql
AS $$
	UPDATE
		core.user_account
	SET
		time_zone_id = update_time_zone.time_zone_id
	WHERE
		id = update_time_zone.user_account_id
    RETURNING *;
$$;
/* drop legacy notification functions */
DROP FUNCTION user_account_api.ack_new_reply(
	user_account_id bigint
);
DROP FUNCTION user_account_api.get_latest_unread_reply(
	user_account_id bigint
);
DROP FUNCTION user_account_api.record_new_reply_desktop_notification(
	user_account_id bigint
);
DROP FUNCTION user_account_api.update_contact_preferences(
	user_account_id bigint,
	receive_website_updates boolean,
	receive_suggested_readings boolean
);
DROP FUNCTION user_account_api.update_notification_preferences(
	user_account_id bigint,
	receive_reply_email_notifications boolean,
	receive_reply_desktop_notifications boolean
);
/* drop user_account view */
DROP VIEW user_account_api.user_account;
/* drop existing preferences and notification tracking from user_account */
ALTER TABLE
	core.user_account
DROP COLUMN
	receive_reply_email_notifications;
ALTER TABLE
	core.user_account
DROP COLUMN
	receive_reply_desktop_notifications;
ALTER TABLE
	core.user_account
DROP COLUMN
	last_new_reply_ack;
ALTER TABLE
	core.user_account
DROP COLUMN
	last_new_reply_desktop_notification;
ALTER TABLE
	core.user_account
DROP COLUMN
	receive_website_updates;
ALTER TABLE
	core.user_account
DROP COLUMN
	receive_suggested_readings;
/* add time zone query function */
CREATE FUNCTION core.get_time_zone_by_id(
	id bigint
)
RETURNS SETOF core.time_zone
LANGUAGE sql
STABLE
AS $$
	SELECT
		*
    FROM
    	core.time_zone
    WHERE
    	id = get_time_zone_by_id.id;
$$;
/* add silent_post_id to social.post */
CREATE OR REPLACE VIEW social.post AS (
	SELECT
		comment.article_id,
		comment.user_account_id,
		comment.date_created,
		comment.id AS comment_id,
		comment.text AS comment_text,
	    NULL::bigint AS silent_post_id
	FROM
		core.comment
	WHERE
		comment.parent_comment_id IS NULL
	UNION ALL
	SELECT
		silent_post.article_id,
		silent_post.user_account_id,
		silent_post.date_created,
		NULL::bigint AS comment_id,
		NULL::text AS comment_text,
	    silent_post.id AS silent_post_id
	FROM
		core.silent_post
);
/* build out new notifications objects */
CREATE VIEW notifications.current_preference AS (
	SELECT
	    preference.id,
	    preference.user_account_id,
	    preference.last_modified,
		preference.company_update_via_email,
		preference.aotd_via_email,
		preference.aotd_via_extension,
		preference.aotd_via_push,
	    preference.aotd_digest_via_email,
		preference.reply_via_email,
		preference.reply_via_extension,
		preference.reply_via_push,
		preference.reply_digest_via_email,
		preference.loopback_via_email,
		preference.loopback_via_extension,
		preference.loopback_via_push,
		preference.loopback_digest_via_email,
		preference.post_via_email,
		preference.post_via_extension,
		preference.post_via_push,
		preference.post_digest_via_email,
		preference.follower_via_email,
		preference.follower_via_extension,
		preference.follower_via_push,
		preference.follower_digest_via_email
	FROM
		core.notification_preference AS preference
    	LEFT JOIN notification_preference AS later_preference ON
    		later_preference.user_account_id = preference.user_account_id AND
    		later_preference.last_modified > preference.last_modified
    WHERE
    	later_preference.id IS NULL
);
CREATE FUNCTION notifications.get_preference(
	user_account_id bigint
)
RETURNS SETOF core.notification_preference
LANGUAGE sql
STABLE
AS $$
	SELECT
		*
    FROM
    	notifications.current_preference
    WHERE
    	user_account_id = get_preference.user_account_id;
$$;
CREATE FUNCTION notifications.set_preference(
	user_account_id bigint,
	company_update_via_email bool,
	aotd_via_email bool,
	aotd_via_extension bool,
	aotd_via_push bool,
	aotd_digest_via_email text,
	reply_via_email bool,
	reply_via_extension bool,
	reply_via_push bool,
	reply_digest_via_email text,
	loopback_via_email bool,
	loopback_via_extension bool,
	loopback_via_push bool,
	loopback_digest_via_email text,
	post_via_email bool,
	post_via_extension bool,
	post_via_push bool,
	post_digest_via_email text,
	follower_via_email bool,
	follower_via_extension bool,
	follower_via_push bool,
	follower_digest_via_email text
)
RETURNS SETOF core.notification_preference
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    existing_preference_id bigint;
BEGIN
    -- casting from text to frequency because of poor mapping in api layer
    -- check for an existing record
	SELECT
		preference.id
    INTO
    	locals.existing_preference_id
    FROM
    	core.notification_preference AS preference
    WHERE
    	preference.user_account_id = set_preference.user_account_id AND
    	preference.last_modified >= core.utc_now() - '1 hour'::interval
    ORDER BY
    	preference.last_modified DESC
    LIMIT 1;
    -- update the existing record or create a new one
    IF existing_preference_id IS NOT NULL THEN
        RETURN QUERY
		UPDATE
		    core.notification_preference
        SET
            last_modified = core.utc_now(),
            company_update_via_email = set_preference.company_update_via_email,
			aotd_via_email = set_preference.aotd_via_email,
			aotd_via_extension = set_preference.aotd_via_extension,
			aotd_via_push = set_preference.aotd_via_push,
            aotd_digest_via_email = set_preference.aotd_digest_via_email::core.notification_event_frequency,
			reply_via_email = set_preference.reply_via_email,
			reply_via_extension = set_preference.reply_via_extension,
			reply_via_push = set_preference.reply_via_push,
			reply_digest_via_email = set_preference.reply_digest_via_email::core.notification_event_frequency,
			loopback_via_email = set_preference.loopback_via_email,
			loopback_via_extension = set_preference.loopback_via_extension,
			loopback_via_push = set_preference.loopback_via_push,
			loopback_digest_via_email = set_preference.loopback_digest_via_email::core.notification_event_frequency,
			post_via_email = set_preference.post_via_email,
			post_via_extension = set_preference.post_via_extension,
			post_via_push = set_preference.post_via_push,
			post_digest_via_email = set_preference.post_digest_via_email::core.notification_event_frequency,
			follower_via_email = set_preference.follower_via_email,
			follower_via_extension = set_preference.follower_via_extension,
			follower_via_push = set_preference.follower_via_push,
			follower_digest_via_email = set_preference.follower_digest_via_email::core.notification_event_frequency
        WHERE
        	id = locals.existing_preference_id
        RETURNING *;
	ELSE
	    RETURN QUERY
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
		VALUES (
		    set_preference.user_account_id,
			set_preference.company_update_via_email,
			set_preference.aotd_via_email,
			set_preference.aotd_via_extension,
			set_preference.aotd_via_push,
		    set_preference.aotd_digest_via_email::core.notification_event_frequency,
			set_preference.reply_via_email,
			set_preference.reply_via_extension,
			set_preference.reply_via_push,
			set_preference.reply_digest_via_email::core.notification_event_frequency,
			set_preference.loopback_via_email,
			set_preference.loopback_via_extension,
			set_preference.loopback_via_push,
			set_preference.loopback_digest_via_email::core.notification_event_frequency,
			set_preference.post_via_email,
			set_preference.post_via_extension,
			set_preference.post_via_push,
			set_preference.post_digest_via_email::core.notification_event_frequency,
			set_preference.follower_via_email,
			set_preference.follower_via_extension,
			set_preference.follower_via_push,
			set_preference.follower_digest_via_email::core.notification_event_frequency
		)
		RETURNING *;
    END IF;
END;
$$;
CREATE VIEW notifications.registered_push_device AS (
	SELECT
		id,
	    date_registered,
	    date_unregistered,
	    unregistration_reason,
	    user_account_id,
	    installation_id,
	    name,
	    token
	FROM
		core.notification_push_device
	WHERE
		date_unregistered IS NULL
);
CREATE FUNCTION notifications.register_push_device(
	user_account_id bigint,
	installation_id text,
	name text,
	token text
)
RETURNS SETOF core.notification_push_device
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    existing_device core.notification_push_device;
BEGIN
    -- check for existing registered device with matching installation_id
	SELECT
    	*
	INTO
		locals.existing_device
    FROM
    	notifications.registered_push_device AS device
    WHERE
        device.installation_id = register_push_device.installation_id;
    -- create a new registration if needed
    IF (
    	locals.existing_device IS NULL OR
    	locals.existing_device.user_account_id != register_push_device.user_account_id OR
    	locals.existing_device.token != register_push_device.token
    ) THEN
        -- unregister the existing device if the user or token has changed
        IF locals.existing_device IS NOT NULL THEN
			UPDATE
			    core.notification_push_device
            SET
                date_unregistered = core.utc_now(),
                unregistration_reason = (
                    CASE WHEN locals.existing_device.user_account_id != register_push_device.user_account_id
                        THEN 'user_change'
                        ELSE 'token_change'
                    END
				)
            WHERE
            	id = locals.existing_device.id;
		END IF;
        -- create the registration and return the result
        RETURN QUERY
		INSERT INTO
		    core.notification_push_device (
		        user_account_id,
		        installation_id,
		        name,
				token
		    )
		VALUES (
		    register_push_device.user_account_id,
			register_push_device.installation_id,
			register_push_device.name,
			register_push_device.token
		)
		RETURNING *;
	END IF;
END;
$$;
CREATE FUNCTION notifications.unregister_push_device_by_installation_id(
	installation_id text,
	reason text
)
RETURNS SETOF core.notification_push_device
LANGUAGE sql
AS $$
	UPDATE
		core.notification_push_device AS device
    SET
    	date_unregistered = core.utc_now(),
        unregistration_reason = unregister_push_device_by_installation_id.reason::core.notification_push_unregistration_reason
    WHERE
    	device.installation_id = unregister_push_device_by_installation_id.installation_id AND
        device.date_unregistered IS NULL
    RETURNING *;
$$;
CREATE FUNCTION notifications.unregister_push_device_by_token(
	token text,
	reason text
)
RETURNS SETOF core.notification_push_device
LANGUAGE sql
AS $$
	UPDATE
		core.notification_push_device AS device
    SET
    	date_unregistered = core.utc_now(),
        unregistration_reason = unregister_push_device_by_token.reason::core.notification_push_unregistration_reason
    WHERE
    	device.token = unregister_push_device_by_token.token AND
        device.date_unregistered IS NULL
    RETURNING *;
$$;
CREATE FUNCTION notifications.create_push_auth_denial(
	user_account_id bigint,
    installation_id text,
    device_name text
)
RETURNS SETOF core.notification_push_auth_denial
LANGUAGE sql
AS $$
	INSERT INTO
    	core.notification_push_auth_denial (
    	    user_account_id,
    	    installation_id,
    	    device_name
    	)
    VALUES (
        create_push_auth_denial.user_account_id,
        create_push_auth_denial.installation_id,
        create_push_auth_denial.device_name
	)
	RETURNING *;
$$;
CREATE FUNCTION notifications.get_registered_push_devices(
	user_account_id bigint
)
RETURNS SETOF core.notification_push_device
LANGUAGE sql
STABLE
AS $$
	SELECT
    	*
    FROM
    	notifications.registered_push_device
    WHERE
    	user_account_id = get_registered_push_devices.user_account_id;
$$;
CREATE TYPE notifications.alert_dispatch AS (
	receipt_id bigint,
    via_email bool,
    via_push bool,
    user_account_id bigint,
    user_name text,
    email_address text,
    push_device_tokens text[],
    aotd_alert bool,
    reply_alert_count int,
    loopback_alert_count int,
    post_alert_count int,
    follower_alert_count int
);
CREATE TYPE notifications.post_alert_dispatch AS (
	receipt_id bigint,
    via_email bool,
    via_push bool,
    is_replyable bool,
    user_account_id bigint,
    user_name text,
    email_address text,
    push_device_tokens text[],
    aotd_alert bool,
    reply_alert_count int,
    loopback_alert_count int,
    post_alert_count int,
    follower_alert_count int
);
CREATE TYPE notifications.email_dispatch AS (
	receipt_id bigint,
    user_account_id bigint,
    user_name text,
    email_address text
);
CREATE TYPE notifications.comment_digest_dispatch AS (
	receipt_id bigint,
    user_account_id bigint,
    user_name text,
    email_address text,
    comment_id bigint,
    comment_date_created timestamp,
    comment_text text,
    comment_author text,
    comment_article_id bigint,
    comment_article_title text
);
CREATE TYPE notifications.follower_digest_dispatch AS (
	receipt_id bigint,
    user_account_id bigint,
    user_name text,
    email_address text,
    follower_following_id bigint,
    follower_date_followed timestamp,
    follower_user_name text
);
CREATE TYPE notifications.post_digest_dispatch AS (
	receipt_id bigint,
    user_account_id bigint,
    user_name text,
    email_address text,
    post_comment_id bigint,
    post_silent_post_id bigint,
    post_date_created timestamp,
    post_comment_text text,
    post_author text,
    post_article_id bigint,
    post_article_title text
);
CREATE FUNCTION notifications.create_transactional_notification(
	user_account_id bigint,
	event_type text,
	email_confirmation_id bigint,
	password_reset_request_id bigint
)
RETURNS SETOF notifications.email_dispatch
LANGUAGE sql
AS $$
    WITH transactional_event AS (
		INSERT INTO
			core.notification_event (type)
		VALUES
		    (create_transactional_notification.event_type::core.notification_event_type)
        RETURNING
        	id
	),
    transactional_data AS (
      	INSERT INTO
        	core.notification_data (
        		event_id,
        	    email_confirmation_id,
        	    password_reset_request_id
			)
    	VALUES (
    	    (SELECT id FROM transactional_event),
			create_transactional_notification.email_confirmation_id,
    	    create_transactional_notification.password_reset_request_id
		)
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			(SELECT id FROM transactional_event),
		    create_transactional_notification.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        RETURNING
        	id
	)
    SELECT
        (SELECT id FROM receipt),
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	core.user_account
    WHERE
    	id = create_transactional_notification.user_account_id;
$$;
CREATE FUNCTION notifications.create_company_update_notifications(
	author_id bigint,
	subject text,
	body text
)
RETURNS SETOF notifications.email_dispatch
LANGUAGE sql
AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.company_update_via_email
	),
    update_event AS (
		INSERT INTO
			core.notification_event (
				type,
			    bulk_email_author_id,
			    bulk_email_subject,
			    bulk_email_body
			)
		SELECT
        	'company_update',
		    create_company_update_notifications.author_id,
		    create_company_update_notifications.subject,
		    create_company_update_notifications.body
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			(SELECT id FROM update_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_aotd_notifications(
	article_id bigint
)
RETURNS SETOF notifications.alert_dispatch
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
	-- create the event
	INSERT INTO
		core.notification_event (
			type
		)
	VALUES
		(
			'aotd'
		)
	RETURNING
		id INTO locals.event_id;
	-- create the data
	INSERT INTO
		core.notification_data (
			event_id,
			article_id
		)
	VALUES
		(
			locals.event_id,
			create_aotd_notifications.article_id
		);
	-- set the alert for all users
	UPDATE
		core.user_account
	SET
		aotd_alert = true
	WHERE
		aotd_alert = false;
	-- create receipts and return the dispatches
	RETURN QUERY
	WITH receipt AS (
		INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		(
			SELECT
				locals.event_id,
				preference.user_account_id,
				preference.aotd_via_email,
				preference.aotd_via_extension,
				preference.aotd_via_push
			FROM
				notifications.current_preference AS preference
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_push
	)
	SELECT
		receipt.id,
	    receipt.via_email,
	    receipt.via_push,
		user_account.id,
	    user_account.name::text,
		user_account.email::text,
	    coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
	    user_account.aotd_alert,
	    user_account.reply_alert_count,
	    user_account.loopback_alert_count,
	    user_account.post_alert_count,
	    user_account.follower_alert_count
	FROM
		receipt
		JOIN core.user_account
		    ON user_account.id = receipt.user_account_id
		LEFT JOIN notifications.registered_push_device AS device
			ON device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
	    receipt.via_email,
	    receipt.via_push,
	    user_account.id;
END;
$$;
CREATE FUNCTION notifications.create_aotd_digest_notifications()
RETURNS SETOF notifications.email_dispatch
LANGUAGE sql
AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.aotd_digest_via_email = 'weekly'
	),
    aotd_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	'aotd_digest'
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			(SELECT id FROM aotd_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	),
    aotd_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				article_id
			)
		SELECT
			(SELECT id FROM aotd_event),
			article.id
		FROM
			core.article
		WHERE
			EXISTS (SELECT id FROM aotd_event)
        ORDER BY
        	article.aotd_timestamp DESC NULLS LAST
        LIMIT 7
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_follower_notification(
	following_id bigint,
	follower_id bigint,
	followee_id bigint
)
RETURNS SETOF notifications.alert_dispatch
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
    -- only notify on the first following
    IF (
		(
		    SELECT
		    	count(*)
		    FROM
		    	following
		    WHERE
		        following.follower_user_account_id = create_follower_notification.follower_id AND
		    	following.followee_user_account_id = create_follower_notification.followee_id
		) = 1
	) THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'follower'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		VALUES
			(
				locals.event_id,
				create_follower_notification.following_id
			);
		-- increment the followee's alert count
		UPDATE
			user_account
		SET
			follower_alert_count = follower_alert_count + 1
		WHERE
			id = create_follower_notification.followee_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
			INSERT INTO
				core.notification_receipt (
					event_id,
					user_account_id,
					via_email,
					via_extension,
					via_push
				)
			(
				SELECT
					locals.event_id,
					create_follower_notification.followee_id,
					preference.follower_via_email,
					preference.follower_via_extension,
					preference.follower_via_push
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = create_follower_notification.followee_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
			receipt.via_email,
			receipt.via_push,
			user_account.id,
			user_account.name::text,
			user_account.email::text,
			coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
			user_account.aotd_alert,
			user_account.reply_alert_count,
			user_account.loopback_alert_count,
			user_account.post_alert_count,
			user_account.follower_alert_count
		FROM
			receipt
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
        GROUP BY
        	receipt.id,
            receipt.via_email,
            receipt.via_push,
            user_account.id;
	END IF;
END;
$$;
CREATE FUNCTION notifications.create_follower_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.follower_digest_dispatch
LANGUAGE sql
AS $$
    WITH follower AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
    	    active_following.id AS following_id,
			active_following.date_followed AS date_followed,
    	    follower.name AS user_name
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN social.active_following
    			ON active_following.followee_user_account_id = recipient.id
    		JOIN core.user_account AS follower
    			ON follower.id = active_following.follower_user_account_id
		WHERE
			preference.follower_digest_via_email = create_follower_digest_notifications.frequency::core.notification_event_frequency AND
		    active_following.date_followed >= (
		        CASE create_follower_digest_notifications.frequency
					WHEN 'daily' THEN core.utc_now() - '1 day'::interval
					WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
				END
		    )
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	follower
	),
    follower_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_follower_digest_notifications.frequency
				WHEN 'daily' THEN 'follower_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'follower_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				follower_event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    follower_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		SELECT
			recipient_event.event_id,
			follower.following_id
		FROM
			recipient_event
        	JOIN follower
        		ON follower.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        follower.recipient_id,
        follower.recipient_name,
        follower.recipient_email,
        follower.following_id,
		follower.date_followed,
		follower.user_name
    FROM
    	receipt
        JOIN follower
    		ON follower.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_loopback_notifications(
	article_id bigint,
	comment_id bigint,
	comment_author_id bigint
)
RETURNS SETOF notifications.alert_dispatch
LANGUAGE sql
AS $$
    WITH recipient AS (
        SELECT
			user_article.user_account_id,
		    preference.loopback_via_email,
		    preference.loopback_via_extension,
		    preference.loopback_via_push
		FROM
			core.user_article
			JOIN notifications.current_preference AS preference ON
				preference.user_account_id = user_article.user_account_id
        	LEFT JOIN social.active_following
        		ON (
        		    active_following.follower_user_account_id = user_article.user_account_id AND
        		    active_following.followee_user_account_id = create_loopback_notifications.comment_author_id
        		)
	    WHERE
	    	user_article.article_id = create_loopback_notifications.article_id AND
	        user_article.user_account_id != create_loopback_notifications.comment_author_id AND
	        user_article.date_completed IS NOT NULL AND
	        active_following.id IS NULL
	),
    loopback_event AS (
        INSERT INTO
			core.notification_event (type)
		SELECT
            'loopback'
        WHERE
            EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
    loopback_data AS (
        INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
        	id,
		    create_loopback_notifications.comment_id
        FROM
        	loopback_event
	),
	receipt AS (
		INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		(
			SELECT
				(SELECT id FROM loopback_event),
				recipient.user_account_id,
				recipient.loopback_via_email,
				recipient.loopback_via_extension,
				recipient.loopback_via_push
			FROM
				recipient
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_extension,
		    via_push
	),
    alert_cache AS (
        UPDATE
			core.user_account
		SET
			loopback_alert_count = loopback_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		user_account.id,
		user_account.name::text,
		user_account.email::text,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		user_account.aotd_alert,
		user_account.reply_alert_count,
		user_account.loopback_alert_count,
		user_account.post_alert_count,
		user_account.follower_alert_count
	FROM
		receipt
		JOIN core.user_account ON
			user_account.id = receipt.user_account_id
		LEFT JOIN notifications.registered_push_device AS device ON
			device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		user_account.id;
$$;
CREATE FUNCTION notifications.create_loopback_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.comment_digest_dispatch
LANGUAGE sql
AS $$
    WITH loopback AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        loopback.id AS comment_id,
	        loopback.date_created AS date_created,
	        loopback.text AS comment_text,
	        loopback_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON (
					recipient.id = preference.user_account_id AND
					preference.loopback_digest_via_email = create_loopback_digest_notifications.frequency::core.notification_event_frequency
				)
			JOIN core.user_article
			    ON (
			        user_article.user_account_id = recipient.id AND
			        user_article.date_completed IS NOT NULL
			    )
			JOIN core.article
			    ON article.id = user_article.article_id
			JOIN core.comment AS loopback
			    ON (
					loopback.article_id = article.id AND
					loopback.user_account_id != recipient.id AND
					loopback.parent_comment_id IS NULL AND
					loopback.date_created >= (
						CASE create_loopback_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
					)
				)
			JOIN core.user_account AS loopback_author
			    ON loopback_author.id = loopback.user_account_id
			LEFT JOIN social.active_following
			    ON (
					active_following.follower_user_account_id = recipient.id AND
					active_following.followee_user_account_id = loopback_author.id
				)
		WHERE
		    active_following.id IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	loopback
	),
    loopback_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_loopback_digest_notifications.frequency
				WHEN 'daily' THEN 'loopback_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'loopback_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				loopback_event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    loopback_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			loopback.comment_id
		FROM
			recipient_event
        	JOIN loopback
        		ON loopback.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        loopback.recipient_id,
        loopback.recipient_name,
        loopback.recipient_email,
        loopback.comment_id,
		loopback.date_created,
		loopback.comment_text,
		loopback.author,
        loopback.article_id,
        loopback.article_title
    FROM
    	receipt
        JOIN loopback
    		ON loopback.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_post_notifications(
	article_id bigint,
	poster_id bigint,
	comment_id bigint,
	silent_post_id bigint
)
RETURNS SETOF notifications.post_alert_dispatch
LANGUAGE sql
AS $$
    WITH recipient AS (
        SELECT
			following.follower_user_account_id AS user_account_id,
		    preference.post_via_email,
		    preference.post_via_extension,
		    preference.post_via_push
		FROM
			social.active_following AS following
			JOIN notifications.current_preference AS preference
			    ON (
					following.follower_user_account_id = preference.user_account_id AND
					following.followee_user_account_id = create_post_notifications.poster_id
				)
	),
    post_event AS (
        INSERT INTO
			core.notification_event (type)
		SELECT
            'post'
        WHERE
            EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
    post_data AS (
        INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
        	id,
		    create_post_notifications.comment_id,
		    create_post_notifications.silent_post_id
        FROM
        	post_event
	),
	receipt AS (
		INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		(
			SELECT
				(SELECT id FROM post_event),
				recipient.user_account_id,
				recipient.post_via_email,
				recipient.post_via_extension,
				recipient.post_via_push
			FROM
				recipient
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_extension,
		    via_push
	),
    alert_cache AS (
        UPDATE
			core.user_account
		SET
			post_alert_count = post_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
	    user_article.date_completed IS NOT NULL AS is_replyable,
		user_account.id,
		user_account.name::text,
		user_account.email::text,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		user_account.aotd_alert,
		user_account.reply_alert_count,
		user_account.loopback_alert_count,
		user_account.post_alert_count,
		user_account.follower_alert_count
	FROM
		receipt
		JOIN core.user_account
			ON user_account.id = receipt.user_account_id
		LEFT JOIN core.user_article
		    ON (
		        user_article.user_account_id = user_account.id AND
		        user_article.article_id = create_post_notifications.article_id
		    )
		LEFT JOIN notifications.registered_push_device AS device
			ON device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		user_account.id,
	    user_article.date_completed;
$$;
CREATE FUNCTION notifications.create_post_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.post_digest_dispatch
LANGUAGE sql
AS $$
    WITH post AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        post.comment_id AS comment_id,
    	    post.silent_post_id AS silent_post_id,
	        post.date_created AS date_created,
	        post.comment_text AS comment_text,
	        post_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN social.active_following
			    ON active_following.follower_user_account_id = preference.user_account_id
			JOIN social.post
			    ON post.user_account_id = active_following.followee_user_account_id
			JOIN core.article
			    ON article.id = post.article_id
	    	JOIN core.user_account AS post_author
	    		ON post_author.id = post.user_account_id
		WHERE
			preference.post_digest_via_email = create_post_digest_notifications.frequency::core.notification_event_frequency AND
		    post.date_created >= (
		        CASE create_post_digest_notifications.frequency
					WHEN 'daily' THEN core.utc_now() - '1 day'::interval
					WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
				END
		    )
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	post
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	 CASE create_post_digest_notifications.frequency
				WHEN 'daily' THEN 'post_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'post_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
			recipient_event.event_id,
			post.comment_id,
		    post.silent_post_id
		FROM
			recipient_event
        	JOIN post
        		ON post.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        post.recipient_id,
        post.recipient_name,
        post.recipient_email,
        post.comment_id,
        post.silent_post_id,
		post.date_created,
		post.comment_text,
		post.author,
        post.article_id,
        post.article_title
    FROM
    	receipt
        JOIN post
    		ON post.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.create_reply_notification(
	reply_id bigint,
	reply_author_id bigint,
	parent_id bigint
)
RETURNS SETOF notifications.alert_dispatch
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    parent_author_id bigint;
    event_id bigint;
BEGIN
    -- lookup the parent author
    SELECT
    	user_account_id
    INTO
        locals.parent_author_id
    FROM
    	core.comment
    WHERE
    	id = parent_id;
    -- check for a self-reply
    IF create_reply_notification.reply_author_id != locals.parent_author_id THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'reply'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		VALUES
			(
				locals.event_id,
				create_reply_notification.reply_id
			);
		-- increment the parent's alert count
		UPDATE
			user_account
		SET
			reply_alert_count = reply_alert_count + 1
		WHERE
			id = locals.parent_author_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
			INSERT INTO
				core.notification_receipt (
					event_id,
					user_account_id,
					via_email,
					via_extension,
					via_push
				)
			(
				SELECT
					locals.event_id,
					locals.parent_author_id,
					preference.reply_via_email,
					preference.reply_via_extension,
					preference.reply_via_push
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = locals.parent_author_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
			user_account.id,
		    user_account.name::text,
			user_account.email::text,
		    coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
			user_account.aotd_alert,
			user_account.reply_alert_count,
			user_account.loopback_alert_count,
			user_account.post_alert_count,
			user_account.follower_alert_count
		FROM
			receipt
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
		GROUP BY
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
		    user_account.id;
	END IF;
END;
$$;
CREATE FUNCTION notifications.create_reply_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.comment_digest_dispatch
LANGUAGE sql
AS $$
    WITH reply AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        reply.id AS comment_id,
	        reply.date_created AS comment_date_created,
	        reply.text AS comment_text,
	        reply_author.name AS comment_author_name,
    	    article.id AS comment_article_id,
    	    article.title AS comment_article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN core.comment
			    ON comment.user_account_id = preference.user_account_id
	    	JOIN core.comment AS reply
	    		ON (
	    		    reply.parent_comment_id = comment.id AND
	    		    reply.user_account_id != preference.user_account_id AND
	    		    reply.date_created >= CASE create_reply_digest_notifications.frequency
						WHEN 'daily' THEN core.utc_now() - '1 day'::interval
						WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
					END
	    		)
			JOIN core.article
			    ON article.id = reply.article_id
	    	JOIN core.user_account AS reply_author
	    		ON reply_author.id = reply.user_account_id
		WHERE
			preference.reply_digest_via_email = create_reply_digest_notifications.frequency::core.notification_event_frequency
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	reply
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_reply_digest_notifications.frequency
				WHEN 'daily' THEN 'reply_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'reply_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
	),
    receipt AS (
        INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			reply.comment_id
		FROM
			recipient_event
        	JOIN reply
        		ON reply.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        reply.recipient_id,
        reply.recipient_name,
        reply.recipient_email,
        reply.comment_id,
		reply.comment_date_created,
		reply.comment_text,
		reply.comment_author_name,
        reply.comment_article_id,
        reply.comment_article_title
    FROM
    	receipt
        JOIN reply
    		ON reply.recipient_id = receipt.user_account_id;
$$;
CREATE FUNCTION notifications.clear_alert(
	receipt_id bigint
)
RETURNS SETOF core.notification_receipt
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    cleared_receipt core.notification_receipt;
BEGIN
    -- clear the alert only if it hasn't be cleared yet
    UPDATE
    	core.notification_receipt AS receipt
    SET
    	date_alert_cleared = core.utc_now()
    WHERE
    	receipt.id = clear_alert.receipt_id AND
    	receipt.date_alert_cleared IS NULL
    RETURNING
        * INTO locals.cleared_receipt;
    -- if the alert was cleared then decrement the cached counts on user_account
    IF locals.cleared_receipt IS NOT NULL THEN
		CASE (
			SELECT
				type
			FROM
				core.notification_event
			WHERE
				id = locals.cleared_receipt.event_id
		)
			WHEN 'aotd' THEN
				UPDATE
					core.user_account
				SET
					aotd_alert = false
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'reply' THEN
				UPDATE
					core.user_account
				SET
					reply_alert_count = greatest(reply_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'loopback' THEN
				UPDATE
					core.user_account
				SET
					loopback_alert_count = greatest(loopback_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'post' THEN
				UPDATE
					core.user_account
				SET
					post_alert_count = greatest(post_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			WHEN 'follower' THEN
				UPDATE
					core.user_account
				SET
					follower_alert_count = greatest(follower_alert_count - 1, 0)
				WHERE
					id = locals.cleared_receipt.user_account_id;
			ELSE
				-- suppress CASE_NOT_FOUND exception
		END CASE;
	END IF;
    -- return the cleared receipt
    RETURN NEXT locals.cleared_receipt;
END;
$$;
CREATE FUNCTION notifications.clear_aotd_alert(
	user_account_id bigint
)
RETURNS SETOF core.notification_receipt
LANGUAGE plpgsql
AS $$
BEGIN
    -- set the cached user_account alert flag to false
	UPDATE
	    core.user_account
    SET
        aotd_alert = false
    WHERE
    	id = clear_aotd_alert.user_account_id;
    -- clear the latest aotd alert only if it hasn't been cleared yet
	RETURN QUERY
    UPDATE
        core.notification_receipt
    SET
        date_alert_cleared = core.utc_now()
    WHERE
    	id = (
    	    SELECT
    	    	CASE WHEN receipt.date_alert_cleared IS NULL
    	    		THEN receipt.id
    	    		ELSE NULL
    	    	END
    	    FROM
    	    	core.notification_receipt AS receipt
    	    	JOIN core.notification_event ON
    	    		notification_event.id = receipt.event_id
    	    WHERE
    	    	notification_event.type = 'aotd' AND
    	        receipt.user_account_id = clear_aotd_alert.user_account_id
    	    ORDER BY
    	    	notification_event.date_created DESC
    	    LIMIT
    	    	1
		)
    RETURNING *;
END;
$$;
CREATE FUNCTION notifications.clear_all_alerts(
	type text,
	user_account_id bigint
)
RETURNS SETOF core.notification_receipt
LANGUAGE plpgsql
AS $$
BEGIN
    -- reset cached alert counters
    CASE clear_all_alerts.type
        WHEN 'reply' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    reply_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'loopback' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    loopback_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'post' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    post_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
        WHEN 'follower' THEN
        	UPDATE
        	    core.user_account
        	SET
        	    follower_alert_count = 0
        	WHERE
        		id = clear_all_alerts.user_account_id;
    END CASE;
    -- clear all uncleared alerts of the specified type
    RETURN QUERY
    UPDATE
    	core.notification_receipt
    SET
    	date_alert_cleared = core.utc_now()
    FROM
    	core.notification_event
    WHERE
    	notification_receipt.event_id = notification_event.id AND
        notification_event.type = clear_all_alerts.type::core.notification_event_type AND
        notification_receipt.user_account_id = clear_all_alerts.user_account_id AND
    	notification_receipt.date_alert_cleared IS NULL
    RETURNING
        notification_receipt.*;
END;
$$;
CREATE FUNCTION notifications.create_interaction(
	receipt_id bigint,
	channel text,
	action text,
	url text,
	reply_id bigint
)
RETURNS SETOF core.notification_interaction
LANGUAGE sql
AS $$
	INSERT INTO
    	core.notification_interaction (
			receipt_id,
    	    channel,
    	    action,
    	    url,
    	    reply_id
		)
	VALUES
    	(
			create_interaction.receipt_id,
			create_interaction.channel::core.notification_channel,
			create_interaction.action::core.notification_action,
			create_interaction.url,
			create_interaction.reply_id
		)
	RETURNING *;
$$;
CREATE VIEW notifications.notification AS (
    SELECT
        event.id AS event_id,
		event.date_created,
        event.type AS event_type,
        coalesce(
        	array_agg(data.article_id) FILTER (WHERE data.article_id IS NOT NULL),
        	'{}'
        ) AS article_ids,
        coalesce(
			array_agg(data.comment_id) FILTER (WHERE data.comment_id IS NOT NULL),
			'{}'
		) AS comment_ids,
        coalesce(
            array_agg(data.silent_post_id) FILTER (WHERE data.silent_post_id IS NOT NULL),
            '{}'
        ) AS silent_post_ids,
        coalesce(
            array_agg(data.following_id) FILTER (WHERE data.following_id IS NOT NULL),
            '{}'
        ) AS following_ids,
        receipt.id AS receipt_id,
        receipt.user_account_id,
        receipt.date_alert_cleared,
        receipt.via_email,
        receipt.via_extension,
        receipt.via_push
    FROM
    	core.notification_event AS event
    	JOIN core.notification_receipt AS receipt ON
    		receipt.event_id = event.id
    	LEFT JOIN core.notification_data AS data ON
    		data.event_id = event.id
	GROUP BY
    	event.id, receipt.id
);
CREATE FUNCTION notifications.get_notification(
	receipt_id bigint
)
RETURNS SETOF notifications.notification
LANGUAGE sql
STABLE
AS $$
    SELECT
		*
    FROM
    	notifications.notification
	WHERE
		notification.receipt_id = get_notification.receipt_id;
$$;
CREATE FUNCTION notifications.get_notifications(
	receipt_ids bigint[]
)
RETURNS SETOF notifications.notification
LANGUAGE sql
STABLE
AS $$
    SELECT
		*
    FROM
    	notifications.notification
	WHERE
		notification.receipt_id = ANY (get_notifications.receipt_ids);
$$;
CREATE FUNCTION notifications.get_extension_notifications(
	user_account_id bigint,
	since_date timestamp,
	excluded_receipt_ids bigint[]
)
RETURNS SETOF notifications.notification
LANGUAGE sql
STABLE
AS $$
    SELECT
    	*
    FROM
    	notifications.notification
    WHERE
    	notification.user_account_id = get_extension_notifications.user_account_id AND
        notification.via_extension AND
        notification.date_created >= get_extension_notifications.since_date AND
        notification.date_alert_cleared IS NULL AND
    	NOT notification.receipt_id = ANY (get_extension_notifications.excluded_receipt_ids);
$$;
-- refactor get_aotd to accept limit
DROP FUNCTION community_reads.get_aotd(user_account_id bigint);
CREATE FUNCTION community_reads.get_aotds(
	user_account_id bigint,
	day_count int
)
RETURNS SETOF article_api.article
LANGUAGE sql
STABLE
AS $$
	SELECT *
	FROM article_api.get_articles(
		user_account_id,
		VARIADIC ARRAY(
			SELECT id
			FROM article
			ORDER BY aotd_timestamp DESC NULLS LAST
			LIMIT get_aotds.day_count
		)
	);
$$;
-- refactor set_aotd to return article
DROP FUNCTION community_reads.set_aotd();
CREATE FUNCTION community_reads.set_aotd()
RETURNS SETOF article_api.article
LANGUAGE sql
AS $$
    WITH aotd AS (
    	UPDATE
			core.article
		SET
			aotd_timestamp = core.utc_now()
		WHERE
			id = (
    			SELECT
					id
				FROM
					community_reads.community_read
				WHERE
					aotd_timestamp IS NULL AND
					core.matches_article_length(word_count, 5, NULL)
				ORDER BY
					hot_score DESC
				LIMIT
					1
			)
    	RETURNING
    		id
    )
    SELECT
    	*
    FROM
    	article_api.get_article(
    		article_id => (
    			SELECT
    				id
    			FROM
    				aotd
    		),
    		user_account_id => NULL
		);
$$;
-- social refactor
-- refactor followers to use new type and include has_alert
DROP FUNCTION social.get_followers(
	viewer_user_id bigint,
	subject_user_name text
);
DROP TYPE social.following;
CREATE TYPE social.follower AS (
	user_name text,
    is_followed boolean,
    has_alert boolean
);
CREATE FUNCTION social.get_followers(
	viewer_user_id bigint,
	subject_user_name text
)
RETURNS SETOF social.follower
LANGUAGE sql
STABLE
AS $$
	SELECT
		follower.name AS user_name,
	   	viewer_following.id IS NOT NULL AS is_followed,
		alert.following_id IS NOT NULL AS has_alert
	FROM
		social.active_following AS subject_following
		JOIN core.user_account AS follower ON follower.id = subject_following.follower_user_account_id
		LEFT JOIN social.active_following AS viewer_following ON (
			viewer_following.follower_user_account_id = get_followers.viewer_user_id AND
			viewer_following.followee_user_account_id = follower.id
		)
		LEFT JOIN (
			SELECT
				notification_data.following_id
		 	FROM
		    	notification_event
		    	JOIN notification_data
		    	    ON (
						notification_event.type = 'follower' AND
						notification_data.event_id = notification_event.id
					)
		    	JOIN notification_receipt AS receipt
		    		ON (
		    		    receipt.event_id = notification_event.id AND
		    		    receipt.user_account_id = get_followers.viewer_user_id AND
						receipt.date_alert_cleared IS NULL
					)
		) AS alert
			ON alert.following_id = subject_following.id
    WHERE
        subject_following.followee_user_account_id = user_account_api.get_user_account_id_by_name(get_followers.subject_user_name)
    ORDER BY
    	subject_following.date_followed DESC;
$$;
-- refactor get_followees to order by date like get_followers
CREATE OR REPLACE FUNCTION social.get_followees(
	user_account_id bigint
)
RETURNS SETOF text
LANGUAGE sql
STABLE
AS $$
    SELECT
    	followee.name
    FROM
    	social.active_following
    	LEFT JOIN user_account AS followee ON followee.id = active_following.followee_user_account_id
    WHERE
    	active_following.follower_user_account_id = get_followees.user_account_id
    ORDER BY
    	active_following.date_followed DESC;
$$;
-- update create_following to return inserted row
DROP FUNCTION social.create_following(
	follower_user_id bigint,
	followee_user_name text,
	analytics text
);
CREATE FUNCTION social.create_following(
	follower_user_id bigint,
	followee_user_name text,
	analytics text
)
RETURNS SETOF core.following
LANGUAGE sql
AS $$
	INSERT INTO core.following
	    (
	    	follower_user_account_id,
	     	followee_user_account_id,
	     	follow_analytics
	    )
	VALUES
    	(
    		create_following.follower_user_id,
    	 	user_account_api.get_user_account_id_by_name(create_following.followee_user_name),
    	 	create_following.analytics::jsonb
		)
	RETURNING *;
$$;
-- add get_following
CREATE FUNCTION social.get_following(
	following_id bigint
)
RETURNS SETOF core.following
LANGUAGE sql
STABLE
AS $$
    SELECT
    	*
    FROM
    	core.following
    WHERE
    	id = get_following.following_id;
$$;
-- add silent_post_id and has_alert to article_post_page_result
DROP FUNCTION social.get_posts_from_followees(user_id bigint, page_number integer, page_size integer, min_length integer, max_length integer);
DROP FUNCTION social.get_posts_from_user(viewer_user_id bigint, subject_user_name text, page_size integer, page_number integer);
DROP TYPE social.article_post_page_result;
CREATE TYPE social.article_post_page_result AS (
	id bigint,
	title text,
	slug text,
	source text,
	date_published timestamp without time zone,
	section text,
	description text,
	aotd_timestamp timestamp without time zone,
	url text,
	authors text[],
	tags text[],
	word_count bigint,
	comment_count bigint,
	read_count bigint,
	date_created timestamp without time zone,
	percent_complete double precision,
	is_read boolean,
	date_starred timestamp without time zone,
	average_rating_score numeric,
	rating_score core.rating_score,
	date_posted timestamp without time zone,
	post_date_created timestamp without time zone,
	user_name text,
	comment_id bigint,
	comment_text text,
    silent_post_id bigint,
    has_alert boolean,
	total_count bigint
);
CREATE FUNCTION social.get_posts_from_followees(
	user_id bigint,
	page_number integer,
	page_size integer,
	min_length integer,
	max_length integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH followee_post AS (
	    SELECT
	    	post.article_id,
	        post.user_account_id,
	        post.date_created,
	        post.comment_id,
	        post.comment_text,
	        post.silent_post_id
	    FROM
	    	social.post
	    	JOIN core.article ON article.id = post.article_id
	    	JOIN social.active_following ON active_following.followee_user_account_id = post.user_account_id
	    WHERE
	    	active_following.follower_user_account_id = get_posts_from_followees.user_id AND
	        core.matches_article_length(
				article.word_count,
				get_posts_from_followees.min_length,
				get_posts_from_followees.max_length
			)
	),
	paginated_post AS (
	    SELECT
	    	*
	    FROM
	    	followee_post
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_followees.page_number - 1) * get_posts_from_followees.page_size
		LIMIT
			get_posts_from_followees.page_size
	)
    SELECT
		article.*,
		paginated_post.date_created AS post_date_created,
		user_account.name AS user_name,
		paginated_post.comment_id,
		paginated_post.comment_text,
        paginated_post.silent_post_id,
		(
			alert.comment_id IS NOT NULL OR
			alert.silent_post_id IS NOT NULL
		) AS has_alert,
		(
		    SELECT
		    	count(*)
		    FROM
		        followee_post
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_followees.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    paginated_post
			)
		) AS article
		JOIN paginated_post ON paginated_post.article_id = article.id
		JOIN user_account ON user_account.id = paginated_post.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id,
		        data.silent_post_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt ON notification_receipt.event_id = event.id
		    	JOIN notification_data AS data ON data.event_id = event.id
		    WHERE
		    	event.type = 'post' AND
		        notification_receipt.user_account_id = get_posts_from_followees.user_id AND
		        notification_receipt.date_alert_cleared IS NULL AND
		        (
		            data.comment_id IN (
						SELECT
							comment_id
						FROM
							paginated_post
					) OR
		            data.silent_post_id IN (
						SELECT
							silent_post_id
						FROM
							paginated_post
					)
		        )
		) AS alert ON (
		    alert.comment_id = paginated_post.comment_id OR
		    alert.silent_post_id = paginated_post.silent_post_id
		)
    ORDER BY
    	paginated_post.date_created DESC
$$;
CREATE FUNCTION social.get_posts_from_user(
	viewer_user_id bigint,
	subject_user_name text,
	page_size integer,
	page_number integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
    WITH subject_user_account AS (
        SELECT
        	id
        FROM
        	user_account_api.get_user_account_id_by_name(get_posts_from_user.subject_user_name) AS user_account (id)
	),
	user_post AS (
	    SELECT
	    	post.article_id,
	        post.user_account_id,
	        post.date_created,
	        post.comment_id,
	        post.comment_text,
	        post.silent_post_id
	    FROM
	    	social.post
	    WHERE
	    	user_account_id = (
	    		SELECT
	    		    id
	    		FROM
	    			subject_user_account
	    	)
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_user.page_number - 1) * get_posts_from_user.page_size
		LIMIT
			get_posts_from_user.page_size
	)
    SELECT
		article.*,
		user_post.date_created AS post_date_created,
		(
		    SELECT
		    	name
		    FROM
		        user_account
		    WHERE
		    	id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		) AS user_name,
		user_post.comment_id AS comment_id,
		user_post.comment_text AS comment_text,
        user_post.silent_post_id,
        FALSE AS has_alert,
		(
		    SELECT
		    	count(*)
		    FROM
		        social.post
		    WHERE
		    	user_account_id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_user.viewer_user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    user_post
			)
		) AS article
		JOIN user_post ON user_post.article_id = article.id
    ORDER BY
    	user_post.date_created DESC
$$;
---- create social.get_inbox for post notifications
CREATE FUNCTION social.get_posts_from_inbox(
	user_id bigint,
	page_number integer,
	page_size integer
)
RETURNS SETOF social.article_post_page_result
LANGUAGE sql
STABLE
AS $$
	WITH inbox_comment AS (
	    SELECT
	    	reply.id,
	        reply.date_created,
	        reply.text,
	        reply.article_id,
	        reply.user_account_id
	    FROM
	    	core.comment
	    	JOIN core.comment AS reply ON reply.parent_comment_id = comment.id
	    WHERE
	    	comment.user_account_id = get_posts_from_inbox.user_id AND
	        reply.user_account_id != get_posts_from_inbox.user_id
	    UNION ALL
	    SELECT
	    	comment.id,
	        comment.date_created,
	        comment.text,
	        comment.article_id,
	        comment.user_account_id
	    FROM
	    	core.user_article
	    	JOIN core.comment ON comment.article_id = user_article.article_id
	    WHERE
	    	user_article.user_account_id = get_posts_from_inbox.user_id AND
	    	user_article.date_completed IS NOT NULL AND
	        comment.user_account_id != get_posts_from_inbox.user_id AND
	        comment.parent_comment_id IS NULL AND
	        comment.date_created > user_article.date_completed
	),
	paginated_inbox_comment AS (
	    SELECT
	    	*
	    FROM
	    	inbox_comment
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_inbox.page_number - 1) * get_posts_from_inbox.page_size
		LIMIT
			get_posts_from_inbox.page_size
	)
    SELECT
		article.*,
		paginated_inbox_comment.date_created AS post_date_created,
		user_account.name AS user_name,
		paginated_inbox_comment.id AS comment_id,
		paginated_inbox_comment.text AS comment_text,
        NULL::bigint AS silent_post_id,
        alert.comment_id IS NOT NULL AS has_alert,
		(
		    SELECT
		    	count(*)
		    FROM
		        inbox_comment
		) AS total_count
	FROM
		article_api.get_articles(
			get_posts_from_inbox.user_id,
			VARIADIC ARRAY(
				SELECT
				    DISTINCT article_id
				FROM
				    paginated_inbox_comment
			)
		) AS article
		JOIN paginated_inbox_comment ON paginated_inbox_comment.article_id = article.id
		JOIN user_account ON user_account.id = paginated_inbox_comment.user_account_id
		LEFT JOIN (
		    SELECT
				data.comment_id
		    FROM
		    	notification_event AS event
		    	JOIN notification_receipt ON notification_receipt.event_id = event.id
		    	JOIN notification_data AS data ON data.event_id = event.id
		    WHERE
		    	(
		    	    event.type = 'reply' OR
		    	    event.type = 'loopback'
		    	) AND
		        notification_receipt.user_account_id = get_posts_from_inbox.user_id AND
		        notification_receipt.date_alert_cleared IS NULL AND
				data.comment_id IN (
					SELECT
						id
					FROM
						paginated_inbox_comment
				)
		) AS alert ON alert.comment_id = paginated_inbox_comment.id
    ORDER BY
    	paginated_inbox_comment.date_created DESC
$$;
-- create social.get_silent_post
CREATE FUNCTION social.get_silent_post(
	id bigint
)
RETURNS SETOF core.silent_post
LANGUAGE sql
STABLE
AS $$
	SELECT
		*
    FROM
    	core.silent_post
	WHERE
    	id = get_silent_post.id;
$$;