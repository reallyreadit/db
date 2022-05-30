-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/**
	Add support for a new free trial completion email notification.
 */

ALTER TYPE
	core.notification_event_type
ADD VALUE
	'free_trial_completion'
AFTER
	'welcome';

DROP INDEX
	notification_event_duplicate_user_account_event_idx;

CREATE UNIQUE INDEX
	notification_event_duplicate_user_account_event_idx
ON
	core.notification_receipt
USING
	btree (
		user_account_id,
		event_type
	)
WHERE
	event_type IN (
		'free_trial_completion'::core.notification_event_type,
		'initial_subscription'::core.notification_event_type
	);