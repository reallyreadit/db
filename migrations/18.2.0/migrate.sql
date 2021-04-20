/*
	We need to add a redundant event_type column to notification_receipt so that we can add a unique constraint to
	prevent duplicate notifications in the upcoming subscriptions release.
*/

/*
	In order to reference the type column in a foreign key constraint it needs to have a unique constraint. The column
	order is apparently important for performance:
	https://dba.stackexchange.com/questions/58970/enforcing-constraints-two-tables-away/58972#58972
*/
ALTER TABLE
	core.notification_event
ADD CONSTRAINT
	notification_event_type_reference
UNIQUE
	(type, id);

-- Add the new redundant column to notification_receipt.
ALTER TABLE
	core.notification_receipt
ADD COLUMN
	event_type core.notification_event_type;

-- Update all the existing receipts.
UPDATE
	core.notification_receipt AS receipt
SET
	event_type = event.type
FROM
	core.notification_event AS event
WHERE
	receipt.event_id = event.id;

-- Enforce a not null constraint going forward.
ALTER TABLE
	core.notification_receipt
ALTER COLUMN
	event_type
SET NOT NULL;

-- Replace the existing foreign key constraint with the new composite constraint.
ALTER TABLE
	core.notification_receipt
DROP CONSTRAINT
	notification_receipt_event_id_fkey,
ADD CONSTRAINT
	notification_receipt_event_fkey
FOREIGN KEY
	(event_id, event_type)
REFERENCES
	core.notification_event (
		id, type
	);

-- Update all functions that insert into notification_receipt in order to add the new column value.
CREATE OR REPLACE FUNCTION notifications.create_aotd_digest_notifications() RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.aotd_digest_via_email = 'weekly'
	),
    aotd_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	'aotd_digest'
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
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
		SELECT
			(SELECT id FROM aotd_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    'aotd_digest'::core.notification_event_type
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	),
    aotd_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				article_id
			)
		SELECT
			(SELECT id FROM aotd_event),
			article.id
		FROM
			core.article
		WHERE
			EXISTS (SELECT id FROM aotd_event)
        ORDER BY
        	article.aotd_timestamp DESC NULLS LAST
        LIMIT 7
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;

CREATE OR REPLACE FUNCTION notifications.create_aotd_notifications(article_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
	-- create the event
	INSERT INTO
		core.notification_event (
			type
		)
	VALUES
		(
			'aotd'
		)
	RETURNING
		id INTO locals.event_id;
	-- create the data
	INSERT INTO
		core.notification_data (
			event_id,
			article_id
		)
	VALUES
		(
			locals.event_id,
			create_aotd_notifications.article_id
		);
	-- set the alert for all users
	UPDATE
		core.user_account
	SET
		aotd_alert = true
	WHERE
		aotd_alert = false;
	-- create receipts and return the dispatches
	RETURN QUERY
	WITH receipt AS (
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
				locals.event_id,
				preference.user_account_id,
				preference.aotd_via_email,
				preference.aotd_via_extension,
				preference.aotd_via_push,
				'aotd'::core.notification_event_type
			FROM
				notifications.current_preference AS preference
		)
		RETURNING
	    	id,
		    user_account_id,
		    via_email,
		    via_push
	)
	SELECT
		receipt.id,
	    receipt.via_email,
	    receipt.via_push,
		user_account.id,
	    user_account.name::text,
		user_account.email::text,
	    coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
	    user_account.aotd_alert,
	    user_account.reply_alert_count,
	    user_account.loopback_alert_count,
	    user_account.post_alert_count,
	    user_account.follower_alert_count
	FROM
		receipt
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
END;
$$;

CREATE OR REPLACE FUNCTION notifications.create_company_update_notifications(author_id bigint, subject text, body text) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH recipient AS (
      	SELECT
        	current_preference.user_account_id
        FROM
        	notifications.current_preference
        WHERE
        	current_preference.company_update_via_email
	),
    update_event AS (
		INSERT INTO
			core.notification_event (
				type,
			    bulk_email_author_id,
			    bulk_email_subject,
			    bulk_email_body
			)
		SELECT
        	'company_update',
		    create_company_update_notifications.author_id,
		    create_company_update_notifications.subject,
		    create_company_update_notifications.body
        FROM
        	recipient
		LIMIT 1
        RETURNING
        	id
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
		SELECT
			(SELECT id FROM update_event),
		    recipient.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    'company_update'::core.notification_event_type
        FROM
        	recipient
        RETURNING
        	id,
            user_account_id
	)
    SELECT
        receipt.id,
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	receipt
        JOIN core.user_account
    		ON user_account.id = receipt.user_account_id;
$$;

CREATE OR REPLACE FUNCTION notifications.create_follower_digest_notifications(frequency text) RETURNS SETOF notifications.follower_digest_dispatch
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_follower_digest_notifications.frequency
				WHEN 'daily' THEN 'follower_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'follower_weekly_digest'::core.notification_event_type
			END
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

CREATE OR REPLACE FUNCTION notifications.create_follower_notification(following_id bigint, follower_id bigint, followee_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    event_id bigint;
BEGIN
    -- only notify on the first following
    IF (
		(
		    SELECT
		    	count(*)
		    FROM
		    	following
		    WHERE
		        following.follower_user_account_id = create_follower_notification.follower_id AND
		    	following.followee_user_account_id = create_follower_notification.followee_id
		) = 1
	) THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'follower'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				following_id
			)
		VALUES
			(
				locals.event_id,
				create_follower_notification.following_id
			);
		-- increment the followee's alert count
		UPDATE
			user_account
		SET
			follower_alert_count = follower_alert_count + 1
		WHERE
			id = create_follower_notification.followee_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
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
					locals.event_id,
					create_follower_notification.followee_id,
					preference.follower_via_email,
					preference.follower_via_extension,
					preference.follower_via_push,
					'follower'::core.notification_event_type
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = create_follower_notification.followee_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
			receipt.via_email,
			receipt.via_push,
			user_account.id,
			user_account.name::text,
			user_account.email::text,
			coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
			user_account.aotd_alert,
			user_account.reply_alert_count,
			user_account.loopback_alert_count,
			user_account.post_alert_count,
			user_account.follower_alert_count
		FROM
			receipt
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
        GROUP BY
        	receipt.id,
            receipt.via_email,
            receipt.via_push,
            user_account.id;
	END IF;
END;
$$;

CREATE OR REPLACE FUNCTION notifications.create_loopback_digest_notifications(frequency text) RETURNS SETOF notifications.comment_digest_dispatch
    LANGUAGE sql
    AS $$
    WITH loopback AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        loopback.id AS comment_id,
	        loopback.date_created AS date_created,
	        loopback.text AS comment_text,
    	    loopback.addenda AS comment_addenda,
	        loopback_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN core.user_account AS recipient
			    ON (
					recipient.id = preference.user_account_id AND
					preference.loopback_digest_via_email = create_loopback_digest_notifications.frequency::core.notification_event_frequency
				)
			JOIN core.user_article
			    ON (
			        user_article.user_account_id = recipient.id AND
			        user_article.date_completed IS NOT NULL
			    )
			JOIN core.article
			    ON article.id = user_article.article_id
			JOIN social.comment AS loopback
			    ON (
					loopback.article_id = article.id AND
					loopback.user_account_id != recipient.id AND
					loopback.parent_comment_id IS NULL AND
					loopback.date_created >= (
						CASE create_loopback_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
					) AND
					loopback.date_deleted IS NULL
				)
			JOIN core.user_account AS loopback_author
			    ON loopback_author.id = loopback.user_account_id
			LEFT JOIN social.active_following
			    ON (
					active_following.follower_user_account_id = recipient.id AND
					active_following.followee_user_account_id = loopback_author.id
				)
		WHERE
		    active_following.id IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	loopback
	),
    loopback_event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_loopback_digest_notifications.frequency
				WHEN 'daily' THEN 'loopback_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'loopback_weekly_digest'::core.notification_event_type
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
				loopback_event
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_loopback_digest_notifications.frequency
				WHEN 'daily' THEN 'loopback_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'loopback_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    loopback_data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			loopback.comment_id
		FROM
			recipient_event
        	JOIN loopback
        		ON loopback.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        loopback.recipient_id,
        loopback.recipient_name,
        loopback.recipient_email,
        loopback.comment_id,
		loopback.date_created,
		loopback.comment_text,
        loopback.comment_addenda,
		loopback.author,
        loopback.article_id,
        loopback.article_title
    FROM
    	receipt
        JOIN loopback
    		ON loopback.recipient_id = receipt.user_account_id;
$$;

CREATE OR REPLACE FUNCTION notifications.create_loopback_notifications(article_id bigint, comment_id bigint, comment_author_id bigint) RETURNS SETOF notifications.alert_dispatch
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

CREATE OR REPLACE FUNCTION notifications.create_post_digest_notifications(frequency text) RETURNS SETOF notifications.post_digest_dispatch
    LANGUAGE sql
    AS $$
    WITH post AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        post.comment_id AS comment_id,
    	    post.silent_post_id AS silent_post_id,
	        post.date_created AS date_created,
	        post.comment_text AS comment_text,
    	    post.comment_addenda AS comment_addenda,
	        post_author.name AS author,
    	    article.id AS article_id,
    	    article.title AS article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN social.active_following
			    ON active_following.follower_user_account_id = preference.user_account_id
			JOIN social.post
			    ON post.user_account_id = active_following.followee_user_account_id
			JOIN core.article
			    ON article.id = post.article_id
	    	JOIN core.user_account AS post_author
	    		ON post_author.id = post.user_account_id
		WHERE
			preference.post_digest_via_email = create_post_digest_notifications.frequency::core.notification_event_frequency AND
		    post.date_created >= (
		        CASE create_post_digest_notifications.frequency
					WHEN 'daily' THEN core.utc_now() - '1 day'::interval
					WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
				END
		    ) AND
		    post.date_deleted IS NULL
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	post
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	 CASE create_post_digest_notifications.frequency
				WHEN 'daily' THEN 'post_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'post_weekly_digest'::core.notification_event_type
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
				event
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_post_digest_notifications.frequency
				WHEN 'daily' THEN 'post_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'post_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id,
			    silent_post_id
			)
		SELECT
			recipient_event.event_id,
			post.comment_id,
		    post.silent_post_id
		FROM
			recipient_event
        	JOIN post
        		ON post.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        post.recipient_id,
        post.recipient_name,
        post.recipient_email,
        post.comment_id,
        post.silent_post_id,
		post.date_created,
		post.comment_text,
        post.comment_addenda,
		post.author,
        post.article_id,
        post.article_title
    FROM
    	receipt
        JOIN post
    		ON post.recipient_id = receipt.user_account_id;
$$;

CREATE OR REPLACE FUNCTION notifications.create_post_notifications(article_id bigint, poster_id bigint, comment_id bigint, silent_post_id bigint) RETURNS SETOF notifications.post_alert_dispatch
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
				via_push,
				event_type
			)
		(
			SELECT
				(SELECT id FROM post_event),
				recipient.user_account_id,
				recipient.post_via_email,
				recipient.post_via_extension,
				recipient.post_via_push,
				'post'::core.notification_event_type
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

CREATE OR REPLACE FUNCTION notifications.create_reply_digest_notifications(frequency text) RETURNS SETOF notifications.comment_digest_dispatch
    LANGUAGE sql
    AS $$
    WITH reply AS (
    	SELECT
    		recipient.id AS recipient_id,
    	    recipient.name AS recipient_name,
	        recipient.email AS recipient_email,
	        reply.id AS comment_id,
	        reply.date_created AS comment_date_created,
	        reply.text AS comment_text,
    	    reply.addenda AS comment_addenda,
	        reply_author.name AS comment_author_name,
    	    article.id AS comment_article_id,
    	    article.title AS comment_article_title
		FROM
			notifications.current_preference AS preference
			JOIN user_account AS recipient
			    ON recipient.id = preference.user_account_id
			JOIN core.comment
			    ON comment.user_account_id = preference.user_account_id
	    	JOIN social.comment AS reply
	    		ON (
	    		    reply.parent_comment_id = comment.id AND
	    		    reply.user_account_id != preference.user_account_id AND
	    		    reply.date_created >= (
	    		        CASE create_reply_digest_notifications.frequency
							WHEN 'daily' THEN core.utc_now() - '1 day'::interval
							WHEN 'weekly' THEN core.utc_now() - '1 week'::interval
						END
	    		    ) AND
	    		    reply.date_deleted IS NULL
	    		)
			JOIN core.article
			    ON article.id = reply.article_id
	    	JOIN core.user_account AS reply_author
	    		ON reply_author.id = reply.user_account_id
		WHERE
			preference.reply_digest_via_email = create_reply_digest_notifications.frequency::core.notification_event_frequency
	),
    recipient AS (
      	SELECT
        	DISTINCT recipient_id
        FROM
        	reply
	),
    event AS (
		INSERT INTO
			core.notification_event (type)
		SELECT
        	CASE create_reply_digest_notifications.frequency
				WHEN 'daily' THEN 'reply_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'reply_weekly_digest'::core.notification_event_type
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
				event
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
				via_push,
				event_type
			)
		SELECT
			recipient_event.event_id,
		    recipient_event.recipient_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    CASE create_reply_digest_notifications.frequency
				WHEN 'daily' THEN 'reply_daily_digest'::core.notification_event_type
				WHEN 'weekly' THEN 'reply_weekly_digest'::core.notification_event_type
			END
        FROM
        	recipient_event
        RETURNING
        	id,
            user_account_id
	),
    data AS (
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		SELECT
			recipient_event.event_id,
			reply.comment_id
		FROM
			recipient_event
        	JOIN reply
        		ON reply.recipient_id = recipient_event.recipient_id
	)
    SELECT
        receipt.id,
        reply.recipient_id,
        reply.recipient_name,
        reply.recipient_email,
        reply.comment_id,
		reply.comment_date_created,
		reply.comment_text,
        reply.comment_addenda,
		reply.comment_author_name,
        reply.comment_article_id,
        reply.comment_article_title
    FROM
    	receipt
        JOIN reply
    		ON reply.recipient_id = receipt.user_account_id;
$$;

CREATE OR REPLACE FUNCTION notifications.create_reply_notification(reply_id bigint, reply_author_id bigint, parent_id bigint) RETURNS SETOF notifications.alert_dispatch
    LANGUAGE plpgsql
    AS $$
<<locals>>
DECLARE
    parent_author_id bigint;
    event_id bigint;
BEGIN
    -- lookup the parent author
    SELECT
    	user_account_id
    INTO
        locals.parent_author_id
    FROM
    	core.comment
    WHERE
    	id = parent_id;
    -- check for a self-reply
    IF create_reply_notification.reply_author_id != locals.parent_author_id THEN
		-- create the event
		INSERT INTO
			core.notification_event (
				type
			)
		VALUES
			(
				'reply'
			)
		RETURNING
			id INTO locals.event_id;
		-- create the data
		INSERT INTO
			core.notification_data (
				event_id,
				comment_id
			)
		VALUES
			(
				locals.event_id,
				create_reply_notification.reply_id
			);
		-- increment the parent's alert count
		UPDATE
			user_account
		SET
			reply_alert_count = reply_alert_count + 1
		WHERE
			id = locals.parent_author_id;
		-- create receipt and return the dispatch
		RETURN QUERY
		WITH receipt AS (
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
					locals.event_id,
					locals.parent_author_id,
					preference.reply_via_email,
					preference.reply_via_extension,
					preference.reply_via_push,
					'reply'::core.notification_event_type
				FROM
					notifications.current_preference AS preference
				WHERE
					user_account_id = locals.parent_author_id
			)
			RETURNING
		    	id,
			    user_account_id,
			    via_email,
			    via_push
		)
		SELECT
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
			user_account.id,
		    user_account.name::text,
			user_account.email::text,
		    coalesce(array_agg(device.token) FILTER (WHERE device.token IS NOT NULL), '{}'),
			user_account.aotd_alert,
			user_account.reply_alert_count,
			user_account.loopback_alert_count,
			user_account.post_alert_count,
			user_account.follower_alert_count
		FROM
			receipt
			JOIN core.user_account ON
				user_account.id = receipt.user_account_id
			LEFT JOIN notifications.registered_push_device AS device
				ON device.user_account_id = receipt.user_account_id
		WHERE
			receipt.via_email OR device.id IS NOT NULL
		GROUP BY
			receipt.id,
		    receipt.via_email,
		    receipt.via_push,
		    user_account.id;
	END IF;
END;
$$;

CREATE OR REPLACE FUNCTION notifications.create_transactional_notification(user_account_id bigint, event_type text, email_confirmation_id bigint, password_reset_request_id bigint) RETURNS SETOF notifications.email_dispatch
    LANGUAGE sql
    AS $$
    WITH transactional_event AS (
		INSERT INTO
			core.notification_event (type)
		VALUES
		    (create_transactional_notification.event_type::core.notification_event_type)
        RETURNING
        	id
	),
    transactional_data AS (
      	INSERT INTO
        	core.notification_data (
        		event_id,
        	    email_confirmation_id,
        	    password_reset_request_id
			)
    	VALUES (
    	    (SELECT id FROM transactional_event),
			create_transactional_notification.email_confirmation_id,
    	    create_transactional_notification.password_reset_request_id
		)
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
		SELECT
			(SELECT id FROM transactional_event),
		    create_transactional_notification.user_account_id,
		    TRUE,
		    FALSE,
		    FALSE,
		    create_transactional_notification.event_type::core.notification_event_type
        RETURNING
        	id
	)
    SELECT
        (SELECT id FROM receipt),
        user_account.id,
        user_account.name,
        user_account.email
    FROM
    	core.user_account
    WHERE
    	id = create_transactional_notification.user_account_id;
$$;