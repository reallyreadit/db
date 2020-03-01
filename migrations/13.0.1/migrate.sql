-- added missing where clause
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