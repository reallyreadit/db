-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

/*
	The first iteration of free-trials, using free view credits.
 */

/*
	Add new free trial types and table.
 */
CREATE TYPE
	core.free_trial_credit_type
AS ENUM (
	'article_view'
);

CREATE TYPE
	core.free_trial_credit_trigger
AS ENUM (
	'account_created',
	'promo_tweet_intended'
);

CREATE TABLE
	core.free_trial_credit (
		id bigserial,
		CONSTRAINT
			free_trial_credit_pkey
		PRIMARY KEY (
			id
		),
		date_created timestamp NOT NULL,
		user_account_id bigint NOT NULL,
		CONSTRAINT
			free_trial_credit_user_account_id_fkey
		FOREIGN KEY (
			user_account_id
		)
		REFERENCES
			core.user_account (
				id
			),
		credit_trigger core.free_trial_credit_trigger NOT NULL,
		credit_type core.free_trial_credit_type NOT NULL,
		amount_credited int NOT NULL,
		amount_remaining int NOT NULL,
		CONSTRAINT
			free_trial_credit_user_account_credit_limit_idx
		UNIQUE (
			user_account_id,
			credit_trigger
		)
	);

/*
	Add a new date_viewed column to core.user_article and core.provisional_user_article to track the view date separate
	from the creation and modification dates. Also add a new free_trial_credit_id column to user_article to track the
	utilization of free trial credits.
 */
ALTER TABLE
	core.user_article
ADD COLUMN
	date_viewed timestamp,
ADD COLUMN
	free_trial_credit_id bigint
CONSTRAINT
	user_article_free_trial_credit_id_fkey
REFERENCES
	core.free_trial_credit (
		id
	);

ALTER TABLE
	core.provisional_user_article
ADD COLUMN
	date_viewed timestamp;

/*
	Add new free trial functions to subscriptions schema.
 */
CREATE FUNCTION
	subscriptions.create_free_trial_credit(
		user_account_id bigint,
		credit_trigger text,
		credit_type text,
		credit_amount int
	)
RETURNS
	SETOF core.free_trial_credit
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.free_trial_credit (
			date_created,
			user_account_id,
			credit_trigger,
			credit_type,
			amount_credited,
			amount_remaining
		)
	VALUES (
		core.utc_now(),
		create_free_trial_credit.user_account_id,
		create_free_trial_credit.credit_trigger::core.free_trial_credit_trigger,
		create_free_trial_credit.credit_type::core.free_trial_credit_type,
		create_free_trial_credit.credit_amount,
		create_free_trial_credit.credit_amount
	)
	RETURNING
		*;
$$;

CREATE FUNCTION
	subscriptions.get_free_trial_credits_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF core.free_trial_credit
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		free_trial_credit.*
	FROM
		core.free_trial_credit
	WHERE
		free_trial_credit.user_account_id = get_free_trial_credits_for_user_account.user_account_id;
$$;

CREATE TYPE
	subscriptions.free_trial_article_view AS (
		article_id bigint,
		article_slug text,
		date_viewed timestamp,
		free_trial_credit_id bigint
	);

CREATE FUNCTION
	subscriptions.get_free_article_views_for_user_account(
		user_account_id bigint
	)
RETURNS
	SETOF subscriptions.free_trial_article_view
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		user_article.article_id,
		article.slug,
		user_article.date_viewed,
		user_article.free_trial_credit_id
	FROM
		core.user_article
		JOIN
			core.article ON
				user_article.article_id = article.id
	WHERE
		user_article.user_account_id = get_free_article_views_for_user_account.user_account_id AND
		user_article.free_trial_credit_id IS NOT NULL;
$$;

/*
	Extract existing subscription status check functions from reading function.
 */
CREATE FUNCTION
	subscriptions.is_user_subscribed_or_free_for_life(
		user_account_id bigint
	)
RETURNS
	bool
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		user_account.date_created < '2021-05-06T04:00:00' OR
		(
			user_account.subscription_end_date IS NOT NULL AND
			user_account.subscription_end_date > core.utc_now()
		)
	FROM
		core.user_account
	WHERE
		user_account.id = is_user_subscribed_or_free_for_life.user_account_id;
$$;

CREATE FUNCTION
	subscriptions.is_article_free_to_read(
		article_id bigint
	)
RETURNS
	bool
LANGUAGE
	sql
STABLE
AS $$
	SELECT
		article.source_id = 48542 -- readup blog
	FROM
		core.article
	WHERE
		article.id = is_article_free_to_read.article_id;
$$;

/*
	Add new function to mark articles as viewed to articles schema.
 */
CREATE FUNCTION
	articles.mark_user_article_as_viewed(
		user_article_id bigint
	)
RETURNS
	SETOF core.user_article
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
	target_user_article core.user_article;
	article_view_free_credit core.free_trial_credit;
BEGIN
	-- Query, cache, and lock the user article.
	SELECT
		user_article.*
	INTO
		locals.target_user_article
	FROM
		core.user_article
	WHERE
		user_article.id = mark_user_article_as_viewed.user_article_id
	FOR UPDATE;
	-- Return immediately without updating if the article has already been marked as viewed.
	IF
		locals.target_user_article.date_viewed IS NOT NULL
	THEN
		RETURN NEXT
			locals.target_user_article;
		RETURN;
	END IF;
	-- Set date_viewed and return immediately if the user is allowed to view the article based on their subscription or
	-- free-for-life status.
	IF
		subscriptions.is_user_subscribed_or_free_for_life(
			user_account_id := locals.target_user_article.user_account_id
		) OR
		subscriptions.is_article_free_to_read(
			article_id := locals.target_user_article.article_id
		)
	THEN
		RETURN QUERY
		UPDATE
			core.user_article
		SET
			date_viewed = core.utc_now()
		WHERE
			user_article.id = locals.target_user_article.id
		RETURNING
			*;
		RETURN;
	END IF;
	-- Query, cache, and lock any available free view credits that the user might have.
	SELECT
		credit.*
	INTO
		locals.article_view_free_credit
	FROM
		core.free_trial_credit AS credit
	WHERE
		credit.user_account_id = locals.target_user_article.user_account_id AND
		credit.credit_type = 'article_view'::core.free_trial_credit_type AND
		credit.amount_remaining > 0
	ORDER BY
		credit.date_created
	LIMIT
		1
	FOR UPDATE;
	-- Check for available free view credits.
	IF
		NOT (locals.article_view_free_credit IS NULL)
	THEN
		-- Subtract one view from the available credit.
		UPDATE
			core.free_trial_credit
		SET
			amount_remaining = locals.article_view_free_credit.amount_remaining - 1
		WHERE
			free_trial_credit.id = locals.article_view_free_credit.id;
		-- Set date_viewed, reference the free_trial_credit that was utilized, and return immediately.
		RETURN QUERY
		UPDATE
			core.user_article
		SET
			date_viewed = core.utc_now(),
			free_trial_credit_id = locals.article_view_free_credit.id
		WHERE
			user_article.id = locals.target_user_article.id
		RETURNING
			*;
		RETURN;
	END IF;
	-- Return without updating if the user doesn't have any free article view credits to use.
	RETURN NEXT
		locals.target_user_article;
END;
$$;

/*
	Add new user article creation functions to conditionally set date_viewed.
 */
CREATE FUNCTION
	article_api.create_user_article(
		article_id bigint,
		user_account_id bigint,
		readable_word_count integer,
		mark_as_viewed bool,
		analytics text
	)
RETURNS
	core.user_article
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
	new_user_article core.user_article;
BEGIN
	-- Create the new user_article without setting date_viewed.
	INSERT INTO
		core.user_article (
			article_id,
			user_account_id,
			read_state,
			readable_word_count,
			analytics
		)
	VALUES (
		create_user_article.article_id,
		create_user_article.user_account_id,
		ARRAY[-create_user_article.readable_word_count],
		create_user_article.readable_word_count,
		create_user_article.analytics::jsonb
	)
	RETURNING
		*
	INTO
		locals.new_user_article;
	-- Try to mark as viewed if requested.
	IF
		create_user_article.mark_as_viewed
	THEN
		SELECT
			*
		INTO
			locals.new_user_article
		FROM
			articles.mark_user_article_as_viewed(
				user_article_id := locals.new_user_article.id
			);
	END IF;
	-- Return the user_article.
	RETURN
		locals.new_user_article;
END;
$$;

CREATE FUNCTION
	article_api.create_provisional_user_article(
		article_id bigint,
		provisional_user_account_id bigint,
		readable_word_count integer,
		mark_as_viewed bool,
		analytics text
	)
RETURNS
	core.provisional_user_article
LANGUAGE
	sql
AS $$
	INSERT INTO
		core.provisional_user_article (
			article_id,
			provisional_user_account_id,
			read_state,
			readable_word_count,
			date_viewed,
			analytics
		)
	VALUES (
		create_provisional_user_article.article_id,
		create_provisional_user_article.provisional_user_account_id,
		ARRAY[-create_provisional_user_article.readable_word_count],
		create_provisional_user_article.readable_word_count,
		CASE WHEN
			create_provisional_user_article.mark_as_viewed
		THEN
			core.utc_now()
		ELSE
			NULL::timestamp
		END,
		create_provisional_user_article.analytics::jsonb
	)
	RETURNING
	    *;
$$;

/*
	Update reading function to check free trial status and use extracted subscription status check functions.
 */
CREATE OR REPLACE FUNCTION
	article_api.update_read_progress(
		user_article_id bigint,
		read_state integer[],
		analytics text
	)
RETURNS
	core.user_article
LANGUAGE
	plpgsql
AS $$
<<locals>>
DECLARE
   	-- utc timestamp
   	utc_now CONSTANT timestamp NOT NULL := utc_now();
   	-- calculate the words read from the read state
	words_read CONSTANT int NOT NULL := (
		SELECT
		    sum(n)
		FROM
		    unnest(update_read_progress.read_state) AS n
		WHERE
		    n > 0
	);
	-- local user_article
	current_user_article user_article;
	-- progress since last commit
	words_read_since_last_commit int;
BEGIN
    -- read and lock the existing user_article
	SELECT
	    *
	INTO
	    locals.current_user_article
	FROM
	    core.user_article
	WHERE
	    user_article.id = update_read_progress.user_article_id
	FOR UPDATE;
	-- check if the user is allowed to read
	IF
		locals.current_user_article.free_trial_credit_id IS NULL AND
		NOT subscriptions.is_user_subscribed_or_free_for_life(
			user_account_id := locals.current_user_article.user_account_id
		) AND
		NOT subscriptions.is_article_free_to_read(
			article_id := locals.current_user_article.article_id
		)
	THEN
		RAISE EXCEPTION
			'Subscription required.'
		USING
			DETAIL = 'https://docs.readup.com/errors/reading/subscription-required';
	END IF;
	-- only update if more words have been read
	IF locals.words_read > locals.current_user_article.words_read THEN
	   	-- calculate the words read since the last commit
	   	locals.words_read_since_last_commit = locals.words_read - locals.current_user_article.words_read;
		-- update the progress
	   	INSERT INTO
	   	    core.user_article_progress (
	   	        user_account_id,
	   	        article_id,
	   	        period,
	   	        words_read,
	   	        client_type
	   	    )
	   	VALUES (
	   		locals.current_user_article.user_account_id,
	   	 	locals.current_user_article.article_id,
            (
                date_trunc('hour', locals.utc_now) +
                make_interval(mins => floor(extract('minute' FROM locals.utc_now) / 15)::int * 15)
            ),
	   		locals.words_read_since_last_commit,
	   		update_read_progress.analytics::json->'client'->'type'
		)
		ON CONFLICT (
		    user_account_id,
		    article_id,
		    period
		)
		DO UPDATE SET
		    words_read = user_article_progress.words_read + locals.words_read_since_last_commit;
	  	-- update the user_article
		UPDATE
		    core.user_article
		SET
			read_state = update_read_progress.read_state,
			words_read = locals.words_read,
			last_modified = locals.utc_now,
			analytics = update_read_progress.analytics::json
		WHERE
		    user_article.id = update_read_progress.user_article_id
		RETURNING
		    *
		INTO
		    locals.current_user_article;
		-- check if this update completed the page
		IF
			locals.current_user_article.date_completed IS NULL AND
			article_api.get_percent_complete(locals.current_user_article.readable_word_count, locals.words_read) >= 90
		THEN
			-- set date_completed
			UPDATE
			    core.user_article
			SET
			    date_completed = user_article.last_modified
			WHERE
			    user_article.id = update_read_progress.user_article_id
			RETURNING
			    *
			INTO
			    locals.current_user_article;
			-- update the cached article read count and set community_read_timestamp if necessary
			UPDATE
			    core.article
			SET
			    read_count = article.read_count + 1,
			    community_read_timestamp = (
			        CASE WHEN
			            article.community_read_timestamp IS NULL AND
			            article.read_count = 1
			        THEN
			            locals.utc_now
			        ELSE
			            article.community_read_timestamp
			        END
                ),
			    latest_read_timestamp = locals.utc_now
			WHERE
			    article.id = locals.current_user_article.article_id;
		END IF;
	END IF;
	-- return
	RETURN locals.current_user_article;
END;
$$;

/*
	Update user account creation function to assign free trial credits during account creation.
 */
CREATE OR REPLACE FUNCTION
	user_account_api.create_user_account(
		name text,
		email text,
		password_hash bytea,
		password_salt bytea,
		time_zone_id bigint,
		theme text,
		analytics text
	)
RETURNS
	SETOF core.user_account
LANGUAGE plpgsql
AS $$
<<locals>>
DECLARE
    new_user core.user_account;
BEGIN
    -- create new user
    INSERT INTO
        core.user_account (
            name,
            email,
            password_hash,
            password_salt,
            time_zone_id,
            creation_analytics
        )
    VALUES
        (
            trim(
                create_user_account.name
            ),
            trim(
                create_user_account.email
            ),
            create_user_account.password_hash,
            create_user_account.password_salt,
            create_user_account.time_zone_id,
            create_user_account.analytics::json
        )
    RETURNING
        *
    INTO
        locals.new_user;
    -- set initial notification preference
    INSERT INTO
        core.notification_preference (
            user_account_id
        )
	VALUES (
	    locals.new_user.id
    );
    -- set initial display preference if a theme is provided
     IF create_user_account.theme IS NOT NULL THEN
        PERFORM
            user_account_api.set_display_preference(
                user_account_id => locals.new_user.id,
                theme => create_user_account.theme,
                text_size => 1,
                hide_links => TRUE
            );
    END IF;
    -- assign initial free trial credits
    PERFORM
    	subscriptions.create_free_trial_credit(
    		user_account_id => locals.new_user.id,
    		credit_trigger => 'account_created'::core.free_trial_credit_trigger::text,
    		credit_type => 'article_view'::core.free_trial_credit_type::text,
    		credit_amount => 5
    	);
    -- return user
    RETURN NEXT
        locals.new_user;
END;
$$;

/*
	Update provisional account merging function to copy date_viewed column.
 */
CREATE OR REPLACE FUNCTION
	user_account_api.merge_provisional_user_account(
		provisional_user_account_id bigint,
		user_account_id bigint
	)
RETURNS
	SETOF core.provisional_user_account
LANGUAGE
	plpgsql
AS $$
BEGIN
    -- check to make sure the provisional account hasn't already been merged
    IF
        (
            SELECT
                provisional_user_account.merged_user_account_id
            FROM
                core.provisional_user_account
            WHERE
                provisional_user_account.id = merge_provisional_user_account.provisional_user_account_id
            FOR UPDATE
        )
        IS NOT NULL
    THEN
        RAISE EXCEPTION
            'Account has already been merged.'
        USING
            ERRCODE = 'RU001';
    END IF;
    -- merge user articles
    INSERT INTO
        core.user_article (
            article_id,
            user_account_id,
            date_created,
            last_modified,
            read_state,
            words_read,
            date_completed,
            readable_word_count,
            date_viewed,
            analytics
        )
    SELECT
        provisional_user_article.article_id,
        merge_provisional_user_account.user_account_id,
        provisional_user_article.date_created,
        provisional_user_article.last_modified,
        provisional_user_article.read_state,
        provisional_user_article.words_read,
        provisional_user_article.date_completed,
        provisional_user_article.readable_word_count,
        provisional_user_article.date_viewed,
        provisional_user_article.analytics
    FROM
        core.provisional_user_article
        LEFT JOIN
            core.user_article AS conflicting_user_article ON
                conflicting_user_article.article_id = provisional_user_article.article_id AND
                conflicting_user_article.user_account_id = merge_provisional_user_account.user_account_id
    WHERE
        provisional_user_article.provisional_user_account_id = merge_provisional_user_account.provisional_user_account_id AND
        conflicting_user_article.id IS NULL;
    -- merge user article progress
    INSERT INTO
        core.user_article_progress (
            user_account_id,
            article_id,
            period,
            words_read,
            client_type
        )
    SELECT
        merge_provisional_user_account.user_account_id,
        provisional_user_article_progress.article_id,
        provisional_user_article_progress.period,
        provisional_user_article_progress.words_read,
        provisional_user_article_progress.client_type
    FROM
        core.provisional_user_article_progress
        LEFT JOIN
            core.user_article_progress AS conflicting_progress ON
                conflicting_progress.user_account_id = merge_provisional_user_account.user_account_id AND
                conflicting_progress.article_id = provisional_user_article_progress.article_id
    WHERE
        provisional_user_article_progress.provisional_user_account_id = merge_provisional_user_account.provisional_user_account_id AND
        conflicting_progress.id IS NULL;
    -- update and return provisional account
    RETURN QUERY
    UPDATE
        core.provisional_user_account
    SET
        date_merged = core.utc_now(),
        merged_user_account_id = merge_provisional_user_account.user_account_id
    WHERE
        provisional_user_account.id = merge_provisional_user_account.provisional_user_account_id AND
        provisional_user_account.merged_user_account_id IS NULL
    RETURNING
        *;
END;
$$;

/*
	Assign free trial credits to existing non-free-for-life user accounts.
 */
INSERT INTO
	core.free_trial_credit (
		date_created,
		user_account_id,
		credit_trigger,
		credit_type,
		amount_credited,
		amount_remaining
	)
SELECT
	core.utc_now(),
	user_account.id,
	'account_created'::core.free_trial_credit_trigger,
	'article_view'::core.free_trial_credit_type,
	5,
	5
FROM
	core.user_account
WHERE
	user_account.date_created >= '2021-05-06T04:00:00';