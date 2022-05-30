-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

\pset pager off

\echo 'Creating subscription account...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription_account(
		provider := 'apple',
		provider_account_id := 'test_cus_' || :id,
		user_account_id := (
			SELECT
				user_account.id
			FROM
				core.user_account
			WHERE
				user_account.name = :user
		),
		date_created := :begin,
		environment := 'production'
	);

\echo 'Creating subscription...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription(
		provider := 'apple',
		provider_subscription_id := 'test_sub_' || :id,
		provider_account_id := 'test_cus_' || :id,
		date_created := :begin,
		latest_receipt := '0'
	);

\echo 'Creating subscription period...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription_period(
		provider := 'apple',
		provider_period_id := 'test_in_' || :id,
		provider_subscription_id := 'test_sub_' || :id,
		provider_price_id := (
			SELECT
				price_level.provider_price_id
			FROM
				subscriptions.price_level
			WHERE
				price_level.provider = 'apple' AND
				price_level.name = :level
		),
		provider_payment_method_id := NULL,
		begin_date := :begin,
		end_date := :end,
		date_created := :begin,
		payment_status := 'succeeded',
		date_paid := :begin,
		date_refunded := NULL,
		refund_reason := NULL,
		proration_discount := NULL
	);