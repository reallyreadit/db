-- update user_account
CREATE TYPE user_account_role AS ENUM ('regular', 'admin');
ALTER TABLE user_account ADD COLUMN role user_account_role NOT NULL DEFAULT 'regular';
ALTER TABLE user_account ADD COLUMN receive_website_updates boolean NULL DEFAULT TRUE;
ALTER TABLE user_account ADD COLUMN receive_suggested_readings boolean NULL DEFAULT TRUE;
-- set admin users
UPDATE user_account SET role = 'admin' WHERE name IN ('bill', 'jeff');
-- update user_account_api.user_account
DROP FUNCTION user_account_api.create_user_account(
	name 			text,
	email 			text,
	password_hash	bytea,
	password_salt	bytea
);
DROP FUNCTION user_account_api.find_user_account(email text);
DROP FUNCTION user_account_api.get_user_account(user_account_id uuid);
DROP FUNCTION user_account_api.update_notification_preferences(
	user_account_id uuid,
	receive_reply_email_notifications boolean,
	receive_reply_desktop_notifications boolean
);
DROP VIEW user_account_api.user_account;
CREATE VIEW user_account_api.user_account AS SELECT
	user_account.id,
	user_account.name,
	user_account.email,
	user_account.password_hash,
	user_account.password_salt,
	user_account.receive_reply_email_notifications,
	user_account.receive_reply_desktop_notifications,
	user_account.last_new_reply_ack,
	user_account.last_new_reply_desktop_notification,
	user_account.date_created,
	user_account.role,
	user_account.receive_website_updates,
	user_account.receive_suggested_readings,
	ec.date_confirmed IS NOT NULL AS is_email_confirmed
	FROM user_account
	LEFT JOIN email_confirmation ec ON ec.user_account_id = user_account.id
	LEFT JOIN email_confirmation ec1 ON ec1.user_account_id = user_account.id AND ec1.date_created > ec.date_created
	WHERE ec1.id IS NULL;
CREATE FUNCTION user_account_api.create_user_account(
	name 			text,
	email 			text,
	password_hash	bytea,
	password_salt	bytea
) RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql AS $func$
DECLARE
	user_account_id uuid;
BEGIN
	INSERT INTO user_account (name, email, password_hash, password_salt)
		VALUES (trim(name), trim(email), password_hash, password_salt)
		RETURNING id INTO user_account_id;
	RETURN QUERY SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE id = user_account_id;
END;
$func$;
CREATE FUNCTION user_account_api.find_user_account(email text) RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE lower(email) = lower(find_user_account.email);
$func$;
CREATE FUNCTION user_account_api.get_user_account(user_account_id uuid) RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE id = user_account_id;
$func$;
CREATE FUNCTION user_account_api.update_notification_preferences(
	user_account_id uuid,
	receive_reply_email_notifications boolean,
	receive_reply_desktop_notifications boolean
) RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql AS $func$
BEGIN
	UPDATE user_account SET
			receive_reply_email_notifications = update_notification_preferences.receive_reply_email_notifications,
			receive_reply_desktop_notifications = update_notification_preferences.receive_reply_desktop_notifications
		WHERE id = user_account_id;
	RETURN QUERY SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE id = user_account_id;
END;
$func$;
-- add user_account_api.update_contact_preferences.sql
CREATE FUNCTION user_account_api.update_contact_preferences(
	user_account_id uuid,
	receive_website_updates boolean,
	receive_suggested_readings boolean
) RETURNS SETOF user_account_api.user_account
LANGUAGE plpgsql AS $func$
BEGIN
	UPDATE user_account SET
			receive_website_updates = update_contact_preferences.receive_website_updates,
			receive_suggested_readings = update_contact_preferences.receive_suggested_readings
		WHERE id = user_account_id;
	RETURN QUERY SELECT
		user_account.id,
		user_account.name,
		user_account.email,
		user_account.password_hash,
		user_account.password_salt,
		user_account.receive_reply_email_notifications,
		user_account.receive_reply_desktop_notifications,
		user_account.last_new_reply_ack,
		user_account.last_new_reply_desktop_notification,
		user_account.date_created,
		user_account.role,
		user_account.receive_website_updates,
		user_account.receive_suggested_readings,
		user_account.is_email_confirmed
		FROM user_account_api.user_account WHERE id = user_account_id;
END;
$func$;
-- add bulk_mailing.sql
CREATE TABLE bulk_mailing (
	id 					uuid		PRIMARY KEY	DEFAULT pgcrypto.gen_random_uuid(),
	date_sent			timestamp	NOT NULL	DEFAULT utc_now(),
	subject				text		NOT NULL,
	body				text		NOT NULL,
	list				text		NOT NULL,
	user_account_id		uuid		NOT NULL	REFERENCES user_account
);
-- add bulk_mailing_recipient.sql
CREATE TABLE bulk_mailing_recipient (
	bulk_mailing_id	uuid	NOT NULL	REFERENCES bulk_mailing,
	user_account_id	uuid	NOT NULL	REFERENCES user_account,
	PRIMARY KEY(bulk_mailing_id, user_account_id)
);
-- add user_account_api.create_bulk_mailing.sql
CREATE FUNCTION user_account_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipient_ids uuid[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	bulk_mailing_id	uuid;
	recipient_id	uuid;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOREACH recipient_id IN ARRAY recipient_ids
	LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id)
			VALUES (bulk_mailing_id, recipient_id);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$func$;
-- add user_account_api.list_bulk_mailings.sql
CREATE FUNCTION user_account_api.list_bulk_mailings() RETURNS TABLE(
	id uuid,
	date_sent timestamp,
	subject text,
	body text,
	list text,
	user_account text,
	recipient_count bigint
)
LANGUAGE SQL AS $func$
	SELECT
		bulk_mailing.id,
		bulk_mailing.date_sent,
		bulk_mailing.subject,
		bulk_mailing.body,
		bulk_mailing.list,
		user_account.name AS user_account,
		count(*) AS recipient_count
		FROM bulk_mailing
		JOIN user_account ON bulk_mailing.user_account_id = user_account.id
		JOIN bulk_mailing_recipient ON bulk_mailing.id = bulk_mailing_recipient.bulk_mailing_id
		GROUP BY bulk_mailing.id, user_account.id;
$func$;
-- add user_account_api.list_user_accounts.sql
CREATE FUNCTION user_account_api.list_user_accounts() RETURNS SETOF user_account_api.user_account
LANGUAGE SQL AS $func$
	SELECT
		id,
		name,
		email,
		password_hash,
		password_salt,
		receive_reply_email_notifications,
		receive_reply_desktop_notifications,
		last_new_reply_ack,
		last_new_reply_desktop_notification,
		date_created,
		role,
		receive_website_updates,
		receive_suggested_readings,
		is_email_confirmed
		FROM user_account_api.user_account;
$func$;