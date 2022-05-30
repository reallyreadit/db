-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

SELECT
	id,
    coalesce(mail->>'timestamp', bounce->>'timestamp', complaint->>'timestamp') AS timestamp,
    notification_type,
    bounce->>'bounce_type' AS bounce_type,
    bounce->>'bounce_sub_type' AS bounce_sub_type,
    mail->'common_headers'->>'to' AS to,
    mail,
    bounce,
    complaint
FROM
	email_notification
WHERE
	bounce->>'bounce_type' ILIKE 'Transient' AND
    bounce->>'bounce_sub_type' ILIKE 'General'
ORDER BY
    coalesce(mail->>'timestamp', bounce->>'timestamp', complaint->>'timestamp') DESC NULLS LAST;