-- Making Readup free to use!

-- Don't assign free credits during account creation.
CREATE OR REPLACE FUNCTION user_account_api.create_user_account(
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
LANGUAGE
	plpgsql
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
    -- return user
    RETURN NEXT
        locals.new_user;
END;
$$;

-- Don't check if allowed to read before updating progress.
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