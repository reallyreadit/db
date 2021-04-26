-- add new author and source lookup functions to query all articles instead of community_reads
-- leave old community_reads functions in place for backward-compatibility
CREATE FUNCTION
	article_api.get_articles_by_author_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
)
RETURNS SETOF
	article_api.article_page_result
LANGUAGE
	sql
STABLE
AS $$
	WITH author_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published
		FROM
			core.article
			JOIN
				core.article_author ON
					article.id = article_author.article_id
			JOIN
				core.author ON
					article_author.author_id = author.id
		WHERE
			author.slug = get_articles_by_author_slug.slug AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_author_slug.min_length,
				max_length := get_articles_by_author_slug.max_length
			)
	)
	SELECT
		articles.*,
		(
			SELECT
				count(*)
			FROM
				author_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
				SELECT
					author_article.id
				FROM
					author_article
				ORDER BY
					author_article.date_published DESC NULLS LAST,
					author_article.id DESC
				OFFSET
					(get_articles_by_author_slug.page_number - 1) * get_articles_by_author_slug.page_size
				LIMIT
					get_articles_by_author_slug.page_size
			)
		) AS articles;
$$;

CREATE FUNCTION
	article_api.get_articles_by_source_slug(
		slug text,
		user_account_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
)
RETURNS SETOF
	article_api.article_page_result
LANGUAGE
	sql
STABLE
AS $$
	WITH publisher_article AS (
		SELECT DISTINCT
			article.id,
			article.date_published
		FROM
			core.article
		WHERE
			article.source_id = (
				SELECT
					source.id
				FROM
					core.source
				WHERE
					source.slug = get_articles_by_source_slug.slug
			) AND
			core.matches_article_length(
				word_count := article.word_count,
				min_length := get_articles_by_source_slug.min_length,
				max_length := get_articles_by_source_slug.max_length
			)
	)
	SELECT
		articles.*,
		(
			SELECT
				count(*)
			FROM
				publisher_article
		)
	FROM
		article_api.get_articles(
			user_account_id,
			VARIADIC ARRAY(
				SELECT
					publisher_article.id
				FROM
					publisher_article
				ORDER BY
					publisher_article.date_published DESC
				OFFSET
					(get_articles_by_source_slug.page_number - 1) * get_articles_by_source_slug.page_size
				LIMIT
					get_articles_by_source_slug.page_size
			)
		) AS articles;
$$;

-- add new notification event type for initial subscription email
ALTER TYPE
	core.notification_event_type
ADD VALUE
	'initial_subscription'
AFTER
	'welcome';

-- prevent duplicate initial_subscription notifications
CREATE UNIQUE INDEX
	notification_event_duplicate_user_account_event_idx
ON
	core.notification_receipt (
		user_account_id, event_type
	)
WHERE
	event_type = 'initial_subscription'::core.notification_event_type;

-- update create_transactional_notification to skip data if not provided
CREATE OR REPLACE FUNCTION
	notifications.create_transactional_notification(
		user_account_id bigint,
		event_type text,
		email_confirmation_id bigint,
		password_reset_request_id bigint
	)
RETURNS SETOF
	notifications.email_dispatch
LANGUAGE
	sql
AS $$
    WITH transactional_event AS (
		INSERT INTO
			core.notification_event (type)
		VALUES
		    (create_transactional_notification.event_type::core.notification_event_type)
        RETURNING
        	id
	),
    transactional_data AS (
      	INSERT INTO
        	core.notification_data (
        		event_id,
        	    email_confirmation_id,
        	    password_reset_request_id
			)
		SELECT
			transactional_event.id,
			create_transactional_notification.email_confirmation_id,
			create_transactional_notification.password_reset_request_id
		FROM
			transactional_event
    	WHERE
    		create_transactional_notification.email_confirmation_id IS NOT NULL OR
    		create_transactional_notification.password_reset_request_id IS NOT NULL
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
			(SELECT id FROM transactional_event),
		    create_transactional_notification.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    create_transactional_notification.event_type::core.notification_event_type
        RETURNING
        	id
	)
    SELECT
        (SELECT id FROM receipt),
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	core.user_account
    WHERE
    	id = create_transactional_notification.user_account_id;
$$;

-- add a new cached column to user_account for fast subscription status checking
ALTER TABLE
	core.user_account
ADD COLUMN
	subscription_end_date timestamp;

-- update article_api.update_read_progress to check subscription status
CREATE OR REPLACE FUNCTION article_api.update_read_progress(
	user_article_id bigint,
	read_state integer[],
	analytics text
)
	RETURNS core.user_article
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
   	-- utc timestamp
   	utc_now CONSTANT timestamp NOT NULL := utc_now();
   	-- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT
		    sum(n)
		FROM
		    unnest(update_read_progress.read_state) AS n
		WHERE
		    n > 0
	);
	-- local user_article
	current_user_article user_article;
	-- progress since last commit
	words_read_since_last_commit int;
BEGIN
    -- read and lock the existing user_article
	SELECT
	    *
	INTO
	    locals.current_user_article
	FROM
	    core.user_article
	WHERE
	    user_article.id = update_read_progress.user_article_id
	FOR UPDATE;
	-- check if the user is allowed to read
	IF (
		SELECT
			user_account.date_created >= '2021-01-01T00:00:00' AND
			(
				user_account.subscription_end_date IS NULL OR
				user_account.subscription_end_date <= locals.utc_now
			)
		FROM
			core.user_account
		WHERE
			user_account.id = locals.current_user_article.user_account_id
	)
	THEN
		RAISE EXCEPTION
			'Subscription required.'
		USING
			DETAIL = 'https://docs.readup.com/errors/reading/subscription-required';
	END IF;
	-- only update if more words have been read
	IF locals.words_read > locals.current_user_article.words_read THEN
	   	-- calculate the words read since the last commit
	   	locals.words_read_since_last_commit = locals.words_read - locals.current_user_article.words_read;
		-- update the progress
	   	INSERT INTO
	   	    core.user_article_progress (
	   	        user_account_id,
	   	        article_id,
	   	        period,
	   	        words_read,
	   	        client_type
	   	    )
	   	VALUES (
	   		locals.current_user_article.user_account_id,
	   	 	locals.current_user_article.article_id,
            (
                date_trunc('hour', locals.utc_now) +
                make_interval(mins => floor(extract('minute' FROM locals.utc_now) / 15)::int * 15)
            ),
	   		locals.words_read_since_last_commit,
	   		update_read_progress.analytics::json->'client'->'type'
		)
		ON CONFLICT (
		    user_account_id,
		    article_id,
		    period
		)
		DO UPDATE SET
		    words_read = user_article_progress.words_read + locals.words_read_since_last_commit;
	  	-- update the user_article
		UPDATE
		    core.user_article
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = locals.utc_now,
			analytics = update_read_progress.analytics::json
		WHERE
		    user_article.id = update_read_progress.user_article_id
		RETURNING
		    *
		INTO
		    locals.current_user_article;
		-- check if this update completed the page
		IF
			locals.current_user_article.date_completed IS NULL AND
			article_api.get_percent_complete(locals.current_user_article.readable_word_count, locals.words_read) >= 90
		THEN
			-- set date_completed
			UPDATE
			    core.user_article
			SET
			    date_completed = user_article.last_modified
			WHERE
			    user_article.id = update_read_progress.user_article_id
			RETURNING
			    *
			INTO
			    locals.current_user_article;
			-- update the cached article read count and set community_read_timestamp if necessary
			UPDATE
			    core.article
			SET
			    read_count = article.read_count + 1,
			    community_read_timestamp = (
			        CASE WHEN
			            article.community_read_timestamp IS NULL AND
			            article.read_count = 1
			        THEN
			            locals.utc_now
			        ELSE
			            article.community_read_timestamp
			        END
                ),
			    latest_read_timestamp = locals.utc_now
			WHERE
			    article.id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_article;
END;
$$;

-- add functions for author/user_account assignment lookup
CREATE FUNCTION
	authors.get_author_by_user_account_name(
		user_account_name text
	)
RETURNS
	SETOF core.author
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		author.*
	FROM
		core.author
	WHERE
		author.id = (
			SELECT
				assignment.author_id
			FROM
				core.author_user_account_assignment AS assignment
				JOIN
					core.user_account ON
						assignment.user_account_id = user_account.id
			WHERE
				user_account.name = get_author_by_user_account_name.user_account_name
		);
$$;

CREATE FUNCTION
	authors.get_user_account_by_author_slug(
		author_slug text
	)
RETURNS
	SETOF core.user_account
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		user_account.*
	FROM
		core.user_account
	WHERE
		user_account.id = (
			SELECT
				assignment.user_account_id
			FROM
				core.author_user_account_assignment AS assignment
				JOIN
					core.author ON
						assignment.author_id = author.id
			WHERE
				author.slug = get_user_account_by_author_slug.author_slug
		);
$$;

-- create new core subscription types and tables
CREATE TYPE
   core.subscription_provider AS enum (
   	'apple',
      'stripe'
	);

CREATE TYPE
	core.subscription_environment AS enum (
		'production',
		'sandbox'
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
		date_created timestamp NOT NULL,
		environment core.subscription_environment NOT NULL
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
		renewal_grace_period_end_date timestamp NOT NULL,
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
		),
		next_provider_period_id text,
		CONSTRAINT
			subscription_period_next_period_fkey
		FOREIGN KEY (
			provider,
			next_provider_period_id
		)
		REFERENCES
			core.subscription_period (
				provider,
				provider_period_id
			),
		prorated_price_amount int,
		CONSTRAINT
			subscription_period_prorated_price_amount_null_check
		CHECK (
			prorated_price_amount IS NULL OR next_provider_period_id IS NOT NULL
		)
	);

CREATE TABLE
	core.subscription_renewal_status_change (
		id bigserial,
		CONSTRAINT
			subscription_renewal_status_change_pkey
		PRIMARY KEY (
			id
		),
		provider core.subscription_provider NOT NULL,
		provider_subscription_id text NOT NULL,
		CONSTRAINT
			subscription_renewal_status_change_subscription_fkey
		FOREIGN KEY (
			provider,
			provider_subscription_id
		)
		REFERENCES
			core.subscription (
				provider,
				provider_subscription_id
			),
		date_created timestamp NOT NULL,
		auto_renew_enabled bool NOT NULL,
		provider_price_id text,
		CONSTRAINT
			subscription_renewal_status_change_price_fkey
		FOREIGN KEY (
			provider,
			provider_price_id
		)
		REFERENCES
			core.subscription_price (
				provider,
				provider_price_id
			),
		expiration_intent text
	);

CREATE TABLE
	core.subscription_period_distribution (
		provider core.subscription_provider,
		provider_period_id text,
		CONSTRAINT
			subscription_period_distribution_pkey
		PRIMARY KEY (
			provider,
			provider_period_id
		),
		CONSTRAINT
			subscription_period_distribution_period_fkey
		FOREIGN KEY (
			provider,
			provider_period_id
		)
		REFERENCES
			core.subscription_period (
				provider,
				provider_period_id
			),
		date_created timestamp NOT NULL,
		platform_amount int NOT NULL,
		provider_amount int NOT NULL,
		unknown_author_minutes_read int NOT NULL,
		unknown_author_amount int NOT NULL
	);

CREATE TABLE
	core.subscription_period_author_distribution (
		provider core.subscription_provider,
		provider_period_id text,
		CONSTRAINT
			subscription_period_author_distribution_distribution_fkey
		FOREIGN KEY (
			provider,
			provider_period_id
		)
		REFERENCES
			core.subscription_period_distribution (
				provider,
				provider_period_id
			),
		author_id int,
		CONSTRAINT
			subscription_period_author_distribution_pkey
		PRIMARY KEY (
			provider,
			provider_period_id,
			author_id
		),
		minutes_read int NOT NULL,
		amount int NOT NULL
	);

-- create new subscriptions schema, views and api functions
CREATE SCHEMA
	subscriptions;

CREATE VIEW
	subscriptions.price_level AS
SELECT
	price.provider,
	price.provider_price_id,
	price.date_created,
	price.level_id,
	level.name,
	coalesce(level.amount, price.custom_amount) AS amount
FROM
	core.subscription_price AS price
	LEFT JOIN
		core.subscription_level AS level ON
			price.level_id = level.id;

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
SELECT DISTINCT ON (
	period.provider,
	period.provider_subscription_id
)
	period.provider,
	period.provider_period_id,
	period.provider_subscription_id,
	period.provider_price_id,
	period.provider_payment_method_id,
	period.begin_date,
	period.end_date,
	period.renewal_grace_period_end_date,
	period.date_created,
	period.payment_status,
	period.date_paid,
	period.date_refunded,
	period.refund_reason,
	period.next_provider_period_id,
	period.prorated_price_amount
FROM
	core.subscription_period AS period
ORDER BY
	period.provider,
	period.provider_subscription_id,
	greatest(period.date_created, period.date_paid) DESC;

CREATE VIEW
	subscriptions.latest_subscription_renewal_status_change AS
SELECT DISTINCT ON (
	change.provider,
	change.provider_subscription_id
)
	change.id,
	change.provider,
	change.provider_subscription_id,
	change.date_created,
	change.auto_renew_enabled,
	change.provider_price_id,
	change.expiration_intent
FROM
	core.subscription_renewal_status_change AS change
ORDER BY
	change.provider,
	change.provider_subscription_id,
	change.id DESC;

CREATE TYPE
	subscriptions.subscription_status_latest_period AS (
		provider_period_id text,
		provider_price_id text,
		price_level_name text,
		price_amount int,
		provider_payment_method_id text,
		begin_date timestamp,
		end_date timestamp,
		renewal_grace_period_end_date timestamp,
		date_created timestamp,
		payment_status core.subscription_payment_status,
		date_paid timestamp,
		date_refunded timestamp,
		refund_reason text
	);

CREATE TYPE
	subscriptions.subscription_status_latest_renewal_status_change AS (
		date_created timestamp,
		auto_renew_enabled bool,
		provider_price_id text,
		price_level_name text,
		price_amount int
	);

CREATE VIEW
	subscriptions.subscription_status AS
SELECT
	account.user_account_id,
	account.provider,
	account.provider_account_id,
	subscription.provider_subscription_id,
	subscription.date_created,
	subscription.latest_receipt,
	(
		latest_period.provider_period_id,
		latest_period.provider_price_id,
		price_level.name,
		price_level.amount,
		latest_period.provider_payment_method_id,
		latest_period.begin_date,
		latest_period.end_date,
		latest_period.renewal_grace_period_end_date,
		latest_period.date_created,
		latest_period.payment_status,
		latest_period.date_paid,
		latest_period.date_refunded,
		latest_period.refund_reason
	)::subscriptions.subscription_status_latest_period AS latest_period,
	CASE
		WHEN
			latest_renewal_change.id IS NOT NULL
		THEN
			(
				latest_renewal_change.date_created,
				latest_renewal_change.auto_renew_enabled,
				latest_renewal_change.provider_price_id,
				renewal_price_level.name,
				renewal_price_level.amount
			)::subscriptions.subscription_status_latest_renewal_status_change
		ELSE
			NULL::subscriptions.subscription_status_latest_renewal_status_change
	END AS latest_renewal_status_change
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
		subscriptions.price_level ON
			latest_period.provider = price_level.provider AND
			latest_period.provider_price_id = price_level.provider_price_id
	LEFT JOIN
		subscriptions.latest_subscription_renewal_status_change AS latest_renewal_change ON
			subscription.provider = latest_renewal_change.provider AND
			subscription.provider_subscription_id = latest_renewal_change.provider_subscription_id AND
			tsrange(latest_period.begin_date, latest_period.end_date) @> latest_renewal_change.date_created
	LEFT JOIN
		subscriptions.price_level AS renewal_price_level ON
			latest_renewal_change.provider = renewal_price_level.provider AND
			latest_renewal_change.provider_price_id = renewal_price_level.provider_price_id;

CREATE VIEW
	subscriptions.user_account_subscription_status AS
SELECT DISTINCT ON (
	status.user_account_id
)
	status.user_account_id,
	status.provider,
	status.provider_account_id,
	status.provider_subscription_id,
	status.date_created,
	status.latest_receipt,
	status.latest_period,
	status.latest_renewal_status_change
FROM
	subscriptions.subscription_status AS status
ORDER BY
	status.user_account_id,
	greatest((status.latest_period).date_created, (status.latest_period).date_paid) DESC;

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
   	date_created timestamp,
   	environment text
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
   		date_created,
   		environment
   	)
   VALUES (
   	create_or_update_subscription_account.provider::core.subscription_provider,
   	create_or_update_subscription_account.provider_account_id,
   	create_or_update_subscription_account.user_account_id,
   	create_or_update_subscription_account.date_created,
   	create_or_update_subscription_account.environment::core.subscription_environment
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
			latest_receipt
		)
	VALUES (
		create_or_update_subscription.provider::core.subscription_provider,
		create_or_update_subscription.provider_subscription_id,
		create_or_update_subscription.provider_account_id,
		create_or_update_subscription.date_created,
		create_or_update_subscription.latest_receipt
	)
	ON CONFLICT (
		provider,
		provider_subscription_id
	)
	DO UPDATE
		SET
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
		refund_reason text,
		proration_discount int
	)
RETURNS
	SETOF core.subscription_period
LANGUAGE
	plpgsql
AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
<<locals>>
DECLARE
	user_account_id CONSTANT bigint := (
		SELECT
			subscription_account.user_account_id
		FROM
			core.subscription_account
			JOIN
				core.subscription ON
					subscription_account.provider = subscription.provider AND
					subscription_account.provider_account_id = subscription.provider_account_id
		WHERE
			subscription.provider = create_or_update_subscription_period.provider::core.subscription_provider AND
			subscription.provider_subscription_id = create_or_update_subscription_period.provider_subscription_id
	);
	current_period core.subscription_period;
	prev_unlinked_period core.subscription_period;
	current_status subscriptions.subscription_status;
BEGIN
	-- insert a new period or update an existing one
	INSERT INTO
		core.subscription_period (
			provider,
			provider_period_id,
			provider_subscription_id,
			provider_price_id,
			provider_payment_method_id,
			begin_date,
			end_date,
			renewal_grace_period_end_date,
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
		create_or_update_subscription_period.end_date + '1 hour'::interval,
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
			provider_payment_method_id = (
				CASE
					WHEN
						subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
					THEN
						subscription_period.provider_payment_method_id
					ELSE
						create_or_update_subscription_period.provider_payment_method_id
				END
			),
			payment_status = (
				CASE
					WHEN
						subscription_period.payment_status = 'succeeded'::core.subscription_payment_status
					THEN
						subscription_period.payment_status
					ELSE
						create_or_update_subscription_period.payment_status::core.subscription_payment_status
				END
			),
			date_paid = coalesce(subscription_period.date_paid, create_or_update_subscription_period.date_paid),
			date_refunded = coalesce(subscription_period.date_refunded, create_or_update_subscription_period.date_refunded),
			refund_reason = coalesce(subscription_period.refund_reason, create_or_update_subscription_period.refund_reason)
	RETURNING
		*
	INTO
		locals.current_period;
	-- check for a previous period that is not linked to the current period
	SELECT
		period.*
	INTO
		locals.prev_unlinked_period
	FROM
		core.subscription_period AS period
	WHERE
		period.provider = locals.current_period.provider AND
		period.provider_subscription_id = locals.current_period.provider_subscription_id AND
		period.begin_date < locals.current_period.begin_date AND
		period.renewal_grace_period_end_date >= locals.current_period.begin_date AND
		period.date_paid IS NOT NULL AND
		period.date_refunded IS NULL AND
		period.next_provider_period_id IS NULL
	FOR UPDATE;
	IF
		NOT (locals.prev_unlinked_period IS NULL)
	THEN
		-- link the previous period to the current period and set the prorated price if necessary
		UPDATE
			core.subscription_period
		SET
			next_provider_period_id = locals.current_period.provider_period_id,
			prorated_price_amount = (
				CASE
					WHEN
						locals.current_period.begin_date < locals.prev_unlinked_period.end_date
					THEN
						(
							SELECT
								CASE
									WHEN
										create_or_update_subscription_period.proration_discount IS NOT NULL
									THEN
										price_level.amount - create_or_update_subscription_period.proration_discount
									ELSE
										round(
											(
												extract('epoch' FROM (locals.current_period.begin_date - locals.prev_unlinked_period.begin_date)) /
												extract('epoch' FROM (locals.prev_unlinked_period.end_date - locals.prev_unlinked_period.begin_date))
											) *
											price_level.amount
										)
								END
							FROM
								subscriptions.price_level
							WHERE
								price_level.provider = locals.prev_unlinked_period.provider AND
								price_level.provider_price_id = locals.prev_unlinked_period.provider_price_id
						)
				END
			)
		WHERE
			subscription_period.provider = locals.prev_unlinked_period.provider AND
			subscription_period.provider_period_id = locals.prev_unlinked_period.provider_period_id;
		-- create a distribution for the previous period
		PERFORM
			subscriptions.create_distribution_for_period(
				provider := locals.prev_unlinked_period.provider::text,
				provider_period_id := locals.prev_unlinked_period.provider_period_id
			);
	END IF;
	-- update the cached user_account column with the current status
	SELECT
		*
	INTO
		locals.current_status
	FROM
		subscriptions.get_current_subscription_status_for_user_account(
			user_account_id := locals.user_account_id
		);
	UPDATE
		core.user_account
	SET
		subscription_end_date = (
			CASE WHEN
				(locals.current_status.latest_period).payment_status = 'succeeded'::core.subscription_payment_status AND
				(locals.current_status.latest_period).date_refunded IS NULL
			THEN
				(locals.current_status.latest_period).renewal_grace_period_end_date
			ELSE
				NULL::timestamp
			END
		)
	WHERE
		user_account.id = locals.user_account_id;
	-- return the current period
	RETURN NEXT
		locals.current_period;
END;
$$;

CREATE FUNCTION
	subscriptions.get_subscription_period(
		provider text,
		provider_period_id text
	)
RETURNS
	SETOF core.subscription_period
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		period.*
	FROM
		core.subscription_period AS period
	WHERE
		period.provider = get_subscription_period.provider::core.subscription_provider AND
		period.provider_period_id = get_subscription_period.provider_period_id;
$$;

CREATE FUNCTION
	subscriptions.create_subscription_renewal_status_change(
		provider text,
		provider_subscription_id text,
		date_created timestamp,
		auto_renew_enabled bool,
		provider_price_id text,
		expiration_intent text
	)
RETURNS
	SETOF core.subscription_renewal_status_change
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.subscription_renewal_status_change (
			provider,
			provider_subscription_id,
			date_created,
			auto_renew_enabled,
			provider_price_id,
			expiration_intent
		)
	VALUES (
		create_subscription_renewal_status_change.provider::core.subscription_provider,
		create_subscription_renewal_status_change.provider_subscription_id,
		create_subscription_renewal_status_change.date_created,
		create_subscription_renewal_status_change.auto_renew_enabled,
		create_subscription_renewal_status_change.provider_price_id,
		create_subscription_renewal_status_change.expiration_intent
	)
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

CREATE FUNCTION
	subscriptions.get_standard_price_levels_for_provider(
		provider text
	)
RETURNS
	SETOF subscriptions.price_level
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		price_level.*
	FROM
		subscriptions.price_level
	WHERE
		price_level.provider = get_standard_price_levels_for_provider.provider::core.subscription_provider AND
		price_level.level_id IS NOT NULL;
$$;

CREATE FUNCTION
	subscriptions.get_custom_price_level_for_provider(
		provider text,
		amount int
	)
RETURNS
	SETOF subscriptions.price_level
STABLE
LANGUAGE
	sql
AS $$
	SELECT
		price_level.*
	FROM
		subscriptions.price_level
	WHERE
		price_level.provider = get_custom_price_level_for_provider.provider::core.subscription_provider AND
		price_level.amount = get_custom_price_level_for_provider.amount;
$$;

CREATE FUNCTION
	subscriptions.create_custom_price_level(
		provider text,
		provider_price_id text,
		date_created timestamp,
		amount int
	)
RETURNS
	SETOF subscriptions.price_level
LANGUAGE
	plpgsql
AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
BEGIN
	-- insert the new price
	INSERT INTO
		core.subscription_price (
			provider,
			provider_price_id,
			date_created,
			custom_amount
		)
	VALUES (
		create_custom_price_level.provider::core.subscription_provider,
		create_custom_price_level.provider_price_id,
		create_custom_price_level.date_created,
		create_custom_price_level.amount
	)
	ON CONFLICT (
		provider,
		custom_amount
	)
	DO NOTHING;
	-- return the price_level
	RETURN QUERY
	SELECT
		*
	FROM
		subscriptions.get_custom_price_level_for_provider(
			provider := create_custom_price_level.provider,
			amount := create_custom_price_level.amount
		);
END;
$$;

CREATE TYPE
	subscriptions.subscription_distribution_author_calculation AS (
		author_id int,
		minutes_read int,
		amount int
	);

CREATE TYPE
	subscriptions.subscription_allocation_calculation AS (
		platform_amount int,
		provider_amount int,
		author_amount int
	);

CREATE FUNCTION
	subscriptions.calculate_allocation_for_period(
		provider core.subscription_provider,
		subscription_amount int,
		payment_method_country core.iso_alpha_2_country_code
	)
RETURNS
	subscriptions.subscription_allocation_calculation
LANGUAGE
	plpgsql
IMMUTABLE
AS $$
<<locals>>
DECLARE
	provider_amount int;
	platform_amount int;
	author_amount int;
BEGIN
	-- calculate the payment provider fee amount
	locals.provider_amount := least(
		CASE
			calculate_allocation_for_period.provider
		WHEN
			'apple'::core.subscription_provider
		THEN
			-- app store small business program 15% commission
			round(calculate_allocation_for_period.subscription_amount * 0.15)
		WHEN
			'stripe'::core.subscription_provider
		THEN
			-- payments percentage-based commission
			round(
				calculate_allocation_for_period.subscription_amount * (
					-- base 2.9% commission
					0.029 +
					-- international 1% commission
					CASE
						WHEN
							calculate_allocation_for_period.payment_method_country != 'US'::core.iso_alpha_2_country_code
						THEN
							0.01
						ELSE
							0
					END
				)
			) +
			-- payments flat-rate $0.30 commission
			30 +
			-- billing 0.5% commission (applied separately from payments commission so needs to be rounded separately)
			round(calculate_allocation_for_period.subscription_amount * 0.005)
		END,
		-- prorated subscriptions could potentially be less than the flat-rate commission
		calculate_allocation_for_period.subscription_amount
	);
	-- calculate the platform fee amount
	locals.platform_amount := greatest(
		least(
			round(calculate_allocation_for_period.subscription_amount * 0.05),
			calculate_allocation_for_period.subscription_amount - locals.provider_amount
		),
		0
	);
	-- calculate the amount left for the authors
	locals.author_amount := greatest(
		calculate_allocation_for_period.subscription_amount - locals.provider_amount - locals.platform_amount,
		0
	);
	-- return the calculation
	RETURN (
		locals.platform_amount,
		locals.provider_amount,
		locals.author_amount
	);
END;
$$;

CREATE TYPE
	subscriptions.subscription_distribution_calculation AS (
		platform_amount int,
		provider_amount int,
		unknown_author_minutes_read int,
		unknown_author_amount int,
		author_distributions subscriptions.subscription_distribution_author_calculation[]
	);

CREATE FUNCTION
	subscriptions.calculate_distribution_for_period(
		provider text,
		provider_period_id text
	)
RETURNS
	subscriptions.subscription_distribution_calculation
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
	period core.subscription_period;
	effective_period_range tsrange;
	subscription_amount int;
	allocation subscriptions.subscription_allocation_calculation;
	unknown_author_minutes_read int;
	unknown_author_amount int;
	author_distributions subscriptions.subscription_distribution_author_calculation[];
BEGIN
	-- get the subscription period
	SELECT
		subscription_period.*
	INTO
		locals.period
	FROM
		core.subscription_period
	WHERE
		subscription_period.provider = calculate_distribution_for_period.provider::core.subscription_provider AND
		subscription_period.provider_period_id = calculate_distribution_for_period.provider_period_id AND
		subscription_period.date_refunded IS NULL;
	-- calculate the effective period range
	IF
		locals.period.next_provider_period_id IS NOT NULL
	THEN
		SELECT
			tsrange(locals.period.begin_date, next_period.begin_date, '[)')
		INTO
			locals.effective_period_range
		FROM
			core.subscription_period AS next_period
		WHERE
			next_period.provider = locals.period.provider AND
			next_period.provider_period_id = locals.period.next_provider_period_id;
	ELSE
		locals.effective_period_range := tsrange(locals.period.begin_date, locals.period.renewal_grace_period_end_date, '[)');
	END IF;
	-- get the subscription amount, checking for a prorated amount first
	IF
		locals.period.prorated_price_amount IS NOT NULL
	THEN
		locals.subscription_amount := locals.period.prorated_price_amount;
	ELSE
		SELECT
			price_level.amount
		INTO
			locals.subscription_amount
		FROM
			subscriptions.price_level
		WHERE
			price_level.provider = locals.period.provider AND
			price_level.provider_price_id = locals.period.provider_price_id;
	END IF;
	-- calculate the allocation
	SELECT
		*
	INTO
		locals.allocation
	FROM
		subscriptions.calculate_allocation_for_period(
			provider := locals.period.provider,
			subscription_amount := locals.subscription_amount,
			payment_method_country := (
				CASE
					locals.period.provider
				WHEN
					'apple'::core.subscription_provider
				THEN
					NULL::iso_alpha_2_country_code
				WHEN
					'stripe'::core.subscription_provider
				THEN
					(
						SELECT
							payment_method.country
						FROM
							core.subscription_payment_method AS payment_method
						WHERE
							payment_method.provider = locals.period.provider AND
							payment_method.provider_payment_method_id = locals.period.provider_payment_method_id
					)
				END
			)
		);
	-- calculate the individual author amounts based on their share of minutes read
	CREATE TEMPORARY TABLE
		author_distribution
	AS (
		WITH period_read AS (
			SELECT
				article.id,
				article.word_count
			FROM
				core.user_article
				JOIN
					core.article ON
						article.id = user_article.article_id
			WHERE
				user_article.user_account_id = (
					SELECT
						subscription_account.user_account_id
					FROM
						core.subscription
						JOIN core.subscription_account ON
							subscription.provider = subscription_account.provider AND
							subscription.provider_account_id = subscription_account.provider_account_id
					WHERE
						subscription.provider = locals.period.provider AND
						subscription.provider_subscription_id = locals.period.provider_subscription_id
				) AND
				user_article.date_completed <@ locals.effective_period_range
		),
		read_author_share AS (
			SELECT
				article_author.author_id,
				(
					core.estimate_article_length(period_read.word_count)::decimal /
					count(*) OVER (PARTITION BY period_read.id)
				) AS minutes_read
			FROM
				period_read
				LEFT JOIN
					core.article_author ON
						period_read.id = article_author.article_id
		)
		SELECT
			read_author_share.author_id,
			sum(read_author_share.minutes_read) AS minutes_read,
			round(
				(
					sum(read_author_share.minutes_read) /
					(
						SELECT
							sum(
								core.estimate_article_length(period_read.word_count)
							)
						FROM
							period_read
					)
				) *
				locals.allocation.author_amount
			)::int AS amount
		FROM
			read_author_share
		GROUP BY
			read_author_share.author_id
	);
	-- absorb any difference between the author total amount and individual distributions caused by rounding into the platform fee
	locals.allocation.platform_amount := locals.allocation.platform_amount + (
			locals.allocation.author_amount -
			(
				SELECT
					coalesce(
						sum(author_distribution.amount)::int,
						0
					)
				FROM
					author_distribution
			)
		);
	-- select the unknown author distribution
	SELECT
		author_distribution.minutes_read,
		author_distribution.amount
	INTO
		locals.unknown_author_minutes_read,
		locals.unknown_author_amount
	FROM
		author_distribution
	WHERE
		author_distribution.author_id IS NULL;
	-- select the author distributions
	locals.author_distributions := ARRAY (
		SELECT
			(
				author_distribution.author_id,
				author_distribution.minutes_read,
				author_distribution.amount
			)::subscriptions.subscription_distribution_author_calculation
		FROM
			author_distribution
		WHERE
			author_distribution.author_id IS NOT NULL
	);
	-- clean up the temp table
	DROP TABLE
		author_distribution;
	-- return the calculation
	RETURN (
		locals.allocation.platform_amount,
		locals.allocation.provider_amount,
		coalesce(locals.unknown_author_minutes_read, 0),
		coalesce(locals.unknown_author_amount, 0),
		locals.author_distributions
	);
END;
$$;

CREATE TYPE
	subscriptions.subscription_distribution_author_report AS (
		author_id bigint,
		author_name text,
		author_slug text,
		minutes_read int,
		amount int
	);

CREATE TYPE
	subscriptions.subscription_distribution_report AS (
		subscription_amount int,
		platform_amount int,
		apple_amount int,
		stripe_amount int,
		unknown_author_minutes_read int,
		unknown_author_amount int,
		author_distributions subscriptions.subscription_distribution_author_report[]
	);

CREATE FUNCTION
	subscriptions.run_distribution_report_for_period_calculation(
		provider text,
		provider_period_id text
	)
RETURNS
	subscriptions.subscription_distribution_report
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		(
			SELECT
				coalesce(period.prorated_price_amount, price_level.amount)
			FROM
				core.subscription_period AS period
				JOIN
					subscriptions.price_level ON
						period.provider = price_level.provider AND
						period.provider_price_id = price_level.provider_price_id
			WHERE
				period.provider = run_distribution_report_for_period_calculation.provider::core.subscription_provider AND
				period.provider_period_id = run_distribution_report_for_period_calculation.provider_period_id
		),
		calculation.platform_amount,
		CASE
			WHEN
				run_distribution_report_for_period_calculation.provider = 'apple'
			THEN
				calculation.provider_amount
			ELSE
				0
		END,
		CASE
			WHEN
				run_distribution_report_for_period_calculation.provider = 'stripe'
			THEN
				calculation.provider_amount
			ELSE
				0
		END,
		calculation.unknown_author_minutes_read,
		calculation.unknown_author_amount,
		ARRAY (
			SELECT
				(
					author.id,
					author.name,
					author.slug,
					author_distribution.minutes_read,
					author_distribution.amount
				)::subscriptions.subscription_distribution_author_report
			FROM
				unnest(calculation.author_distributions) AS author_distribution (
					author_id,
					minutes_read,
					amount
				)
				JOIN
					core.author ON
						author_distribution.author_id = author.id
		)
	FROM
		subscriptions.calculate_distribution_for_period(
			provider := run_distribution_report_for_period_calculation.provider,
			provider_period_id := run_distribution_report_for_period_calculation.provider_period_id
		) AS calculation (
			platform_amount,
			provider_amount,
			unknown_author_minutes_read,
			unknown_author_amount,
			author_distributions
		);
$$;

CREATE FUNCTION
	subscriptions.create_distribution_for_period(
		provider text,
		provider_period_id text
	)
RETURNS
	SETOF core.subscription_period_distribution
LANGUAGE
	plpgsql
AS $$
-- ON CONFLICT column names cannot be distinguished from parameters in plpgsql
#variable_conflict use_column
<<locals>>
DECLARE
	calculation subscriptions.subscription_distribution_calculation;
	distribution core.subscription_period_distribution;
BEGIN
	-- first run the calculation
	SELECT
		result.*
	INTO
		locals.calculation
	FROM
		subscriptions.calculate_distribution_for_period(
			provider := create_distribution_for_period.provider,
			provider_period_id := create_distribution_for_period.provider_period_id
		) AS result;
	-- attempt to insert the period distribution
	INSERT INTO
		core.subscription_period_distribution (
			provider,
			provider_period_id,
			date_created,
			platform_amount,
			provider_amount,
			unknown_author_minutes_read,
			unknown_author_amount
		)
	VALUES (
		create_distribution_for_period.provider::core.subscription_provider,
		create_distribution_for_period.provider_period_id,
		core.utc_now(),
		locals.calculation.platform_amount,
		locals.calculation.provider_amount,
		locals.calculation.unknown_author_minutes_read,
		locals.calculation.unknown_author_amount
	)
	ON CONFLICT (
		provider,
		provider_period_id
	)
	DO NOTHING
	RETURNING
		*
	INTO
		locals.distribution;
	-- check if the insert was successful
	IF
		NOT (locals.distribution IS NULL)
	THEN
		-- clear to insert author distributions
		INSERT INTO
			core.subscription_period_author_distribution (
				provider,
				provider_period_id,
				author_id,
				minutes_read,
				amount
			)
		SELECT
			locals.distribution.provider,
			locals.distribution.provider_period_id,
			author_distribution.author_id,
			author_distribution.minutes_read,
			author_distribution.amount
		FROM
			unnest(locals.calculation.author_distributions) AS author_distribution (
				author_id,
				minutes_read,
				amount
			);
		-- return distribution
		RETURN NEXT
			locals.distribution;
	END IF;
END;
$$;

CREATE FUNCTION
	subscriptions.create_distributions_for_lapsed_periods(
		user_account_id bigint
	)
RETURNS
	SETOF core.subscription_period_distribution
LANGUAGE
	sql
AS $$
	WITH completed_period AS (
		SELECT
			period.provider,
			period.provider_period_id
		FROM
			core.subscription_period AS period
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account ON
					subscription.provider = subscription_account.provider AND
					subscription.provider_account_id = subscription_account.provider_account_id
			LEFT JOIN
				core.subscription_period_distribution AS distribution ON
					period.provider = distribution.provider AND
					period.provider_period_id = distribution.provider_period_id
		WHERE
			CASE
				WHEN
					create_distributions_for_lapsed_periods.user_account_id IS NOT NULL
				THEN
					subscription_account.user_account_id = create_distributions_for_lapsed_periods.user_account_id
				ELSE
					TRUE
			END AND
			period.renewal_grace_period_end_date < core.utc_now() AND
			period.date_refunded IS NULL AND
			distribution.provider_period_id IS NULL
		)
	SELECT
		(distribution).*
	FROM
		(
			SELECT
				subscriptions.create_distribution_for_period(
					provider := completed_period.provider::text,
					provider_period_id := completed_period.provider_period_id
				)
			FROM
				completed_period
		) AS result (distribution);
$$;

CREATE FUNCTION
	subscriptions.run_distribution_report_for_period_distributions(
		user_account_id bigint
	)
RETURNS
	subscriptions.subscription_distribution_report
LANGUAGE
	sql
STABLE
AS $$
	WITH user_distribution AS (
		SELECT
			distribution.provider,
			distribution.provider_period_id,
			coalesce(period.prorated_price_amount, price_level.amount) AS subscription_amount,
			distribution.platform_amount,
			CASE
				WHEN
					distribution.provider = 'apple'::core.subscription_provider
				THEN
					distribution.provider_amount
				ELSE
					0
			END AS apple_amount,
			CASE
				WHEN
					distribution.provider = 'stripe'::core.subscription_provider
				THEN
					distribution.provider_amount
				ELSE
					0
			END AS stripe_amount,
			distribution.unknown_author_minutes_read,
			distribution.unknown_author_amount
		FROM
			core.subscription_period_distribution AS distribution
			JOIN
				core.subscription_period AS period ON
					period.provider = distribution.provider AND
					period.provider_period_id = distribution.provider_period_id
			JOIN
				subscriptions.price_level ON
					period.provider = price_level.provider AND
					period.provider_price_id = price_level.provider_price_id
			JOIN
				core.subscription ON
					subscription.provider = period.provider AND
					subscription.provider_subscription_id = period.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
		WHERE
			account.user_account_id = run_distribution_report_for_period_distributions.user_account_id AND
			period.date_refunded IS NULL
	)
	SELECT
		coalesce(
			sum(user_distribution.subscription_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.platform_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.apple_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.stripe_amount)::int,
			0
		),
		coalesce(
			sum(user_distribution.unknown_author_minutes_read)::int,
			0
		),
		coalesce(
			sum(user_distribution.unknown_author_amount)::int,
			0
		),
		ARRAY (
			SELECT
				(
					author.id,
					author.name,
					author.slug,
					sum(author_distribution.minutes_read),
					sum(author_distribution.amount)
				)::subscriptions.subscription_distribution_author_report
			FROM
				user_distribution
				JOIN
					core.subscription_period_author_distribution AS author_distribution ON
						user_distribution.provider = author_distribution.provider AND
						user_distribution.provider_period_id = author_distribution.provider_period_id
				JOIN
					core.author ON
						author_distribution.author_id = author.id
			GROUP BY
				author.id
		)
	FROM
		user_distribution;
$$;

CREATE FUNCTION
	subscriptions.run_author_distribution_report_for_period_distributions(
		author_id bigint
	)
RETURNS
	subscriptions.subscription_distribution_author_report
LANGUAGE
	sql
STABLE
AS $$
	WITH author_distribution_totals AS (
		SELECT
			coalesce(
				sum(author_distribution.minutes_read)::int,
				0
			) AS minutes_read,
			coalesce(
				sum(author_distribution.amount)::int,
				0
			) AS amount
		FROM
			core.subscription_period_author_distribution AS author_distribution
			JOIN
				core.subscription_period AS period ON
					author_distribution.provider = period.provider AND
					author_distribution.provider_period_id = period.provider_period_id
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
		WHERE
			author_distribution.author_id = run_author_distribution_report_for_period_distributions.author_id AND
			period.date_refunded IS NULL AND
			account.environment = 'production'::core.subscription_environment
	)
	SELECT
		author.id,
		author.name,
		author.slug,
		(
			SELECT
				author_distribution_totals.minutes_read
			FROM
				author_distribution_totals
		),
		(
			SELECT
				author_distribution_totals.amount
			FROM
				author_distribution_totals
		)
	FROM
		core.author
	WHERE
		author.id = run_author_distribution_report_for_period_distributions.author_id;
$$;

CREATE FUNCTION
	subscriptions.calculate_allocation_for_all_periods()
RETURNS
	subscriptions.subscription_allocation_calculation
LANGUAGE
	sql
STABLE
AS $$
	WITH allocation AS (
		SELECT
			(
				subscriptions.calculate_allocation_for_period(
					provider := period.provider,
					subscription_amount := coalesce(
						period.prorated_price_amount,
						price_level.amount
					),
					payment_method_country := payment_method.country
				)
			).*
		FROM
			core.subscription_period AS period
			JOIN
				core.subscription ON
					period.provider = subscription.provider AND
					period.provider_subscription_id = subscription.provider_subscription_id
			JOIN
				core.subscription_account AS account ON
					subscription.provider = account.provider AND
					subscription.provider_account_id = account.provider_account_id
			JOIN
				subscriptions.price_level ON
					period.provider = price_level.provider AND
					period.provider_price_id = price_level.provider_price_id
			LEFT JOIN
				core.subscription_payment_method AS payment_method ON
					period.provider = payment_method.provider AND
					period.provider_payment_method_id = payment_method.provider_payment_method_id
		WHERE
			period.payment_status = 'succeeded'::core.subscription_payment_status AND
			period.date_refunded IS NULL AND
			account.environment = 'production'::core.subscription_environment
	)
	SELECT
		sum(allocation.platform_amount)::int,
		sum(allocation.provider_amount)::int,
		sum(allocation.author_amount)::int
	FROM
		allocation;
$$;