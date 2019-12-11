-- fix stale alert counts due to CTE snapshotting
CREATE OR REPLACE FUNCTION notifications.create_loopback_notifications(
	article_id bigint,
	comment_id bigint,
	comment_author_id bigint
)
RETURNS SETOF notifications.alert_dispatch
LANGUAGE sql
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
				via_push
			)
		(
			SELECT
				(SELECT id FROM loopback_event),
				recipient.user_account_id,
				recipient.loopback_via_email,
				recipient.loopback_via_extension,
				recipient.loopback_via_push
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
		updated_user.name,
		updated_user.email,
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

CREATE OR REPLACE FUNCTION notifications.create_post_notifications(
	article_id bigint,
	poster_id bigint,
	comment_id bigint,
	silent_post_id bigint
)
RETURNS SETOF notifications.post_alert_dispatch
LANGUAGE sql
AS $$
    WITH recipient AS (
        SELECT
			following.follower_user_account_id AS user_account_id,
		    preference.post_via_email,
		    preference.post_via_extension,
		    preference.post_via_push
		FROM
			social.active_following AS following
			JOIN notifications.current_preference AS preference
			    ON (
					following.follower_user_account_id = preference.user_account_id AND
					following.followee_user_account_id = create_post_notifications.poster_id
				)
	),
    post_event AS (
        INSERT INTO
			core.notification_event (type)
		SELECT
            'post'
        WHERE
            EXISTS (SELECT * FROM recipient)
		RETURNING
			id
	),
    post_data AS (
        INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
        	id,
		    create_post_notifications.comment_id,
		    create_post_notifications.silent_post_id
        FROM
        	post_event
	),
	receipt AS (
		INSERT INTO
			core.notification_receipt (
				event_id,
				user_account_id,
				via_email,
				via_extension,
				via_push
			)
		(
			SELECT
				(SELECT id FROM post_event),
				recipient.user_account_id,
				recipient.post_via_email,
				recipient.post_via_extension,
				recipient.post_via_push
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
			post_alert_count = post_alert_count + 1
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
	    user_article.date_completed IS NOT NULL,
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
		JOIN updated_user
			ON updated_user.id = receipt.user_account_id
		LEFT JOIN core.user_article
		    ON (
		        user_article.user_account_id = updated_user.id AND
		        user_article.article_id = create_post_notifications.article_id
		    )
		LEFT JOIN notifications.registered_push_device AS device
			ON device.user_account_id = receipt.user_account_id
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
		updated_user.follower_alert_count,
	    user_article.date_completed;
$$;