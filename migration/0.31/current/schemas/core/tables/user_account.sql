CREATE TABLE user_account (
	id 									bigserial			PRIMARY KEY,
	name								varchar(30)			NOT NULL,
		CONSTRAINT user_account_name_valid CHECK (name SIMILAR TO '[A-Za-z0-9\-_]+'),
	email								varchar(256)		NOT NULL
		CONSTRAINT user_account_email_valid CHECK (email LIKE '%@%'),
	password_hash						bytea				NOT NULL,
	password_salt						bytea				NOT NULL,
	receive_reply_email_notifications	boolean				NOT NULL DEFAULT TRUE,
	receive_reply_desktop_notifications	boolean				NOT NULL DEFAULT TRUE,
	last_new_reply_ack					timestamp			NOT NULL DEFAULT utc_now(),
	last_new_reply_desktop_notification	timestamp			NOT NULL DEFAULT utc_now(),
	date_created						timestamp			NOT NULL DEFAULT utc_now(),
	role								user_account_role	NOT NULL DEFAULT 'regular',
	receive_website_updates				boolean				NOT NULL DEFAULT TRUE,
	receive_suggested_readings			boolean				NOT NULL DEFAULT TRUE
);
CREATE UNIQUE INDEX user_account_name_key ON user_account (lower(name));
CREATE UNIQUE INDEX user_account_email_key ON user_account (lower(email));