-- Copyright (C) 2022 reallyread.it, inc.
-- 
-- This file is part of Readup.
-- 
-- Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
-- 
-- Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
-- 
-- You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

-- Set final "free-for-life" cutoff date.
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
	IF (
		SELECT
			user_account.date_created >= '2021-05-06T04:00:00' AND
			(
				user_account.subscription_end_date IS NULL OR
				user_account.subscription_end_date <= locals.utc_now
			)
		FROM
			core.user_account
		WHERE
			user_account.id = locals.current_user_article.user_account_id
	) AND (
		SELECT
			article.source_id != 48542 -- readup blog
		FROM
			core.article
		WHERE
			article.id = current_user_article.article_id
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