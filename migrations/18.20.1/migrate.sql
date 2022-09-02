-- Added missing return type casting.
CREATE OR REPLACE FUNCTION
	notifications.create_loopback_notifications(
		article_id bigint,
		comment_id bigint,
		comment_author_id bigint
	)
RETURNS
	SETOF notifications.alert_dispatch
LANGUAGE
	sql
AS $$
	WITH recipient AS (
		SELECT
			user_article.user_account_id,
			preference.loopback_via_email,
			preference.loopback_via_extension,
			preference.loopback_via_push
		FROM
			core.user_article
			JOIN notifications.current_preference AS preference ON
				preference.user_account_id = user_article.user_account_id
			LEFT JOIN social.active_following
				ON (
					active_following.follower_user_account_id = user_article.user_account_id AND
					active_following.followee_user_account_id = create_loopback_notifications.comment_author_id
				)
		WHERE
			user_article.article_id = create_loopback_notifications.article_id AND
			user_article.user_account_id != create_loopback_notifications.comment_author_id AND
			user_article.date_completed IS NOT NULL AND
			active_following.id IS NULL
	),
	loopback_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
			'loopback'
		WHERE
			EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
	loopback_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			id,
			create_loopback_notifications.comment_id
		FROM
			loopback_event
	),
	receipt AS (
		INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push,
				event_type
			)
		(
			SELECT
				(SELECT id FROM loopback_event),
				recipient.user_account_id,
				recipient.loopback_via_email,
				recipient.loopback_via_extension,
				recipient.loopback_via_push,
				'loopback'::core.notification_event_type
			FROM
				recipient
		)
		RETURNING
			id,
			user_account_id,
			via_email,
			via_extension,
			via_push
	),
	updated_user AS (
		UPDATE
			core.user_account
		SET
			loopback_alert_count = loopback_alert_count + 1
		FROM
			 recipient
		WHERE
			user_account.id = recipient.user_account_id
		RETURNING
			user_account.id,
			user_account.name,
			user_account.email,
			user_account.aotd_alert,
			user_account.reply_alert_count,
			user_account.loopback_alert_count,
			user_account.post_alert_count,
			user_account.follower_alert_count
	)
	SELECT
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		updated_user.id,
		updated_user.name::text,
		updated_user.email::text,
		coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count
	FROM
		receipt
		JOIN updated_user ON
			updated_user.id = receipt.user_account_id
		LEFT JOIN notifications.registered_push_device AS device ON
			device.user_account_id = receipt.user_account_id
	WHERE
		receipt.via_email OR device.id IS NOT NULL
	GROUP BY
		receipt.id,
		receipt.via_email,
		receipt.via_push,
		updated_user.id,
		updated_user.name,
		updated_user.email,
		updated_user.aotd_alert,
		updated_user.reply_alert_count,
		updated_user.loopback_alert_count,
		updated_user.post_alert_count,
		updated_user.follower_alert_count;
$$;