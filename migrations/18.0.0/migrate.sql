-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE TYPE
    core.display_theme AS ENUM (
        'light',
        'dark'
    );

CREATE TABLE
    core.display_preference (
        id bigserial NOT NULL,
        user_account_id bigint NOT NULL REFERENCES core.user_account (id),
        last_modified timestamp NOT NULL DEFAULT core.utc_now(),
        theme core.display_theme NOT NULL,
        text_size int NOT NULL,
        hide_links bool NOT NULL
    );

CREATE VIEW
    user_account_api.current_display_preference AS
SELECT
    current_preference.id,
    current_preference.user_account_id,
    current_preference.last_modified,
    current_preference.theme,
    current_preference.text_size,
    current_preference.hide_links
FROM
    core.display_preference AS current_preference
    LEFT JOIN
        core.display_preference AS later_preference ON
            later_preference.user_account_id = current_preference.user_account_id AND
            later_preference.last_modified > current_preference.last_modified
WHERE
    later_preference.id IS NULL;

CREATE FUNCTION
    user_account_api.set_display_preference(
        user_account_id bigint,
        theme text,
        text_size int,
        hide_links bool
    )
RETURNS SETOF
    core.display_preference
LANGUAGE
    plpgsql
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
    	core.display_preference AS preference
    WHERE
    	preference.user_account_id = set_display_preference.user_account_id AND
    	preference.last_modified >= core.utc_now() - '1 hour'::interval
    ORDER BY
    	preference.last_modified DESC
    LIMIT
        1
    FOR UPDATE;
    -- update the existing record or create a new one
    IF locals.existing_preference_id IS NOT NULL THEN
        RETURN QUERY
		UPDATE
		    core.display_preference
        SET
            last_modified = core.utc_now(),
            theme = set_display_preference.theme::core.display_theme,
            text_size = set_display_preference.text_size,
            hide_links = set_display_preference.hide_links
        WHERE
        	display_preference.id = locals.existing_preference_id
        RETURNING
            *;
	ELSE
	    RETURN QUERY
    	INSERT INTO
    	    core.display_preference (
    	        user_account_id,
    	        theme,
    	        text_size,
    	        hide_links
			)
		VALUES (
		    set_display_preference.user_account_id,
		    set_display_preference.theme::core.display_theme,
		    set_display_preference.text_size,
		    set_display_preference.hide_links
		)
		RETURNING
		    *;
    END IF;
END;
$$;

CREATE FUNCTION
    user_account_api.get_display_preference(
        user_account_id bigint
    )
RETURNS SETOF
    core.display_preference
LANGUAGE
    sql
STABLE
AS $$
    SELECT
        *
    FROM
        user_account_api.current_display_preference
    WHERE
        current_display_preference.user_account_id = get_display_preference.user_account_id;
$$;

DROP FUNCTION user_account_api.create_user_account(
    name text,
    email text,
    password_hash bytea,
    password_salt bytea,
    time_zone_id bigint,
    analytics text
);
CREATE FUNCTION user_account_api.create_user_account(
    name text,
    email text,
    password_hash bytea,
    password_salt bytea,
    time_zone_id bigint,
    theme text,
    analytics text
)
RETURNS SETOF
    core.user_account
LANGUAGE
    plpgsql
AS $$
<<locals>>
DECLARE
    new_user core.user_account;
BEGIN
    -- create new user
    INSERT INTO
        core.user_account (
            name,
            email,
            password_hash,
            password_salt,
            time_zone_id,
            creation_analytics
        )
    VALUES
        (
            trim(
                create_user_account.name
            ),
            trim(
                create_user_account.email
            ),
            create_user_account.password_hash,
            create_user_account.password_salt,
            create_user_account.time_zone_id,
            create_user_account.analytics::json
        )
    RETURNING
        *
    INTO
        locals.new_user;
    -- set initial notification preference
    INSERT INTO
        core.notification_preference (
            user_account_id
        )
	VALUES (
	    locals.new_user.id
    );
    -- set initial display preference if a theme is provided
     IF create_user_account.theme IS NOT NULL THEN
        PERFORM
            user_account_api.set_display_preference(
                user_account_id => locals.new_user.id,
                theme => create_user_account.theme,
                text_size => 1,
                hide_links => TRUE
            );
    END IF;
    -- return user
    RETURN NEXT
        locals.new_user;
END;
$$;