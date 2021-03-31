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
		date_created := :begin
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