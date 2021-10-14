-- set up for stripe subscription testing
CREATE TEMP TABLE
	price_id_migration (
		prod_id,
		dev_id
	) AS
VALUES
	('price_1In4cdCE1GzMLmqKRCTbqTGR', 'price_1In6LdCE1GzMLmqKo9JXXYpK'),
	('price_1In4cdCE1GzMLmqK1Dmh9hKF', 'price_1In6LdCE1GzMLmqKviYeislC'),
	('price_1In4cdCE1GzMLmqKQxqbyI2g', 'price_1In6LdCE1GzMLmqK73XjFH1Z');

WITH updated_subscription_price AS (
	UPDATE
		core.subscription_price
	SET
		provider_price_id = price_id_migration.dev_id
	FROM
		price_id_migration
	WHERE
		provider_price_id = price_id_migration.prod_id
	RETURNING
		*
),
updated_subscription_period AS (
	UPDATE
		core.subscription_period
	SET
		provider_price_id = price_id_migration.dev_id
	FROM
		price_id_migration
	WHERE
		provider_price_id = price_id_migration.prod_id
),
updated_subscription_renewal_status_change AS (
	UPDATE
		core.subscription_renewal_status_change
	SET
		provider_price_id = price_id_migration.dev_id
	FROM
		price_id_migration
	WHERE
		provider_price_id = price_id_migration.prod_id
)
SELECT
	*
FROM
	updated_subscription_price;