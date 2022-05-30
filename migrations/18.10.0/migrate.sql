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
	Adding support for donation payouts.
*/

CREATE TABLE
	core.donation_recipient (
		id bigserial,
		CONSTRAINT
			donation_recipient_pkey
		PRIMARY KEY (
			id
		),
		date_created timestamp NOT NULL,
		name text NOT NULL,
		website text NOT NULL,
		tax_id text NOT NULL
	);

CREATE TABLE
	core.donation_account (
		id bigserial,
		CONSTRAINT
			donation_account_pkey
		PRIMARY KEY (
			id
		),
		author_id bigint,
		CONSTRAINT
			donation_account_author_id_fkey
		FOREIGN KEY (
			author_id
		)
		REFERENCES
			core.author (id),
		user_account_id bigint,
		CONSTRAINT
			donation_account_user_account_id_fkey
		FOREIGN KEY (
			user_account_id
		)
		REFERENCES
			core.user_account (id),
		date_created timestamp NOT NULL,
		date_user_account_assigned timestamp,
		CONSTRAINT
			donation_account_principal_check
		CHECK (
			(
				author_id IS NOT NULL AND
				user_account_id IS NULL AND
				date_user_account_assigned IS NULL
			) OR (
				author_id IS NULL AND
				user_account_id IS NOT NULL AND
				date_user_account_assigned IS NOT NULL
			)
		),
		donation_recipient_id bigint NOT NULL,
		CONSTRAINT
			donation_account_donation_recipient_id_fkey
		FOREIGN KEY (
			donation_recipient_id
		)
		REFERENCES
			core.donation_recipient (id)
	);

CREATE TABLE
	core.donation_payout (
		id bigserial,
		CONSTRAINT
			donation_payout_pkey
		PRIMARY KEY (
			id
		),
		date_created timestamp NOT NULL,
		donation_account_id bigint NOT NULL,
		CONSTRAINT
			donation_payout_donation_account_id_fkey
		FOREIGN KEY (
			donation_account_id
		)
		REFERENCES
			core.donation_account (id),
		donation_recipient_id bigint NOT NULL,
		CONSTRAINT
			donation_payout_donation_recipient_id_fkey
		FOREIGN KEY (
			donation_recipient_id
		)
		REFERENCES
			core.donation_recipient (id),
		amount int NOT NULL,
		receipt text NOT NULL
	);

CREATE TYPE
	subscriptions.payout_totals_report AS (
		totalAuthorPayouts int,
		totalDonationPayouts int
	);

CREATE FUNCTION
	subscriptions.run_payout_totals_report()
RETURNS
	SETOF subscriptions.payout_totals_report
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		0,
		sum(donation_payout.amount)::int
	FROM
		core.donation_payout;
$$;

CREATE FUNCTION
	subscriptions.get_donation_recipient_for_author(
		author_id bigint
	)
RETURNS
	SETOF core.donation_recipient
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		recipient.*
	FROM
		core.donation_account AS account
		JOIN
			core.donation_recipient AS recipient ON
				account.donation_recipient_id = recipient.id
	WHERE
		account.author_id = get_donation_recipient_for_author.author_id;
$$;

DROP FUNCTION
	subscriptions.run_authors_earnings_report();

DROP TYPE
	subscriptions.author_earnings_report_line_item;

CREATE TYPE
	subscriptions.author_earnings_report_line_item AS (
		author_id bigint,
		author_name text,
		author_slug text,
		user_account_id bigint,
		user_account_name text,
		donation_recipient_id bigint,
		donation_recipient_name text,
		minutes_read integer,
		amount_earned integer,
		amount_paid integer
	);

CREATE FUNCTION
	subscriptions.run_authors_earnings_report()
RETURNS
	SETOF subscriptions.author_earnings_report_line_item
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		author.id,
		author.name,
		author.slug,
		user_account.id,
		user_account.name,
		donation_recipient.id,
		donation_recipient.name,
		sum(author_distribution.minutes_read)::int,
		sum(author_distribution.amount)::int,
		0
	FROM
		core.subscription_period_author_distribution AS author_distribution
		JOIN
			core.subscription_period AS period ON
				author_distribution.provider = period.provider AND
				author_distribution.provider_period_id = period.provider_period_id AND
				period.date_refunded IS NULL
		JOIN
			core.subscription ON
				period.provider = subscription.provider AND
				period.provider_subscription_id = subscription.provider_subscription_id
		JOIN
			core.subscription_account AS account ON
				subscription.provider = account.provider AND
				subscription.provider_account_id = account.provider_account_id AND
				account.environment = 'production'::core.subscription_environment
		JOIN
			core.author ON
				author_distribution.author_id = author.id
		LEFT JOIN
			core.author_user_account_assignment AS user_account_assignment ON
				author.id = user_account_assignment.author_id
		LEFT JOIN
			core.user_account ON
				user_account_assignment.user_account_id = user_account.id
		LEFT JOIN
			core.donation_account ON
				author.id = donation_account.author_id OR
				user_account.id = donation_account.user_account_id
		LEFT JOIN
			core.donation_recipient ON
				donation_account.donation_recipient_id = donation_recipient.id
	GROUP BY
		author.id,
		user_account.id,
		donation_recipient.id;
$$;