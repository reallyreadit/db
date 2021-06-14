/*
	This migration adds the payout_account table and limited associated functions.
*/

CREATE TABLE
	core.payout_account (
		id text,
		CONSTRAINT
			payout_account_pkey
		PRIMARY KEY (
			id
		),
		user_account_id bigint NOT NULL,
		CONSTRAINT
			payout_account_user_account_id_fkey
		FOREIGN KEY (
			user_account_id
		)
		REFERENCES
			core.user_account (id),
		CONSTRAINT
			payout_account_user_account_id_key
		UNIQUE (
			user_account_id
		),
		date_created timestamp NOT NULL,
		date_details_submitted timestamp,
		date_payouts_enabled timestamp
	);

CREATE FUNCTION
	subscriptions.get_payout_account(
		id text
	)
RETURNS
	SETOF core.payout_account
LANGUAGE
	sql
AS $$
	SELECT
		payout_account.*
	FROM
		core.payout_account
	WHERE
		payout_account.id = get_payout_account.id;
$$;

CREATE FUNCTION
	subscriptions.get_payout_account_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF core.payout_account
LANGUAGE
	sql
AS $$
	SELECT
		payout_account.*
	FROM
		core.payout_account
	WHERE
		payout_account.user_account_id = get_payout_account_for_user_account.user_account_id;
$$;

CREATE FUNCTION
	subscriptions.create_payout_account(
		id text,
		user_account_id bigint
	)
RETURNS
	SETOF core.payout_account
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.payout_account (
			id,
			user_account_id,
			date_created
		)
	VALUES (
		create_payout_account.id,
		create_payout_account.user_account_id,
		core.utc_now()
	)
	RETURNING
		*;
$$;

CREATE FUNCTION
	subscriptions.update_payout_account(
		id text,
		date_details_submitted timestamp,
		date_payouts_enabled timestamp
	)
RETURNS
	SETOF core.payout_account
LANGUAGE
	sql
AS $$
	UPDATE
		core.payout_account
	SET
		date_details_submitted = coalesce(payout_account.date_details_submitted, update_payout_account.date_details_submitted),
		date_payouts_enabled = coalesce(payout_account.date_payouts_enabled, update_payout_account.date_payouts_enabled)
	WHERE
		payout_account.id = update_payout_account.id
	RETURNING
		*;
$$;