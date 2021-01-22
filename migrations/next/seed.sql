INSERT INTO
	core.subscription_level (
		id,
		name,
		amount
	)
VALUES
	(
		1,
		'Budget',
		499
	),
	(
		2,
		'Reader',
		1499
	),
	(
		3,
		'Super Reader',
		2499
	);

INSERT INTO
   core.subscription_price (
   	provider,
   	provider_price_id,
   	date_created,
   	level_id
   )
VALUES
	(
		'apple',
		'v1_level1',
		core.utc_now(),
		1
	),
   (
		'apple',
		'v1_level2',
		core.utc_now(),
		2
	),
   (
		'apple',
		'v1_level3',
		core.utc_now(),
		3
	),
   (
		'stripe',
		'',
		core.utc_now(),
		1
	),
   (
		'stripe',
		'',
		core.utc_now(),
		2
	),
   (
		'stripe',
		'',
		core.utc_now(),
		3
	);