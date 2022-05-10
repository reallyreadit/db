-- Making Readup free to use!

-- Don't assign free credits during account creation.
CREATE OR REPLACE FUNCTION user_account_api.create_user_account(
	name text,
	email text,
	password_hash bytea,
	password_salt bytea,
	time_zone_id bigint,
	theme text,
	analytics text
)
RETURNS
	SETOF core.user_account
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