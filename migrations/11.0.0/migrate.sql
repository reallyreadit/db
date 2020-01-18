-- migrate user_account creation_analytics
UPDATE
    core.user_account
SET
    creation_analytics = (creation_analytics - 'marketing_screen_variant') || jsonb_build_object('marketing_variant', creation_analytics->>'marketing_screen_variant')
WHERE
    creation_analytics IS NOT NULL;

DROP FUNCTION analytics.get_user_account_creations(
    start_date timestamp without time zone,
    end_date timestamp without time zone
);
CREATE FUNCTION analytics.get_user_account_creations(
    start_date timestamp without time zone,
    end_date timestamp without time zone
)
RETURNS TABLE(
    id bigint,
    name text,
    date_created timestamp without time zone,
    time_zone_name text,
    client_mode text,
    marketing_variant integer,
    referrer_url text,
    initial_path text,
    current_path text,
    action text
)
LANGUAGE sql STABLE
AS $$
	SELECT
		user_account.id,
	    user_account.name,
	    user_account.date_created,
	    time_zone.name,
	    user_account.creation_analytics->'client'->>'mode',
	    (user_account.creation_analytics->>'marketing_variant')::int,
	    user_account.creation_analytics->>'referrer_url',
	    user_account.creation_analytics->>'initial_path',
	    user_account.creation_analytics->>'current_path',
	    user_account.creation_analytics->>'action'
	FROM
		user_account
    	LEFT JOIN time_zone
    		ON time_zone.id = user_account.time_zone_id
    WHERE
    	user_account.date_created <@ tsrange(start_date, end_date)
    ORDER BY
    	user_account.date_created DESC
$$;

-- remove password not null constraints for user_account
ALTER TABLE
    core.user_account
ALTER COLUMN
    password_hash DROP NOT NULL;
ALTER TABLE
    core.user_account
ALTER COLUMN
    password_salt DROP NOT NULL;

-- create new tables for identities from authentication services
CREATE TYPE core.auth_service_provider AS ENUM (
  	'apple'
);

CREATE TYPE core.auth_service_association_method AS ENUM (
  	'auto',
    'manual'
);

CREATE TYPE core.auth_service_real_user_rating AS ENUM (
  	'likely_real',
    'unknown',
    'unsupported'
);

CREATE TABLE core.auth_service_identity (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    provider core.auth_service_provider NOT NULL,
    provider_user_id text NOT NULL,
    real_user_rating core.auth_service_real_user_rating,
    creation_analytics jsonb NOT NULL,
    UNIQUE (
        provider,
        provider_user_id
    )
);

CREATE TABLE core.auth_service_email_address (
    date_created timestamp DEFAULT core.utc_now(),
	identity_id bigint REFERENCES core.auth_service_identity (id),
	provider_user_email_address text NOT NULL,
	is_private bool NOT NULL,
	PRIMARY KEY (
	    date_created,
	    identity_id
	)
);

CREATE TABLE core.auth_service_authentication (
    id bigserial PRIMARY KEY,
    date_authenticated timestamp NOT NULL DEFAULT core.utc_now(),
    identity_id bigint NOT NULL REFERENCES core.auth_service_identity (id),
    session_id text NOT NULL
);

CREATE TABLE core.auth_service_association (
	date_associated timestamp DEFAULT core.utc_now(),
	identity_id bigint REFERENCES core.auth_service_identity (id),
	authentication_id bigint NOT NULL REFERENCES core.auth_service_authentication (id) UNIQUE,
	user_account_id bigint NOT NULL REFERENCES core.user_account (id),
	association_method core.auth_service_association_method NOT NULL,
	date_dissociated timestamp,
	PRIMARY KEY (
	    date_associated,
	    identity_id
	)
);

CREATE UNIQUE INDEX
    auth_service_association_unique_associated_identity_id ON
    	core.auth_service_association (identity_id)
WHERE
	date_dissociated IS NULL;

CREATE TABLE core.auth_service_refresh_token (
    date_created timestamp DEFAULT core.utc_now(),
    identity_id bigint REFERENCES core.auth_service_identity (id),
    raw_value text NOT NULL,
    PRIMARY KEY (
        date_created,
        identity_id
    )
);

-- add optional auth_service_authentication reference to password_reset_request
ALTER TABLE
    core.password_reset_request
ADD COLUMN
    auth_service_authentication_id bigint REFERENCES core.auth_service_authentication (id);

-- update create_password_reset_request to take auth_service_authentication_id
DROP FUNCTION user_account_api.create_password_reset_request(user_account_id bigint);
CREATE FUNCTION user_account_api.create_password_reset_request(
    user_account_id bigint,
    auth_service_authentication_id bigint
)
RETURNS SETOF core.password_reset_request
LANGUAGE sql
AS $$
	INSERT INTO password_reset_request (
	    user_account_id,
	    email_address,
	    auth_service_authentication_id
	)
	VALUES (
	    user_account_id,
	    (
	        SELECT
	            email
	        FROM
	            core.user_account
	        WHERE
	            user_account.id = create_password_reset_request.user_account_id
	    ),
	    create_password_reset_request.auth_service_authentication_id
	)
	RETURNING
	    *;
$$;

-- create view for auth service accounts
CREATE VIEW user_account_api.auth_service_account AS (
	SELECT
		identity.id AS identity_id,
	    identity.date_created AS date_identity_created,
	    identity.creation_analytics AS identity_creation_analytics,
	    identity.provider,
	    identity.provider_user_id,
	    current_email_address.provider_user_email_address,
	    current_email_address.is_private AS is_email_address_private,
	    association.date_associated AS date_user_account_associated,
	    association.user_account_id AS associated_user_account_id
	FROM
		core.auth_service_identity AS identity
		JOIN (
		    SELECT
		    	email_address.identity_id,
		        email_address.provider_user_email_address,
		        email_address.is_private
		    FROM
		    	core.auth_service_email_address AS email_address
		    	LEFT JOIN core.auth_service_email_address AS newer_email_address
		    		ON (
		    		    newer_email_address.identity_id = email_address.identity_id AND
						newer_email_address.date_created > email_address.date_created
					)
		    WHERE
		    	newer_email_address.date_created IS NULL
		) AS current_email_address
			ON current_email_address.identity_id = identity.id
		LEFT JOIN core.auth_service_association AS association
			ON (
				association.identity_id = identity.id AND
				association.date_dissociated IS NULL
			)
);

-- create api for auth service accounts
CREATE FUNCTION user_account_api.get_auth_service_account_by_identity_id(
    identity_id bigint
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE sql
STABLE
AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.identity_id = get_auth_service_account_by_identity_id.identity_id;
$$;

CREATE FUNCTION user_account_api.get_auth_service_account_by_provider_user_id(
    provider text,
	provider_user_id text
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE sql
STABLE
AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.provider = get_auth_service_account_by_provider_user_id.provider::core.auth_service_provider AND
    	auth_service_account.provider_user_id = get_auth_service_account_by_provider_user_id.provider_user_id;
$$;

CREATE FUNCTION user_account_api.get_auth_service_accounts_for_user_account(
    user_account_id bigint
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE sql
STABLE
AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.associated_user_account_id = get_auth_service_accounts_for_user_account.user_account_id;
$$;

CREATE FUNCTION user_account_api.get_auth_service_authentication_by_id(
    authentication_id bigint
)
RETURNS SETOF core.auth_service_authentication
LANGUAGE sql
STABLE
AS $$
    SELECT
        *
    FROM
        core.auth_service_authentication AS authentication
    WHERE
        authentication.id =  get_auth_service_authentication_by_id.authentication_id;
$$;

CREATE FUNCTION user_account_api.create_auth_service_identity(
	provider text,
	provider_user_id text,
	provider_user_email_address text,
	is_email_address_private bool,
	real_user_rating text,
	analytics text
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    identity_id bigint;
BEGIN
	-- create the identity
    INSERT INTO
		core.auth_service_identity (
    		provider,
			provider_user_id,
			real_user_rating,
			creation_analytics
    	)
    VALUES (
      	create_auth_service_identity.provider::core.auth_service_provider,
        create_auth_service_identity.provider_user_id,
        create_auth_service_identity.real_user_rating::core.auth_service_real_user_rating,
        create_auth_service_identity.analytics::jsonb
	)
	RETURNING
		id INTO locals.identity_id;
    -- create the email address
    INSERT INTO
        core.auth_service_email_address (
        	identity_id,
        	provider_user_email_address,
        	is_private
		)
	VALUES (
	    locals.identity_id,
	    create_auth_service_identity.provider_user_email_address,
	    create_auth_service_identity.is_email_address_private
    );
	-- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = locals.identity_id;
END;
$$;

CREATE FUNCTION user_account_api.update_auth_service_account_email_address(
    identity_id bigint,
    email_address text,
	is_private bool
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
BEGIN
    -- insert the new email address
    INSERT INTO
        core.auth_service_email_address (
            identity_id,
            provider_user_email_address,
            is_private
        )
    VALUES (
        update_auth_service_account_email_address.identity_id,
        update_auth_service_account_email_address.email_address,
        update_auth_service_account_email_address.is_private
    );
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = update_auth_service_account_email_address.identity_id;
END;
$$;

CREATE FUNCTION user_account_api.associate_auth_service_account(
    identity_id bigint,
    authentication_id bigint,
    user_account_id bigint,
    association_method text
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
BEGIN
    -- insert the new association
    INSERT INTO
        core.auth_service_association (
            identity_id,
            authentication_id,
            user_account_id,
            association_method
        )
    VALUES (
        associate_auth_service_account.identity_id,
        associate_auth_service_account.authentication_id,
        associate_auth_service_account.user_account_id,
        associate_auth_service_account.association_method::core.auth_service_association_method
    );
     -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = associate_auth_service_account.identity_id;
END;
$$;

CREATE FUNCTION user_account_api.create_auth_service_authentication(
    identity_id bigint,
    session_id text
)
RETURNS SETOF core.auth_service_authentication
LANGUAGE sql
AS $$
    INSERT INTO
        core.auth_service_authentication (
            identity_id,
            session_id
        )
    VALUES (
        create_auth_service_authentication.identity_id,
        create_auth_service_authentication.session_id
    )
    RETURNING
        *;
$$;

CREATE FUNCTION user_account_api.create_auth_service_refresh_token(
    identity_id bigint,
    raw_value text
)
RETURNS SETOF core.auth_service_refresh_token
LANGUAGE sql
AS $$
    INSERT INTO
        core.auth_service_refresh_token (
            identity_id,
            raw_value
        )
    VALUES (
        create_auth_service_refresh_token.identity_id,
        create_auth_service_refresh_token.raw_value
    )
    RETURNING
        *;
$$;

-- create new function for querying articles by publisher slug
CREATE OR REPLACE VIEW community_reads.community_read AS
SELECT
    article.id,
    article.aotd_timestamp,
    article.word_count,
    article.hot_score,
    article.top_score,
    article.comment_count,
    article.read_count,
    article.average_rating_score,
    article.date_published,
    article.source_id
FROM
    core.article
WHERE (
    article.comment_count > 0 OR
    article.read_count > 1 OR
    article.average_rating_score IS NOT NULL OR
    article.silent_post_count > 0
);

CREATE FUNCTION community_reads.get_articles_by_source_slug(
    slug text,
    user_account_id bigint,
    page_number integer,
    page_size integer,
    min_length integer,
    max_length integer
)
RETURNS SETOF article_api.article_page_result
LANGUAGE sql STABLE
AS $$
    WITH publisher_article AS (
        SELECT
            community_read.id,
            community_read.date_published
        FROM
        	community_reads.community_read
        WHERE
            source_id = (
                SELECT
                    source.id
                FROM
                    core.source
                WHERE
                    source.slug = get_articles_by_source_slug.slug
            ) AND
			core.matches_article_length(
				community_read.word_count,
			    get_articles_by_source_slug.min_length,
			    get_articles_by_source_slug.max_length
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