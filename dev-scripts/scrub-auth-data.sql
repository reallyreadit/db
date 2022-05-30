-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
The purpose of this script is only to scrub authentication-related data. Dumps produced after running this
script need to be stored on encrypted drives and encrypted in transit.
*/
CREATE FUNCTION pg_temp.generate_random_string(
    length int
)
RETURNS text
LANGUAGE SQL
AS $$
    SELECT array_to_string(
        ARRAY(
            SELECT
                chr((65 + round(random() * 25))::int)
            FROM
                generate_series(1, generate_random_string.length)
        ),
        ''
    );
$$;

UPDATE
	core.auth_service_access_token
SET
	token_value = '_SCRUBBED_' || pg_temp.generate_random_string(64),
	token_secret = '_SCRUBBED_' || pg_temp.generate_random_string(64)
WHERE
	TRUE;

UPDATE
	core.auth_service_refresh_token
SET
	raw_value = '_SCRUBBED_' || pg_temp.generate_random_string(64)
WHERE
	TRUE;

UPDATE
	core.auth_service_request_token
SET
	token_value = '_SCRUBBED_' || pg_temp.generate_random_string(64),
	token_secret = '_SCRUBBED_' || pg_temp.generate_random_string(64)
WHERE
	TRUE;

UPDATE
	core.notification_push_device
SET
	token = '_SCRUBBED_' || pg_temp.generate_random_string(64)
WHERE
	TRUE;

UPDATE
	core.user_account
SET
	-- sets password = 'password'
	password_hash = E'\\x4B0C6BA854E085CA2C6E014EE461000187C6D9C28FBDFC96AD7B203F8CC4E6BF',
	password_salt = E'\\x00000000000000000000000000000000'
WHERE
	TRUE;