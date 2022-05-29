-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

CREATE TABLE core.new_platform_notification_request (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    email_address varchar (512) NOT NULL,
    ip_address text NOT NULL,
    user_agent text NOT NULL
);

CREATE FUNCTION analytics.log_new_platform_notification_request(
    email_address text,
    ip_address text,
    user_agent text
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO
        core.new_platform_notification_request (
            email_address,
            ip_address,
            user_agent
        )
    VALUES (
        log_new_platform_notification_request.email_address,
        log_new_platform_notification_request.ip_address,
        log_new_platform_notification_request.user_agent
    );
$$;