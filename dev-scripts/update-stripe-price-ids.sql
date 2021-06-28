-- set up for stripe subscription testing
UPDATE
	core.subscription_price
SET
	provider_price_id = ''
WHERE
	provider = 'stripe'::core.subscription_provider AND
	level_id = 1;
UPDATE
	core.subscription_price
SET
	provider_price_id = ''
WHERE
	provider = 'stripe'::core.subscription_provider AND
	level_id = 2;
UPDATE
	core.subscription_price
SET
	provider_price_id = ''
WHERE
	provider = 'stripe'::core.subscription_provider AND
	level_id = 3;