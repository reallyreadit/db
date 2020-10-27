-- new email blocking policy
CREATE OR REPLACE FUNCTION
   notifications.get_blocked_email_addresses()
RETURNS
   SETOF text
LANGUAGE
	sql
STABLE
AS $$
	SELECT DISTINCT
		lower(
			recipient->>'email_address'
		)
	FROM (
		SELECT
			jsonb_array_elements(
				notification.complaint->'complained_recipients'
			)
		FROM
			core.email_notification AS notification
		WHERE
			notification.complaint != 'null'
		UNION ALL
		SELECT
			jsonb_array_elements(
				notification.bounce->'bounced_recipients'
			)
		FROM
			core.email_notification AS notification
		WHERE
			notification.bounce != 'null' AND
			(
				notification.bounce->>'bounce_type' IS NULL OR
				NOT (
					notification.bounce->>'bounce_type' = 'Transient' AND
					notification.bounce->>'bounce_sub_type' = 'General' AND
					(
						(
							notification.bounce->'bounced_recipients'->0->>'action' IS NULL OR
							notification.bounce->'bounced_recipients'->0->>'status' IS NULL OR
							notification.bounce->'bounced_recipients'->0->>'diagnostic_code' IS NULL
						) OR
						(
							notification.bounce->'bounced_recipients'->0->>'email_address' ILIKE '%@privaterelay.appleid.com%' AND
							notification.bounce->'bounced_recipients'->0->>'diagnostic_code' ILIKE '%relay not allowed%'
						)
					)
				)
			)
	) AS report (
		recipient
	);
$$;