-- create new core subscription types and tables
CREATE TYPE
   core.subscription_provider AS enum (
   	'apple',
      'stripe'
	);

CREATE TABLE
   core.subscription_account (
   	provider core.subscription_provider,
   	provider_account_id text,
   	CONSTRAINT
   		subscription_account_pkey
   	PRIMARY KEY (
   	   provider,
   	   provider_account_id
		),
   	user_account_id bigint
   		CONSTRAINT
   			subscription_account_user_account_fkey
   	   REFERENCES
   	      core.user_account (id),
		CONSTRAINT
		   subscription_account_user_account_null_check
		CHECK (
		   user_account_id IS NOT NULL OR
		   provider = 'apple'::core.subscription_provider
		),
		date_created timestamp NOT NULL
	);

CREATE UNIQUE INDEX
   subscription_account_user_account_unique_assignment_idx ON
		core.subscription_account (
			user_account_id
		)
WHERE
	provider = 'stripe'::core.subscription_provider;

CREATE TYPE
	core.subscription_payment_method_wallet AS enum (
		'none',
		'unknown',
		'amex_express_checkout',
		'apple_pay',
		'google_pay',
		'masterpass',
		'samsung_pay',
		'visa_checkout'
	);

CREATE TYPE
   core.subscription_payment_method_brand AS enum (
      'none',
      'unknown',
		'amex',
      'diners',
      'discover',
      'jcb',
      'mastercard',
      'unionpay',
      'visa'
	);

CREATE TYPE
	core.subscription_event_source AS enum (
		'provider_notification',
		'user_action'
	);

CREATE DOMAIN
   core.calendar_month AS int
CHECK (
	VALUE <@ int4range(1, 12, '[]')
);

CREATE DOMAIN
   core.calendar_year AS int
CHECK (
	VALUE <@ int4range(1000, 9999, '[]')
);

CREATE DOMAIN
	core.iso_alpha_2_country_code AS char (2)
CHECK (
	VALUE SIMILAR TO '[A-Z]{2}'
);

CREATE TABLE
   core.subscription_payment_method (
		provider core.subscription_provider,
		provider_payment_method_id text,
		CONSTRAINT
			subscription_payment_method_pkey
		PRIMARY KEY (
		   provider,
		   provider_payment_method_id
		),
		provider_account_id text NOT NULL,
		CONSTRAINT
			subscription_payment_method_account_fkey
		FOREIGN KEY (
		   provider,
		   provider_account_id
		)
		REFERENCES
		   core.subscription_account (
				provider,
		      provider_account_id
			),
		date_created timestamp NOT NULL,
		wallet core.subscription_payment_method_wallet NOT NULL,
		brand core.subscription_payment_method_brand NOT NULL,
		last_four_digits char (4) NOT NULL
			CONSTRAINT
				subscription_payment_method_last_four_digits_pattern_check
			CHECK (
				last_four_digits SIMILAR TO '[0-9]{4}'
			),
		country core.iso_alpha_2_country_code NOT NULL,
   	current_version_date timestamp NOT NULL
	);

CREATE TABLE
	core.subscription_payment_method_version (
		provider core.subscription_provider,
		provider_payment_method_id text,
		date_created timestamp,
		CONSTRAINT
			subscription_payment_method_version_pkey
		PRIMARY KEY (
			provider,
			provider_payment_method_id,
			date_created
		),
		CONSTRAINT
			subscription_payment_method_version_payment_method_fkey
		FOREIGN KEY (
			provider,
			provider_payment_method_id
		)
		REFERENCES
			core.subscription_payment_method (
				provider,
				provider_payment_method_id
			),
		event_source core.subscription_event_source NOT NULL,
		expiration_month core.calendar_month NOT NULL,
		expiration_year core.calendar_year NOT NULL
	);

ALTER TABLE
	core.subscription_payment_method
ADD CONSTRAINT
	subscription_payment_method_current_version_fkey
FOREIGN KEY (
	provider,
	provider_payment_method_id,
	current_version_date
)
REFERENCES
	core.subscription_payment_method_version (
		provider,
		provider_payment_method_id,
		date_created
	)
DEFERRABLE INITIALLY IMMEDIATE;

CREATE TABLE
   core.subscription_default_payment_method (
   	provider core.subscription_provider,
   	provider_account_id text,
   	date_assigned timestamp,
   	CONSTRAINT
   		subscription_default_payment_method_pkey
   	PRIMARY KEY (
   	   provider,
   	   provider_account_id,
   	   date_assigned
		),
		CONSTRAINT
			subscription_default_payment_method_account_fkey
		FOREIGN KEY (
		   provider,
		   provider_account_id
		)
		REFERENCES
			core.subscription_account (
			   provider,
			   provider_account_id
			),
   	date_unassigned timestamp,
   	provider_payment_method_id text NOT NULL,
   	CONSTRAINT
   		subscription_default_payment_method_payment_method_fkey
		FOREIGN KEY (
		   provider,
		   provider_payment_method_id
		)
		REFERENCES
			core.subscription_payment_method (
			   provider,
			   provider_payment_method_id
			)
	);

CREATE UNIQUE INDEX
	subscription_default_payment_method_unique_assignment_idx ON
		core.subscription_default_payment_method (
			provider,
			provider_account_id
		)
WHERE
	date_unassigned IS NULL;

CREATE TABLE
	core.subscription_level (
		id int
			CONSTRAINT
				subscription_level_pkey
			PRIMARY KEY,
		name text NOT NULL,
		amount int NOT NULL
	);

CREATE TABLE
   core.subscription_price (
   	provider core.subscription_provider,
   	provider_price_id text,
   	CONSTRAINT
   		subscription_price_pkey
   	PRIMARY KEY (
   	   provider,
   	   provider_price_id
		),
   	date_created timestamp NOT NULL,
   	level_id int
   		CONSTRAINT
   			subscription_price_level_fkey
   		REFERENCES
   			core.subscription_level (id),
   	custom_amount int,
   	CONSTRAINT
   		subscription_price_level_or_custom_amount_null_check
   	CHECK (
   		(
   			level_id IS NULL AND
   			custom_amount IS NOT NULL AND
   			provider = 'stripe'::core.subscription_provider
   		) OR (
   			level_id IS NOT NULL AND
   			custom_amount IS NULL
   		)
   	),
   	CONSTRAINT
   		subscription_price_unique_level_idx
   	UNIQUE (
   		provider,
   		level_id
   	),
   	CONSTRAINT
   		subscription_price_unique_custom_amount_idx
   	UNIQUE (
   		provider,
			custom_amount
   	)
	);

CREATE DOMAIN
   core.base64_text AS text
CHECK (
	VALUE SIMILAR TO '[A-Za-z0-9+/]+={0,2}'
);

CREATE TABLE
   core.subscription (
   	provider core.subscription_provider,
   	provider_subscription_id text,
   	CONSTRAINT
   		subscription_pkey
   	PRIMARY KEY (
   	   provider,
   	   provider_subscription_id
		),
   	provider_account_id text NOT NULL,
   	CONSTRAINT
   		subscription_account_fkey
   	FOREIGN KEY (
		   provider,
			provider_account_id
		)
		REFERENCES
			core.subscription_account (
				provider,
				provider_account_id
			),
		date_created timestamp NOT NULL,
		date_terminated timestamp,
   	latest_receipt core.base64_text,
   	CONSTRAINT
   		subscription_latest_receipt_null_check
   	CHECK (
			latest_receipt IS NOT NULL OR
			provider = 'stripe'::core.subscription_provider
		)
	);

CREATE TYPE
	core.subscription_payment_status AS enum (
		'succeeded',
		'requires_confirmation',
		'failed'
	);

CREATE TABLE
	core.subscription_period (
		provider core.subscription_provider,
		provider_period_id text,
		CONSTRAINT
			subscription_period_pkey
		PRIMARY KEY (
		   provider,
		   provider_period_id
		),
		provider_subscription_id text NOT NULL,
		CONSTRAINT
			subscription_period_subscription_fkey
		FOREIGN KEY (
		   provider,
		   provider_subscription_id
		)
		REFERENCES
			core.subscription (
				provider,
			   provider_subscription_id
			),
		provider_price_id text NOT NULL,
		CONSTRAINT
			subscription_period_price_fkey
		FOREIGN KEY (
		   provider,
		   provider_price_id
		)
		REFERENCES
		   core.subscription_price (
		   	provider,
		      provider_price_id
			),
		provider_payment_method_id text,
		CONSTRAINT
			subscription_period_payment_method_fkey
		FOREIGN KEY (
			provider,
			provider_payment_method_id
		)
		REFERENCES
			core.subscription_payment_method (
				provider,
				provider_payment_method_id
			),
		CONSTRAINT
			subscription_period_payment_method_null_check
		CHECK (
			provider_payment_method_id IS NOT NULL OR
			date_paid IS NULL OR
			provider = 'apple'::core.subscription_provider
		),
		begin_date timestamp NOT NULL,
		end_date timestamp NOT NULL,
		CONSTRAINT
			subscription_period_date_range_check
		CHECK (
			begin_date < end_date
		),
		date_created timestamp NOT NULL,
		payment_status core.subscription_payment_status NOT NULL,
		date_paid timestamp,
		CONSTRAINT
			subscription_period_payment_status_check
		CHECK (
			CASE
				payment_status
			WHEN
				'succeeded'::core.subscription_payment_status
			THEN
				date_paid IS NOT NULL
			ELSE
				date_paid IS NULL
			END
		),
		date_refunded timestamp,
		refund_reason text,
		CONSTRAINT
			subscription_period_refund_reason_null_check
		CHECK (
			(
				date_refunded IS NULL AND refund_reason IS NULL
			) OR (
				date_refunded IS NOT NULL AND refund_reason IS NOT NULL
			)
		)
	);

-- create new subscriptions schema, views and api functions
CREATE SCHEMA
	subscriptions;

CREATE VIEW
	subscriptions.current_payment_method AS
SELECT
	method.provider,
   method.provider_payment_method_id,
	method.provider_account_id,
	method.date_created,
	method.wallet,
	method.brand,
	method.last_four_digits,
	method.country,
	current_version.expiration_month,
	current_version.expiration_year
FROM
	core.subscription_payment_method AS method
	JOIN
		core.subscription_payment_method_version AS current_version ON
			method.provider = current_version.provider AND
			method.provider_payment_method_id = current_version.provider_payment_method_id AND
			method.current_version_date = current_version.date_created;

CREATE VIEW
   subscriptions.current_default_payment_method AS
SELECT
	current_method.provider,
   current_method.provider_payment_method_id,
	current_method.provider_account_id,
	current_method.date_created,
	current_method.wallet,
	current_method.brand,
	current_method.last_four_digits,
	current_method.country,
	current_method.expiration_month,
	current_method.expiration_year
FROM
   subscriptions.current_payment_method AS current_method
	JOIN
      core.subscription_default_payment_method AS default_method ON
			current_method.provider = default_method.provider AND
			current_method.provider_payment_method_id = default_method.provider_payment_method_id AND
			current_method.provider_account_id = default_method.provider_account_id
WHERE
	default_method.date_unassigned IS NULL;

CREATE VIEW
	subscriptions.latest_subscription_period AS
SELECT
	latest_period.provider,
	latest_period.provider_period_id,
	latest_period.provider_subscription_id,
	latest_period.provider_price_id,
	latest_period.provider_payment_method_id,
	latest_period.begin_date,
	latest_period.end_date,
	latest_period.date_created,
	latest_period.payment_status,
	latest_period.date_paid,
	latest_period.date_refunded,
	latest_period.refund_reason
FROM
	core.subscription_period AS latest_period
	LEFT JOIN
		core.subscription_period AS later_period ON
			latest_period.provider = later_period.provider AND
			latest_period.provider_subscription_id = later_period.provider_subscription_id AND
			latest_period.date_created < later_period.date_created
WHERE
	later_period.provider_period_id IS NULL;

CREATE TYPE
	subscriptions.subscription_status_latest_period AS (
		provider_period_id text,
		provider_price_id text,
		price_level_name text,
		price_amount int,
		provider_payment_method_id text,
		begin_date timestamp,
		end_date timestamp,
		date_created timestamp,
		payment_status core.subscription_payment_status,
		date_paid timestamp,
		date_refunded timestamp,
		refund_reason text
	);

CREATE VIEW
	subscriptions.subscription_status AS
SELECT
	account.user_account_id,
	account.provider,
	account.provider_account_id,
	subscription.provider_subscription_id,
	subscription.date_created,
	subscription.date_terminated,
	(
		latest_period.provider_period_id,
		latest_period.provider_price_id,
		level.name,
		coalesce(level.amount, price.custom_amount),
		latest_period.provider_payment_method_id,
		latest_period.begin_date,
		latest_period.end_date,
		latest_period.date_created,
		latest_period.payment_status,
		latest_period.date_paid,
		latest_period.date_refunded,
		latest_period.refund_reason
	)::subscriptions.subscription_status_latest_period AS latest_period
FROM
	core.subscription
	JOIN
		core.subscription_account AS account ON
			subscription.provider = account.provider AND
			subscription.provider_account_id = account.provider_account_id
	JOIN
		subscriptions.latest_subscription_period AS latest_period ON
			subscription.provider = latest_period.provider AND
			subscription.provider_subscription_id = latest_period.provider_subscription_id
	JOIN
		core.subscription_price AS price ON
			latest_period.provider = price.provider AND
			latest_period.provider_price_id = price.provider_price_id
	LEFT JOIN
		core.subscription_level AS level ON
			price.level_id = level.id;

CREATE VIEW
	subscriptions.user_account_subscription_status AS
SELECT
	latest_status.user_account_id,
	latest_status.provider,
	latest_status.provider_account_id,
	latest_status.provider_subscription_id,
	latest_status.date_created,
	latest_status.date_terminated,
	latest_status.latest_period
FROM
	subscriptions.subscription_status AS latest_status
	LEFT JOIN
		subscriptions.subscription_status AS later_status ON
			latest_status.user_account_id = later_status.user_account_id AND
			greatest((latest_status.latest_period).date_created, (latest_status.latest_period).date_paid) < greatest((later_status.latest_period).date_created, (later_status.latest_period).date_paid)
WHERE
	(later_status.latest_period).provider_period_id IS NULL;

CREATE FUNCTION
   subscriptions.get_subscription_accounts_for_user_account(
   	user_account_id bigint
	)
RETURNS
   SETOF core.subscription_account
LANGUAGE
   sql
STABLE
AS $$
   SELECT
   	subscription_account.*
   FROM
   	core.subscription_account
   WHERE
   	subscription_account.user_account_id = get_subscription_accounts_for_user_account.user_account_id;
$$;

CREATE FUNCTION
   subscriptions.create_or_update_subscription_account(
   	provider text,
   	provider_account_id text,
   	user_account_id bigint,
   	date_created timestamp
	)
RETURNS
   SETOF core.subscription_account
LANGUAGE
   sql
AS $$
   INSERT INTO
   	core.subscription_account (
   		provider,
   		provider_account_id,
   		user_account_id,
   		date_created
   	)
   VALUES (
   	create_or_update_subscription_account.provider::core.subscription_provider,
   	create_or_update_subscription_account.provider_account_id,
   	create_or_update_subscription_account.user_account_id,
   	create_or_update_subscription_account.date_created
	)
	ON CONFLICT (
		provider,
		provider_account_id
	)
	DO UPDATE
		SET
			user_account_id = coalesce(subscription_account.user_account_id, create_or_update_subscription_account.user_account_id)
	RETURNING
   	*;
$$;

CREATE FUNCTION
	subscriptions.get_payment_method(
		provider text,
		provider_payment_method_id text
	)
RETURNS
	SETOF subscriptions.current_payment_method
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = get_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = get_payment_method.provider_payment_method_id;
$$;

CREATE FUNCTION
   subscriptions.create_payment_method(
		provider text,
		provider_payment_method_id text,
		provider_account_id text,
		date_created timestamp,
		wallet text,
		brand text,
		last_four_digits text,
		country text,
		expiration_month int,
		expiration_year int
	)
RETURNS
   SETOF subscriptions.current_payment_method
LANGUAGE
   plpgsql
AS $$
<<locals>>
DECLARE
	version_timestamp CONSTANT timestamp := core.utc_now();
BEGIN
	SET CONSTRAINTS
		subscription_payment_method_current_version_fkey
	DEFERRED;
   INSERT INTO
   	core.subscription_payment_method (
   		provider,
   		provider_payment_method_id,
   		provider_account_id,
   		date_created,
   		wallet,
   		brand,
   		last_four_digits,
   		country,
   		current_version_date
   	)
   	VALUES (
			create_payment_method.provider::core.subscription_provider,
			create_payment_method.provider_payment_method_id,
			create_payment_method.provider_account_id,
			create_payment_method.date_created,
			create_payment_method.wallet::core.subscription_payment_method_wallet,
			create_payment_method.brand::core.subscription_payment_method_brand,
			create_payment_method.last_four_digits::char (4),
			create_payment_method.country::core.iso_alpha_2_country_code,
			locals.version_timestamp
		);
	INSERT INTO
		core.subscription_payment_method_version (
			provider,
			provider_payment_method_id,
			date_created,
			event_source,
			expiration_month,
			expiration_year
		)
	VALUES (
		create_payment_method.provider::core.subscription_provider,
		create_payment_method.provider_payment_method_id,
		locals.version_timestamp,
		'user_action'::core.subscription_event_source,
		create_payment_method.expiration_month,
		create_payment_method.expiration_year
	);
	RETURN QUERY
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = create_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = create_payment_method.provider_payment_method_id;
END;
$$;

CREATE FUNCTION
	subscriptions.update_payment_method(
		provider text,
		provider_payment_method_id text,
		event_source text,
		expiration_month int,
		expiration_year int
	)
RETURNS
	SETOF subscriptions.current_payment_method
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
	version_timestamp CONSTANT timestamp := core.utc_now();
BEGIN
	INSERT INTO
		core.subscription_payment_method_version (
			provider,
			provider_payment_method_id,
			date_created,
			event_source,
			expiration_month,
			expiration_year
		)
	VALUES (
		update_payment_method.provider::core.subscription_provider,
		update_payment_method.provider_payment_method_id,
		locals.version_timestamp,
		update_payment_method.event_source::core.subscription_event_source,
		update_payment_method.expiration_month,
		update_payment_method.expiration_year
	);
	UPDATE
		core.subscription_payment_method AS payment_method
	SET
		current_version_date = locals.version_timestamp
	WHERE
		payment_method.provider = update_payment_method.provider::core.subscription_provider AND
		payment_method.provider_payment_method_id = update_payment_method.provider_payment_method_id;
	RETURN QUERY
	SELECT
		current_method.*
	FROM
		subscriptions.current_payment_method AS current_method
	WHERE
		current_method.provider = update_payment_method.provider::core.subscription_provider AND
		current_method.provider_payment_method_id = update_payment_method.provider_payment_method_id;
END;
$$;

CREATE FUNCTION
   subscriptions.assign_default_payment_method(
   	provider text,
   	provider_account_id text,
   	provider_payment_method_id text
	)
RETURNS
   SETOF subscriptions.current_payment_method
LANGUAGE
   plpgsql
AS $$
<<locals>>
DECLARE
	current_default_payment_method_id CONSTANT text := (
	   SELECT
	   	default_method.provider_payment_method_id
	   FROM
	   	subscriptions.current_default_payment_method AS default_method
	   WHERE
	   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	      default_method.provider_account_id = assign_default_payment_method.provider_account_id
	   FOR UPDATE
	);
BEGIN
   IF
      locals.current_default_payment_method_id IS NOT NULL AND
	   locals.current_default_payment_method_id != assign_default_payment_method.provider_payment_method_id
	THEN
	   UPDATE
	      core.subscription_default_payment_method AS default_method
	   SET
	      date_unassigned = core.utc_now()
	   WHERE
	   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	      default_method.provider_account_id = assign_default_payment_method.provider_account_id AND
	      default_method.date_unassigned IS NULL;
	END IF;
	IF
	   locals.current_default_payment_method_id IS NULL OR
	   locals.current_default_payment_method_id != assign_default_payment_method.provider_payment_method_id
	THEN
		INSERT INTO
		   core.subscription_default_payment_method (
		   	provider,
		   	provider_account_id,
		   	date_assigned,
		   	provider_payment_method_id
		   )
		VALUES (
			assign_default_payment_method.provider::core.subscription_provider,
			assign_default_payment_method.provider_account_id,
			core.utc_now(),
			assign_default_payment_method.provider_payment_method_id
		);
	END IF;
   RETURN QUERY
   SELECT
   	default_method.*
   FROM
      subscriptions.current_default_payment_method AS default_method
   WHERE
   	default_method.provider = assign_default_payment_method.provider::core.subscription_provider AND
	   default_method.provider_account_id = assign_default_payment_method.provider_account_id;
END;
$$;

CREATE FUNCTION
	subscriptions.get_default_payment_method_for_subscription_account(
		provider text,
		provider_account_id text
	)
RETURNS
	SETOF subscriptions.current_payment_method
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		default_method.*
	FROM
		subscriptions.current_default_payment_method AS default_method
	WHERE
		default_method.provider = get_default_payment_method_for_subscription_account.provider::core.subscription_provider AND
		default_method.provider_account_id = get_default_payment_method_for_subscription_account.provider_account_id;
$$;

CREATE FUNCTION
	subscriptions.create_or_update_subscription(
		provider text,
		provider_subscription_id text,
		provider_account_id text,
		date_created timestamp,
		date_terminated timestamp,
		latest_receipt text
	)
RETURNS
	SETOF core.subscription
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.subscription (
			provider,
			provider_subscription_id,
			provider_account_id,
			date_created,
			date_terminated,
			latest_receipt
		)
	VALUES (
		create_or_update_subscription.provider::core.subscription_provider,
		create_or_update_subscription.provider_subscription_id,
		create_or_update_subscription.provider_account_id,
		create_or_update_subscription.date_created,
		create_or_update_subscription.date_terminated,
		create_or_update_subscription.latest_receipt
	)
	ON CONFLICT (
		provider,
		provider_subscription_id
	)
	DO UPDATE
		SET
			date_terminated = coalesce(subscription.date_terminated, create_or_update_subscription.date_terminated),
			latest_receipt = coalesce(create_or_update_subscription.latest_receipt, subscription.latest_receipt)
	RETURNING
		*;
$$;

CREATE FUNCTION
	subscriptions.create_or_update_subscription_period(
		provider text,
		provider_period_id text,
		provider_subscription_id text,
		provider_price_id text,
		provider_payment_method_id text,
		begin_date timestamp,
		end_date timestamp,
		date_created timestamp,
		payment_status text,
		date_paid timestamp,
		date_refunded timestamp,
		refund_reason text
	)
RETURNS
	SETOF core.subscription_period
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.subscription_period (
			provider,
			provider_period_id,
			provider_subscription_id,
			provider_price_id,
			provider_payment_method_id,
			begin_date,
			end_date,
			date_created,
			payment_status,
			date_paid,
			date_refunded,
			refund_reason
		)
	VALUES (
		create_or_update_subscription_period.provider::core.subscription_provider,
		create_or_update_subscription_period.provider_period_id,
		create_or_update_subscription_period.provider_subscription_id,
		create_or_update_subscription_period.provider_price_id,
		create_or_update_subscription_period.provider_payment_method_id,
		create_or_update_subscription_period.begin_date,
		create_or_update_subscription_period.end_date,
		create_or_update_subscription_period.date_created,
		create_or_update_subscription_period.payment_status::core.subscription_payment_status,
		create_or_update_subscription_period.date_paid,
		create_or_update_subscription_period.date_refunded,
		create_or_update_subscription_period.refund_reason
	)
	ON CONFLICT (
		provider,
		provider_period_id
	)
	DO UPDATE
		SET
			payment_status = create_or_update_subscription_period.payment_status::core.subscription_payment_status,
			date_paid = coalesce(subscription_period.date_paid, create_or_update_subscription_period.date_paid),
			date_refunded = coalesce(subscription_period.date_refunded, create_or_update_subscription_period.date_refunded),
			refund_reason = coalesce(subscription_period.refund_reason, create_or_update_subscription_period.refund_reason)
	RETURNING
		*;
$$;

CREATE FUNCTION
	subscriptions.update_subscription_period_payment_status(
		provider text,
		provider_period_id text,
		provider_payment_method_id text,
		payment_status text,
		date_paid timestamp
	)
RETURNS
	SETOF core.subscription_period
LANGUAGE
	sql
AS $$
	UPDATE
		core.subscription_period AS period
	SET
		provider_payment_method_id = update_subscription_period_payment_status.provider_payment_method_id,
		payment_status = update_subscription_period_payment_status.payment_status::core.subscription_payment_status,
		date_paid = coalesce(period.date_paid, update_subscription_period_payment_status.date_paid)
	WHERE
		period.provider = update_subscription_period_payment_status.provider::core.subscription_provider AND
		period.provider_period_id = update_subscription_period_payment_status.provider_period_id
	RETURNING
		*;
$$;

CREATE FUNCTION
	subscriptions.get_subscription_statuses_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF subscriptions.subscription_status
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		status.*
	FROM
		subscriptions.subscription_status AS status
	WHERE
		status.user_account_id = get_subscription_statuses_for_user_account.user_account_id;
$$;

CREATE FUNCTION
	subscriptions.get_current_subscription_status_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF subscriptions.subscription_status
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		status.*
	FROM
		subscriptions.user_account_subscription_status AS status
	WHERE
		status.user_account_id = get_current_subscription_status_for_user_account.user_account_id;
$$;

CREATE FUNCTION
	subscriptions.get_subscription_status_for_subscription_account(
		provider text,
		provider_account_id text
	)
RETURNS
	SETOF subscriptions.subscription_status
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		status.*
	FROM
		subscriptions.subscription_status AS status
	WHERE
		status.provider = get_subscription_status_for_subscription_account.provider::core.subscription_provider AND
		status.provider_account_id = get_subscription_status_for_subscription_account.provider_account_id;
$$;

CREATE VIEW
	subscriptions.price_level AS
SELECT
	price.provider,
	price.provider_price_id,
	price.date_created,
	level.name,
	level.amount
FROM
	core.subscription_price AS price
	JOIN
		core.subscription_level AS level ON
			price.level_id = level.id;

CREATE FUNCTION
	subscriptions.get_price_levels_for_provider(
		provider text
	)
RETURNS
	SETOF subscriptions.price_level
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		price.*
	FROM
		subscriptions.price_level AS price
	WHERE
		price.provider = get_price_levels_for_provider.provider::core.subscription_provider;
$$;

CREATE FUNCTION
	subscriptions.get_custom_price_for_provider(
		provider text,
		amount int
	)
RETURNS
	SETOF core.subscription_price
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		price.*
	FROM
		core.subscription_price AS price
	WHERE
		price.provider = get_custom_price_for_provider.provider::core.subscription_provider AND
		price.custom_amount = get_custom_price_for_provider.amount;
$$;

CREATE FUNCTION
	subscriptions.create_custom_price(
		provider text,
		provider_price_id text,
		date_created timestamp,
		amount int
	)
RETURNS
	SETOF core.subscription_price
LANGUAGE
	sql
AS $$
	WITH new_price AS (
		INSERT INTO
			core.subscription_price (
				provider,
				provider_price_id,
				date_created,
				custom_amount
			)
		VALUES (
			create_custom_price.provider::core.subscription_provider,
			create_custom_price.provider_price_id,
			create_custom_price.date_created,
			create_custom_price.amount
		)
		ON CONFLICT (
			provider,
			custom_amount
		)
		DO NOTHING
		RETURNING
			*
	)
	SELECT
		new_price.*
	FROM
		new_price
	UNION
	SELECT
		price.*
	FROM
		core.subscription_price AS price
	WHERE
		price.provider = create_custom_price.provider::core.subscription_provider AND
		price.custom_amount = create_custom_price.amount;
$$;