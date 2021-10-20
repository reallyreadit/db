/**
	Add filters to company update emails.
 */

-- Refactor subscriptions.is_user_subscribed_or_free_for_life into two different functions.
CREATE FUNCTION
	subscriptions.is_user_subscribed(
		user_account core.user_account,
		as_of_date timestamp
	)
RETURNS
	boolean
LANGUAGE
	sql
IMMUTABLE
AS $$
	SELECT
		is_user_subscribed.user_account.subscription_end_date IS NOT NULL AND
		is_user_subscribed.user_account.subscription_end_date > is_user_subscribed.as_of_date;
$$;

CREATE FUNCTION
	subscriptions.is_user_free_for_life(
		user_account core.user_account
	)
RETURNS
	boolean
LANGUAGE
	sql
IMMUTABLE
AS $$
	SELECT
		is_user_free_for_life.user_account.date_created < '2021-05-06T04:00:00';
$$;

CREATE OR REPLACE FUNCTION
	subscriptions.is_user_subscribed_or_free_for_life(
		user_account_id bigint
	)
RETURNS
	boolean
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		subscriptions.is_user_free_for_life(
			user_account := user_account
		) OR
		subscriptions.is_user_subscribed(
			user_account := user_account,
			as_of_date := core.utc_now()
		)
	FROM
		core.user_account
	WHERE
		user_account.id = is_user_subscribed_or_free_for_life.user_account_id;
$$;

-- Add new columns to notification_event to track bulk_email_filters.
CREATE TYPE
	notifications.bulk_email_subscription_status_filter
AS ENUM (
	'currently_subscribed',
	'not_currently_subscribed',
	'never_subscribed'
);

ALTER TABLE
	core.notification_event
ADD COLUMN
	bulk_email_subscription_status_filter notifications.bulk_email_subscription_status_filter,
ADD COLUMN
	bulk_email_free_for_life_filter bool;

-- Create a new notifications.create_company_update_notifications function that accepts optional filters.
CREATE FUNCTION
	notifications.create_company_update_notifications(
		author_id bigint,
		subject text,
		body text,
		subscription_status_filter text,
		free_for_life_filter bool
	)
RETURNS
	SETOF notifications.email_dispatch
LANGUAGE sql
AS $$
	WITH recipient AS (
		SELECT
			user_account.id AS user_account_id
		FROM
			core.user_account
			JOIN
				notifications.current_preference ON
					user_account.id = current_preference.user_account_id
			LEFT JOIN
				core.subscription_account ON
					user_account.id = subscription_account.user_account_id
			LEFT JOIN
				core.subscription ON
					subscription_account.provider = subscription.provider AND
					subscription_account.provider_account_id = subscription.provider_account_id
			LEFT JOIN
				core.subscription_period ON
					subscription.provider = subscription_period.provider AND
					subscription.provider_subscription_id = subscription_period.provider_subscription_id
		WHERE
			current_preference.company_update_via_email AND
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			WHEN
				'not_currently_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				NOT subscriptions.is_user_subscribed(
					user_account := user_account,
					as_of_date := core.utc_now()
				)
			ELSE
				TRUE
			END AND
			CASE
				create_company_update_notifications.free_for_life_filter
			WHEN
				TRUE
			THEN
				subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			WHEN
				FALSE
			THEN
				NOT subscriptions.is_user_free_for_life(
					user_account := user_account
				)
			ELSE
				TRUE
			END
		GROUP BY
			user_account.id
		HAVING
			CASE
				create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter
			WHEN
				'never_subscribed'::notifications.bulk_email_subscription_status_filter
			THEN
				every(subscription_period.payment_status IS DISTINCT FROM 'succeeded'::core.subscription_payment_status)
			ELSE
				TRUE
			END
	),
	update_event AS (
		INSERT INTO
			core.notification_event (
				type,
				bulk_email_author_id,
				bulk_email_subject,
				bulk_email_body,
				bulk_email_subscription_status_filter,
				bulk_email_free_for_life_filter
			)
		SELECT
			'company_update',
			create_company_update_notifications.author_id,
			create_company_update_notifications.subject,
			create_company_update_notifications.body,
			create_company_update_notifications.subscription_status_filter::notifications.bulk_email_subscription_status_filter,
			create_company_update_notifications.free_for_life_filter
		FROM
			recipient
		LIMIT
			1
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
				via_push,
				event_type
			)
		SELECT
			(
				SELECT
					update_event.id
				FROM
					update_event
			),
			recipient.user_account_id,
			TRUE,
			FALSE,
			FALSE,
			'company_update'::core.notification_event_type
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
		JOIN
			core.user_account ON
				user_account.id = receipt.user_account_id;
$$;

-- Update notifications.get_bulk_mailings function to return filters.
DROP FUNCTION
	notifications.get_bulk_mailings();

CREATE FUNCTION
	notifications.get_bulk_mailings()
RETURNS
	TABLE(
		id bigint,
		date_sent timestamp,
		subject text,
		body text,
		type core.notification_event_type,
		subscription_status_filter notifications.bulk_email_subscription_status_filter,
		free_for_life_filter bool,
		user_account text,
		recipient_count bigint
	)
LANGUAGE
	sql
AS $$
	SELECT
		event.id,
		event.date_created,
		event.bulk_email_subject,
		event.bulk_email_body,
		event.type,
		event.bulk_email_subscription_status_filter,
		event.bulk_email_free_for_life_filter,
		user_account.name AS user_account,
		count(*) AS recipient_count
	FROM
		core.notification_event AS event
		JOIN
			core.user_account ON
				event.bulk_email_author_id = core.user_account.id
		JOIN
			core.notification_receipt ON
				event.id = notification_receipt.event_id
	GROUP BY
		event.id,
		user_account.id;
$$;