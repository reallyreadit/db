SELECT
	timestamp,
    user_account_id,
    reason
FROM
    extension_removal
ORDER BY
	timestamp DESC;