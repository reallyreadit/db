SELECT
	notification.bounce->>'timestamp' AS timestamp,
	notification.mail->'common_headers'->>'subject' AS subject,
	notification.bounce->'bounced_recipients'->0->>'email_address' AS email_address,
	notification.bounce->>'bounce_type' AS bounce_type,
	notification.bounce->>'bounce_sub_type' AS bounce_sub_type,
	notification.bounce->'bounced_recipients'->0->>'action' AS action,
	notification.bounce->'bounced_recipients'->0->>'status' AS status,
	notification.bounce->'bounced_recipients'->0->>'diagnostic_code' AS diagnostic_code
FROM
	email_notification AS notification
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
ORDER BY
	notification.bounce->>'timestamp' DESC;
