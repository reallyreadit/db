-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

ALTER TABLE
    core.user_account
ADD COLUMN
    date_deleted timestamp;

CREATE FUNCTION core.generate_random_string(
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

CREATE FUNCTION user_account_api.delete_user_account(
    email_address text
)
RETURNS void
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    user_account_id CONSTANT bigint := (
        SELECT
            user_account.id
        FROM
            core.user_account
        WHERE
            user_account.email = delete_user_account.email_address
    );
BEGIN
    IF locals.user_account_id IS NULL THEN
        RAISE EXCEPTION 'User account not found';
    END IF;
    UPDATE
        core.user_account
    SET
        name = core.generate_random_string(30),
        email = core.generate_random_string(30) || '@' || core.generate_random_string(30),
        password_hash = E'\\xE40C3AA8085BEAF7E88F0131DEF4E800E0654FCED9ABA5A26B40CD30859229D2',
        password_salt = E'\\x00000000000000000000000000000000',
        date_deleted = core.utc_now()
    WHERE
        user_account.id = locals.user_account_id;
    UPDATE
        core.comment
    SET
        date_deleted = core.utc_now()
    WHERE
        comment.user_account_id = locals.user_account_id;
    UPDATE
        core.notification_preference
    SET
        company_update_via_email = FALSE,
        aotd_via_email = FALSE,
        aotd_via_extension = FALSE,
        aotd_via_push = FALSE,
        aotd_digest_via_email = 'never',
        reply_via_email = FALSE,
        reply_via_extension = FALSE,
        reply_via_push = FALSE,
        reply_digest_via_email = 'never',
        loopback_via_email = FALSE,
        loopback_via_extension = FALSE,
        loopback_via_push = FALSE,
        loopback_digest_via_email = 'never',
        post_via_email = FALSE,
        post_via_extension = FALSE,
        post_via_push = FALSE,
        post_digest_via_email = 'never',
        follower_via_email = FALSE,
        follower_via_extension = FALSE,
        follower_via_push = FALSE,
        follower_digest_via_email = 'never'
    WHERE
        notification_preference.user_account_id = locals.user_account_id;
END;
$$;