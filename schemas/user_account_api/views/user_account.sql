CREATE VIEW user_account_api.user_account AS
	SELECT ua.*, ec.date_confirmed IS NOT NULL AS is_email_confirmed
	FROM user_account ua
	LEFT JOIN email_confirmation ec ON ec.user_account_id = ua.id
	LEFT JOIN email_confirmation ec1 ON ec1.user_account_id = ua.id AND ec1.date_created > ec.date_created
	WHERE ec1.id IS NULL;