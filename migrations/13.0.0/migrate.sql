-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- update enums
ALTER TYPE
    core.auth_service_provider
ADD VALUE
    'twitter';

ALTER TYPE
    core.auth_service_real_user_rating
ADD VALUE
    'verified';

ALTER TYPE
    core.auth_service_association_method
ADD VALUE
    'link';

-- update core.auth_service_identity to use have optional sign_up_analytics
ALTER TABLE
    core.auth_service_identity
ALTER COLUMN
    creation_analytics DROP NOT NULL;

ALTER TABLE
    core.auth_service_identity
RENAME COLUMN
    creation_analytics
TO
    sign_up_analytics;

-- migrate core.auth_service_email_address to auth_service_user
ALTER TABLE
    core.auth_service_email_address
ALTER COLUMN
    provider_user_email_address DROP NOT NULL;

ALTER TABLE
    core.auth_service_email_address
RENAME COLUMN
    provider_user_email_address
TO
    email_address;

ALTER TABLE
    core.auth_service_email_address
RENAME COLUMN
    is_private
TO
    is_email_address_private;

ALTER TABLE
    core.auth_service_email_address
ADD COLUMN
    name text,
ADD COLUMN
    handle text;

-- rename core.auth_service_email_address to auth_service_user
ALTER TABLE
    core.auth_service_email_address
RENAME TO
    auth_service_user;

ALTER TABLE
    core.auth_service_user
ADD CONSTRAINT
    auth_service_user_identifier_check
CHECK
    (email_address IS NOT NULL OR handle IS NOT NULL);

ALTER TABLE
    core.auth_service_user
RENAME CONSTRAINT
    auth_service_email_address_pkey TO auth_service_user_pkey;

ALTER TABLE
    core.auth_service_user
RENAME CONSTRAINT
    auth_service_email_address_identity_id_fkey TO auth_service_user_identity_id_fkey;

-- create new tables
CREATE TABLE core.auth_service_request_token (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    provider core.auth_service_provider NOT NULL,
    token_value text NOT NULL UNIQUE,
    token_secret text NOT NULL,
    date_cancelled timestamp,
    sign_up_analytics jsonb
);

CREATE TABLE core.auth_service_access_token (
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    last_stored timestamp NOT NULL DEFAULT core.utc_now(),
    identity_id bigint NOT NULL REFERENCES core.auth_service_identity (id),
    request_id bigint NOT NULL REFERENCES core.auth_service_request_token (id),
    token_value text NOT NULL UNIQUE,
    token_secret text NOT NULL,
    date_revoked timestamp,
    PRIMARY KEY (
        date_created,
        identity_id
    )
);

CREATE UNIQUE INDEX
    auth_service_access_token_unique_valid_identity_id ON
    	core.auth_service_access_token (identity_id)
WHERE
	date_revoked IS NULL;

CREATE TABLE core.auth_service_integration_preference (
    id bigserial PRIMARY KEY,
    last_modified timestamp NOT NULL DEFAULT core.utc_now(),
    identity_id bigint NOT NULL REFERENCES core.auth_service_identity (id),
    is_post_enabled boolean NOT NULL
);

CREATE TABLE core.auth_service_post (
    id bigserial PRIMARY KEY,
    identity_id bigint NOT NULL REFERENCES core.auth_service_identity (id),
    date_posted timestamp NOT NULL DEFAULT core.utc_now(),
    comment_id bigint REFERENCES core.comment (id),
    silent_post_id bigint REFERENCES core.silent_post (id),
    content text NOT NULL,
    provider_post_id text NOT NULL
);

ALTER TABLE
    core.auth_service_post
ADD CONSTRAINT
    auth_service_post_reference_check
CHECK
    (comment_id IS NOT NULL OR silent_post_id IS NOT NULL);

-- create new views
CREATE VIEW
    user_account_api.current_auth_service_user AS
SELECT
    service_user.date_created,
    service_user.identity_id,
    service_user.email_address,
    service_user.is_email_address_private,
    service_user.name,
    service_user.handle
FROM
    core.auth_service_user AS service_user
    LEFT JOIN
        core.auth_service_user AS newer_service_user ON
            newer_service_user.identity_id = service_user.identity_id AND
            newer_service_user.date_created > service_user.date_created
WHERE
    newer_service_user.date_created IS NULL;

CREATE VIEW
    user_account_api.current_auth_service_access_token AS
SELECT
    token.date_created,
    token.last_stored,
    token.identity_id,
    token.request_id,
    token.token_value,
    token.token_secret,
    token.date_revoked
FROM
    core.auth_service_access_token AS token
    LEFT JOIN
        core.auth_service_access_token AS newer_token ON
            newer_token.identity_id = token.identity_id AND
            newer_token.date_created > token.date_created
WHERE
    newer_token.date_created IS NULL;

CREATE VIEW
    user_account_api.current_auth_service_integration_preference AS
SELECT
    preference.id,
    preference.last_modified,
    preference.identity_id,
    preference.is_post_enabled
FROM
    core.auth_service_integration_preference AS preference
    LEFT JOIN
        core.auth_service_integration_preference AS newer_preference ON
            newer_preference.identity_id = preference.identity_id AND
            newer_preference.last_modified > preference.last_modified
WHERE
    newer_preference.id IS NULL;

-- drop functions referencing user_account_api.auth_service_account
DROP FUNCTION user_account_api.associate_auth_service_account(
    identity_id bigint,
    authentication_id bigint,
    user_account_id bigint,
    association_method text
);
DROP FUNCTION user_account_api.create_auth_service_identity(
    provider text,
    provider_user_id text,
    provider_user_email_address text,
    is_email_address_private boolean,
    real_user_rating text,
    analytics text
);
DROP FUNCTION user_account_api.get_auth_service_account_by_identity_id(
    identity_id bigint
);
DROP FUNCTION user_account_api.get_auth_service_account_by_provider_user_id(
    provider text,
    provider_user_id text
);
DROP FUNCTION user_account_api.get_auth_service_accounts_for_user_account(
    user_account_id bigint
);
DROP FUNCTION user_account_api.update_auth_service_account_email_address(
    identity_id bigint,
    email_address text,
    is_private boolean
);

-- drop and recreate user_account_api.auth_service_account
DROP VIEW user_account_api.auth_service_account;

CREATE VIEW user_account_api.auth_service_account AS
SELECT
    identity.id AS identity_id,
    identity.date_created AS date_identity_created,
    identity.sign_up_analytics AS identity_sign_up_analytics,
    identity.provider,
    identity.provider_user_id,
    current_service_user.email_address AS provider_user_email_address,
    coalesce(current_service_user.is_email_address_private, FALSE) AS is_email_address_private,
    current_service_user.name AS provider_user_name,
    current_service_user.handle AS provider_user_handle,
    association.date_associated AS date_user_account_associated,
    association.user_account_id AS associated_user_account_id,
    current_active_access_token.token_value AS access_token_value,
    current_active_access_token.token_secret AS access_token_secret,
    coalesce(current_integration_preference.is_post_enabled, FALSE) AS is_post_integration_enabled
FROM
    core.auth_service_identity AS identity
    JOIN
        user_account_api.current_auth_service_user AS current_service_user ON
            current_service_user.identity_id = identity.id
    LEFT JOIN
        core.auth_service_association AS association ON
            association.identity_id = identity.id AND
            association.date_dissociated IS NULL
    LEFT JOIN
        user_account_api.current_auth_service_access_token AS current_active_access_token ON
            current_active_access_token.identity_id = identity.id AND
            current_active_access_token.date_revoked IS NULL
    LEFT JOIN
        user_account_api.current_auth_service_integration_preference AS current_integration_preference ON
            current_integration_preference.identity_id = identity.id;

-- recreate existing functions (unchanged)
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
CREATE FUNCTION user_account_api.get_auth_service_account_by_identity_id(
    identity_id bigint
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE sql STABLE
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
LANGUAGE sql STABLE
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
LANGUAGE sql STABLE
AS $$
    SELECT
    	*
    FROM
    	user_account_api.auth_service_account
    WHERE
        auth_service_account.associated_user_account_id = get_auth_service_accounts_for_user_account.user_account_id;
$$;

-- recreate existing functions (updated)
CREATE FUNCTION user_account_api.create_auth_service_identity(
    provider text,
    provider_user_id text,
    provider_user_email_address text,
    is_email_address_private boolean,
    provider_user_name text,
    provider_user_handle text,
    real_user_rating text,
    sign_up_analytics text
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
			sign_up_analytics
    	)
    VALUES (
      	create_auth_service_identity.provider::core.auth_service_provider,
        create_auth_service_identity.provider_user_id,
        create_auth_service_identity.real_user_rating::core.auth_service_real_user_rating,
        create_auth_service_identity.sign_up_analytics::jsonb
	)
	RETURNING
		id INTO locals.identity_id;
    -- create the user
    INSERT INTO
        core.auth_service_user (
        	identity_id,
        	email_address,
        	is_email_address_private,
        	name,
        	handle
		)
	VALUES (
	    locals.identity_id,
	    create_auth_service_identity.provider_user_email_address,
	    create_auth_service_identity.is_email_address_private,
	    create_auth_service_identity.provider_user_name,
	    create_auth_service_identity.provider_user_handle
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
CREATE FUNCTION user_account_api.update_auth_service_account_user(
    identity_id bigint,
    email_address text,
    is_email_address_private boolean,
    name text,
    handle text
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
BEGIN
    -- insert the new user
    INSERT INTO
        core.auth_service_user (
            identity_id,
            email_address,
            is_email_address_private,
            name,
            handle
        )
    VALUES (
        update_auth_service_account_user.identity_id,
        update_auth_service_account_user.email_address,
        update_auth_service_account_user.is_email_address_private,
        update_auth_service_account_user.name,
        update_auth_service_account_user.handle
    );
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = update_auth_service_account_user.identity_id;
END;
$$;

-- create new functions
CREATE FUNCTION user_account_api.create_auth_service_request_token(
    provider text,
    token_value text,
    token_secret text,
    sign_up_analytics text
)
RETURNS SETOF core.auth_service_request_token
LANGUAGE SQL
AS $$
    INSERT INTO
        core.auth_service_request_token (
            provider,
            token_value,
            token_secret,
            sign_up_analytics
        )
    VALUES (
        create_auth_service_request_token.provider::core.auth_service_provider,
        create_auth_service_request_token.token_value,
        create_auth_service_request_token.token_secret,
        create_auth_service_request_token.sign_up_analytics::jsonb
    )
    RETURNING
        *;
$$;

CREATE FUNCTION user_account_api.cancel_auth_service_request_token(
    token_value text
)
RETURNS SETOF core.auth_service_request_token
LANGUAGE SQL
AS $$
    UPDATE
        core.auth_service_request_token
    SET
        date_cancelled = core.utc_now()
    WHERE
        auth_service_request_token.token_value = cancel_auth_service_request_token.token_value
    RETURNING
        *;
$$;

CREATE FUNCTION user_account_api.get_auth_service_request_token(
    token_value text
)
RETURNS SETOF core.auth_service_request_token
LANGUAGE SQL
AS $$
    SELECT
        *
    FROM
        core.auth_service_request_token
    WHERE
        auth_service_request_token.token_value = get_auth_service_request_token.token_value;
$$;

CREATE FUNCTION user_account_api.revoke_auth_service_access_token(
    token_value text
)
RETURNS SETOF core.auth_service_access_token
LANGUAGE SQL
AS $$
    UPDATE
        core.auth_service_access_token
    SET
        date_revoked = core.utc_now()
    WHERE
        auth_service_access_token.token_value = revoke_auth_service_access_token.token_value
    RETURNING
        *;
$$;

CREATE FUNCTION user_account_api.store_auth_service_access_token(
    identity_id bigint,
    request_id bigint,
    token_value text,
    token_secret text
)
RETURNS SETOF core.auth_service_access_token
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    current_token_value CONSTANT text := (
        SELECT
            token.token_value
        FROM
            user_account_api.current_auth_service_access_token AS token
    );
BEGIN
    IF locals.current_token_value = store_auth_service_access_token.token_value THEN
        RETURN QUERY
        UPDATE
            core.auth_service_access_token AS access_token
        SET
            last_stored = core.utc_now()
        WHERE
            access_token.token_value = locals.current_token_value
        RETURNING
            *;
    ELSE
        IF locals.current_token_value IS NOT NULL THEN
            PERFORM user_account_api.revoke_auth_service_access_token(
                token_value => locals.current_token_value
            );
        END IF;
        RETURN QUERY
        INSERT INTO
            core.auth_service_access_token (
                identity_id,
                request_id,
                token_value,
                token_secret
            )
        VALUES (
            store_auth_service_access_token.identity_id,
            store_auth_service_access_token.request_id,
            store_auth_service_access_token.token_value,
            store_auth_service_access_token.token_secret
        )
        RETURNING
            *;
    END IF;
END;
$$;

CREATE FUNCTION user_account_api.set_auth_service_account_integration_preference(
    identity_id bigint,
    is_post_enabled bool
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    existing_preference_id bigint;
BEGIN
    -- check for an existing record
	SELECT
		preference.id
    INTO
    	locals.existing_preference_id
    FROM
    	core.auth_service_integration_preference AS preference
    WHERE
    	preference.identity_id = set_auth_service_account_integration_preference.identity_id AND
    	preference.last_modified >= core.utc_now() - '1 hour'::interval
    ORDER BY
    	preference.last_modified DESC
    LIMIT 1
    FOR UPDATE;
    -- update the existing record or create a new one
    IF existing_preference_id IS NOT NULL THEN
		UPDATE
		    core.auth_service_integration_preference
        SET
            last_modified = core.utc_now(),
            is_post_enabled = set_auth_service_account_integration_preference.is_post_enabled
        WHERE
        	id = locals.existing_preference_id;
	ELSE
    	INSERT INTO
    	    core.auth_service_integration_preference (
    	        identity_id,
    	        is_post_enabled
			)
		VALUES (
		    set_auth_service_account_integration_preference.identity_id,
		    set_auth_service_account_integration_preference.is_post_enabled
		);
    END IF;
    -- return from view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account
    WHERE
        auth_service_account.identity_id = set_auth_service_account_integration_preference.identity_id;
END;
$$;

CREATE FUNCTION user_account_api.create_auth_service_post(
    identity_id bigint,
    comment_id bigint,
    silent_post_id bigint,
    content text,
    provider_post_id text
)
RETURNS SETOF core.auth_service_post
LANGUAGE SQL
AS $$
    INSERT INTO
        core.auth_service_post (
            identity_id,
            comment_id,
            silent_post_id,
            content,
            provider_post_id
        )
    VALUES (
        create_auth_service_post.identity_id,
        create_auth_service_post.comment_id,
        create_auth_service_post.silent_post_id,
        create_auth_service_post.content,
        create_auth_service_post.provider_post_id
    )
    RETURNING
        *;
$$;