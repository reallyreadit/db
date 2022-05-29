-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- added FOR UPDATE lock on SELECT
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
	existing_device core.notification_push_device;
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
		   locals.existing_device IS NOT NULL
		THEN
			UPDATE
				core.notification_push_device
			SET
				date_unregistered = core.utc_now(),
				unregistration_reason = (
					CASE WHEN
					   locals.existing_device.user_account_id != register_push_device.user_account_id
					THEN
					   'user_change'
					ELSE
					   'token_change'
					END
				)
			WHERE
				notification_push_device.id = locals.existing_device.id;
		END IF;
		-- unregister any other currently registered devices using the same token
		UPDATE
			core.notification_push_device
		SET
			date_unregistered = core.utc_now(),
			unregistration_reason = 'reinstall'
		WHERE
			notification_push_device.token = register_push_device.token AND
			notification_push_device.date_unregistered IS NULL;
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