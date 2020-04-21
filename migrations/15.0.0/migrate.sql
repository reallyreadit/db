-- temporarily drop functions that reference user_account_api.auth_service_account
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
    provider_user_name text,
    provider_user_handle text,
    real_user_rating text,
    sign_up_analytics text
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
DROP FUNCTION user_account_api.update_auth_service_account_user(
    identity_id bigint,
    email_address text,
    is_email_address_private boolean,
    name text,
    handle text
);

-- drop auth_service_integration_preference
DROP FUNCTION user_account_api.set_auth_service_account_integration_preference(
    identity_id bigint,
    is_post_enabled boolean
);
DROP VIEW user_account_api.auth_service_account;
DROP VIEW user_account_api.current_auth_service_integration_preference;
DROP TABLE core.auth_service_integration_preference;

-- recreate user_account_api.auth_service_account
CREATE VIEW user_account_api.auth_service_account AS
SELECT
    identity.id AS identity_id,
    identity.date_created AS date_identity_created,
    identity.sign_up_analytics AS identity_sign_up_analytics,
    identity.provider,
    identity.provider_user_id,
    current_service_user.email_address AS provider_user_email_address,
    coalesce(current_service_user.is_email_address_private, false) AS is_email_address_private,
    current_service_user.name AS provider_user_name,
    current_service_user.handle AS provider_user_handle,
    association.date_associated AS date_user_account_associated,
    association.user_account_id AS associated_user_account_id,
    current_active_access_token.token_value AS access_token_value,
    current_active_access_token.token_secret AS access_token_secret
FROM
    core.auth_service_identity AS identity
    JOIN user_account_api.current_auth_service_user AS current_service_user ON
        current_service_user.identity_id = identity.id
    LEFT JOIN core.auth_service_association AS association ON
        association.identity_id = identity.id AND
        association.date_dissociated IS NULL
    LEFT JOIN user_account_api.current_auth_service_access_token AS current_active_access_token ON
        current_active_access_token.identity_id = identity.id AND
        current_active_access_token.date_revoked IS NULL;

-- add has_linked_twitter_account to user_account
ALTER TABLE
    core.user_account
ADD COLUMN
    has_linked_twitter_account boolean NOT NULL DEFAULT false;

-- disassociate auth service accounts with revoked access tokens
UPDATE
    core.auth_service_association
SET
    date_dissociated = revoked_current_access_token.date_revoked
FROM
    (
        SELECT
            current_access_token.identity_id,
            current_access_token.date_revoked
        FROM
            user_account_api.current_auth_service_access_token AS current_access_token
        WHERE
            current_access_token.date_revoked IS NOT NULL
    ) AS revoked_current_access_token
WHERE
    revoked_current_access_token.identity_id = auth_service_association.identity_id AND
    auth_service_association.date_dissociated IS NULL;

-- set current has_linked_twitter_account value
UPDATE
    core.user_account
SET
    has_linked_twitter_account = true
FROM
    (
        SELECT DISTINCT
            auth_service_account.associated_user_account_id
        FROM
            user_account_api.auth_service_account
        WHERE
            auth_service_account.associated_user_account_id IS NOT NULL AND
            auth_service_account.provider = 'twitter'
    ) AS twitter_account
WHERE
    twitter_account.associated_user_account_id = user_account.id;

-- remove NOT NULL constraint from auth_service_authentication
ALTER TABLE
    core.auth_service_authentication
ALTER COLUMN
    session_id DROP NOT NULL;

-- update user_account_api.associate_auth_service_account to set user_account.has_linked_twitter_account
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
    -- update cached user_account.has_linked_twitter_account if this is a twitter account
    IF (
        SELECT
            identity.provider = 'twitter'
        FROM
            auth_service_identity AS identity
        WHERE
            identity.id = associate_auth_service_account.identity_id
    ) THEN
        UPDATE
            core.user_account
        SET
            has_linked_twitter_account = true
        WHERE
            user_account.id = associate_auth_service_account.user_account_id;
    END IF;
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

-- create user_account_api.disassociate_auth_service_account to set user_account.has_linked_twitter_account
CREATE FUNCTION user_account_api.disassociate_auth_service_account(
    identity_id bigint
)
RETURNS SETOF user_account_api.auth_service_account
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    disassociated_user_account_id bigint;
BEGIN
    -- update the association
    UPDATE
        core.auth_service_association
    SET
        date_dissociated = core.utc_now()
    WHERE
        auth_service_association.identity_id = disassociate_auth_service_account.identity_id AND
        auth_service_association.date_dissociated IS NULL
    RETURNING
        auth_service_association.user_account_id INTO locals.disassociated_user_account_id;
    -- revoke access token if present
    UPDATE
        core.auth_service_access_token
    SET
        date_revoked = core.utc_now()
    FROM
        user_account_api.current_auth_service_access_token
    WHERE
        auth_service_access_token.identity_id = disassociate_auth_service_account.identity_id AND
        auth_service_access_token.identity_id = current_auth_service_access_token.identity_id AND
        auth_service_access_token.date_created = current_auth_service_access_token.date_created AND
        auth_service_access_token.date_revoked IS NULL;
    -- update cached user_account.has_linked_twitter_account if this was the last twitter account
    IF (
        NOT EXISTS (
            SELECT
                *
            FROM
                user_account_api.auth_service_account
            WHERE
                auth_service_account.associated_user_account_id = locals.disassociated_user_account_id AND
                auth_service_account.provider = 'twitter'
        )
    )
    THEN
        UPDATE
            core.user_account
        SET
            has_linked_twitter_account = false
        WHERE
            user_account.id = locals.disassociated_user_account_id;
    END IF;
    -- return from the view
    RETURN QUERY
    SELECT
        *
    FROM
        user_account_api.auth_service_account AS account
    WHERE
        account.identity_id = disassociate_auth_service_account.identity_id;
END;
$$;

-- remove user_account_api.revoke_auth_service_access_token
CREATE OR REPLACE FUNCTION user_account_api.store_auth_service_access_token(
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
        WHERE
            token.identity_id = store_auth_service_access_token.identity_id
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
            UPDATE
                core.auth_service_access_token
            SET
                date_revoked = core.utc_now()
            WHERE
                auth_service_access_token.token_value = locals.current_token_value;
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
DROP FUNCTION user_account_api.revoke_auth_service_access_token(
    token_value text
);

-- recreate temporarily dropped functions that reference user_account_api.auth_service_account
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