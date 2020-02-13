-- query for dispatching failed aotd bulk email send
SELECT
    receipt.id AS receipt_id,
    receipt.via_email,
    receipt.via_push,
    user_account.id AS user_account_id,
    user_account.name::text AS user_name,
    user_account.email::text AS email_address,
    coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}') AS push_device_tokens,
    user_account.aotd_alert,
    user_account.reply_alert_count,
    user_account.loopback_alert_count,
    user_account.post_alert_count,
    user_account.follower_alert_count
FROM
    (
        SELECT
            receipt.id,
            receipt.via_email,
            receipt.via_push,
            receipt.user_account_id
        FROM
            notification_receipt AS receipt
            JOIN notification_event ON
                notification_event.type = 'aotd' AND
                notification_event.date_created = (
                    SELECT
                        max(date_created)
                    FROM
                        notification_event
                    WHERE
                        type = 'aotd'
                ) AND
                receipt.event_id = notification_event.id
    ) AS receipt
    JOIN core.user_account
        ON user_account.id = receipt.user_account_id
    LEFT JOIN notifications.registered_push_device AS device
        ON device.user_account_id = receipt.user_account_id
WHERE
    receipt.via_email OR device.id IS NOT NULL
GROUP BY
    receipt.id,
    receipt.via_email,
    receipt.via_push,
    user_account.id;