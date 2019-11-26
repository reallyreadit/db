-- don't trigger follower digest notification for a follower that has previously followed the followee
CREATE OR REPLACE FUNCTION notifications.create_follower_digest_notifications(
	frequency text
)
RETURNS SETOF notifications.follower_digest_dispatch
LANGUAGE sql
AS $$
    WITH follower AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
    	    active_following.id AS following_id,
			active_following.date_followed AS date_followed,
    	    follower.name AS user_name
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON (
					recipient.id = preference.user_account_id AND
					preference.follower_digest_via_email = create_follower_digest_notifications.frequency::core.notification_event_frequency
				)
			JOIN core.following AS active_following
    			ON (
					active_following.followee_user_account_id = recipient.id AND
    			    active_following.date_followed >= (
						CASE create_follower_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
					) AND
					active_following.date_unfollowed IS NULL
				)
    		JOIN core.user_account AS follower
    			ON follower.id = active_following.follower_user_account_id
    		LEFT JOIN core.following AS inactive_following
    			ON (
    			    inactive_following.followee_user_account_id = active_following.followee_user_account_id AND
    			    inactive_following.follower_user_account_id = active_following.follower_user_account_id AND
    			    inactive_following.id != active_following.id
    			)
		WHERE
			 inactive_following.id IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	follower
	),
    follower_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_follower_digest_notifications.frequency
				WHEN 'daily' THEN 'follower_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'follower_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient
        RETURNING
        	id
	),
    recipient_event AS (
        SELECT
            numbered_recipient.id AS recipient_id,
        	numbered_event.id AS event_id
        FROM
		(
			SELECT
				recipient_id AS id,
				row_number() OVER (ORDER BY recipient_id) AS row_number
			FROM
				recipient
		) AS numbered_recipient
		JOIN (
			SELECT
				id,
				row_number() OVER (ORDER BY id) AS row_number
			FROM
				follower_event
		) AS numbered_event
			ON numbered_event.row_number = numbered_recipient.row_number
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
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    follower_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		SELECT
			recipient_event.event_id,
			follower.following_id
		FROM
			recipient_event
        	JOIN follower
        		ON follower.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        follower.recipient_id,
        follower.recipient_name,
        follower.recipient_email,
        follower.following_id,
		follower.date_followed,
		follower.user_name
    FROM
    	receipt
        JOIN follower
    		ON follower.recipient_id = receipt.user_account_id;
$$;