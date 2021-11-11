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