-- fixed null check on row variable
CREATE OR REPLACE FUNCTION
	notifications.register_push_device(
		user_account_id bigint,
		installation_id text,
		name text,
		token text
	)
RETURNS SETOF
	core.notification_push_device
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
	existing_device notifications.registered_push_device;
BEGIN
	-- check for existing registered device with matching installation_id
	SELECT
		*
	INTO
		locals.existing_device
	FROM
		notifications.registered_push_device AS device
	WHERE
		device.installation_id = register_push_device.installation_id
	FOR UPDATE;
	-- create a new registration if needed
	IF
		locals.existing_device IS NULL OR
		locals.existing_device.user_account_id != register_push_device.user_account_id OR
		locals.existing_device.token != register_push_device.token
	THEN
		-- unregister the existing device if the user or token has changed
		IF
		   locals.existing_device.id IS NOT NULL
		THEN
		   PERFORM
		   	notifications.unregister_push_device_by_installation_id(
		   	   installation_id => locals.existing_device.installation_id,
		   	   reason => (
		   	      CASE WHEN
							locals.existing_device.user_account_id != register_push_device.user_account_id
						THEN
							'user_change'
						ELSE
							'token_change'
						END
					)
		   	);
		END IF;
		-- unregister any other currently registered devices using the same token
		PERFORM
			notifications.unregister_push_device_by_token(
				token => register_push_device.token,
			   reason => 'reinstall'
			);
		-- create the registration and return the result
		RETURN QUERY
		INSERT INTO
			core.notification_push_device (
				user_account_id,
				installation_id,
				name,
				token
			)
		VALUES (
			register_push_device.user_account_id,
			register_push_device.installation_id,
			register_push_device.name,
			register_push_device.token
		)
		RETURNING
			*;
	END IF;
END;
$$;