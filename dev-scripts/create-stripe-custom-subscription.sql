\pset pager off

\echo 'Creating subscription account...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription_account(
		provider := 'stripe',
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

\echo 'Creating payment method...'

SELECT
	*
FROM
	subscriptions.create_payment_method(
		provider := 'stripe',
		provider_payment_method_id := 'test_pm_' || :id,
		provider_account_id := 'test_cus_' || :id,
		date_created := :begin,
		wallet := 'none',
		brand := :card_brand,
		last_four_digits := :card_digits,
		country := :card_country,
		expiration_month := :card_exp_month,
		expiration_year := :card_exp_year
	);

\echo 'Assigning default payment method...'

SELECT
	*
FROM
	subscriptions.assign_default_payment_method(
   	provider := 'stripe',
   	provider_account_id := 'test_cus_' || :id,
   	provider_payment_method_id := 'test_pm_' || :id
	);

\echo 'Creating custom price...'

SELECT
	*
FROM
	subscriptions.create_custom_price_level(
		provider := 'stripe',
		provider_price_id := 'test_price_' || :id,
		date_created := :begin,
		amount := :price
	);

\echo 'Creating subscription...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription(
		provider := 'stripe',
		provider_subscription_id := 'test_sub_' || :id,
		provider_account_id := 'test_cus_' || :id,
		date_created := :begin,
		latest_receipt := NULL
	);

\echo 'Creating subscription period...'

SELECT
	*
FROM
	subscriptions.create_or_update_subscription_period(
		provider := 'stripe',
		provider_period_id := 'test_in_' || :id,
		provider_subscription_id := 'test_sub_' || :id,
		provider_price_id := 'test_price_' || :id,
		provider_payment_method_id := 'test_pm_' || :id,
		begin_date := :begin,
		end_date := :end,
		date_created := :begin,
		payment_status := 'succeeded',
		date_paid := :begin,
		date_refunded := NULL,
		refund_reason := NULL,
		proration_discount := NULL
	);