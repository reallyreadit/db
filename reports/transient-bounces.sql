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