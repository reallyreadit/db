/*
	Coalesce null results into empty arrays.
*/

CREATE OR REPLACE FUNCTION
	social.get_posts_from_user(
		subject_user_name text,
		page_size integer,
		page_number integer
)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
    WITH subject_user_account AS (
        SELECT
        	id
        FROM
        	user_account_api.get_user_account_id_by_name(get_posts_from_user.subject_user_name) AS user_account (id)
	),
	user_post AS (
	    SELECT
	        post.date_created,
	        post.comment_id,
	        post.silent_post_id
	    FROM
	    	core.post
	    WHERE
	    	post.user_account_id = (
	    		SELECT
	    		    id
	    		FROM
	    			subject_user_account
	    	) AND
	        post.date_deleted IS NULL
	    ORDER BY
			post.date_created DESC
		OFFSET
			(get_posts_from_user.page_number - 1) * get_posts_from_user.page_size
		LIMIT
			get_posts_from_user.page_size
	)
    SELECT
		coalesce(
			(
				SELECT
					array_agg(
						(user_post.comment_id, user_post.silent_post_id)::social.post_reference
						ORDER BY
							user_post.date_created DESC
					)
				FROM
					user_post
			),
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        core.post
		    WHERE
		    	user_account_id = (
		    	    SELECT
		    	        id
		    		FROM
		    		    subject_user_account
		    	)
		);
$$;

CREATE OR REPLACE FUNCTION
	social.get_posts_from_followees_v1(
		user_id bigint,
		page_number integer,
		page_size integer,
		min_length integer,
		max_length integer
)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH followee_post AS (
	    SELECT
	        post.date_created,
	        post.comment_id,
	        post.silent_post_id
	    FROM
	    	core.post
	    	JOIN core.article ON article.id = post.article_id
	    	JOIN social.active_following ON active_following.followee_user_account_id = post.user_account_id
	    WHERE
	        post.date_deleted IS NULL AND
	    	active_following.follower_user_account_id = get_posts_from_followees_v1.user_id AND
	        core.matches_article_length(
				article.word_count,
				get_posts_from_followees_v1.min_length,
				get_posts_from_followees_v1.max_length
			)
	),
	paginated_post AS (
	    SELECT
	    	*
	    FROM
	    	followee_post
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_followees_v1.page_number - 1) * get_posts_from_followees_v1.page_size
		LIMIT
			get_posts_from_followees_v1.page_size
	)
    SELECT
		coalesce(
			(
				SELECT
					array_agg(
						(paginated_post.comment_id, paginated_post.silent_post_id)::social.post_reference
						ORDER BY
							paginated_post.date_created DESC
					)
				FROM
					paginated_post
			),
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        followee_post
		)
$$;

CREATE OR REPLACE FUNCTION
	social.get_notification_posts_v1(
		user_id bigint,
		page_number integer,
		page_size integer
)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH notification_post AS (
	    -- followee post
	    SELECT
			followee_post.date_created,
			followee_post.comment_id,
			followee_post.silent_post_id
	    FROM
	    	core.post AS followee_post
	    	JOIN social.active_following ON
	    	    active_following.followee_user_account_id = followee_post.user_account_id AND
	    	    active_following.follower_user_account_id = get_notification_posts_v1.user_id AND
	    	    followee_post.date_deleted IS NULL
	    UNION ALL
	    -- loopback comment
	    SELECT
			loopback.date_created,
			loopback.id AS comment_id,
			NULL::bigint AS silent_post_id
	    FROM
	        social.comment AS loopback
	        JOIN core.user_article AS completed_article ON
	            completed_article.article_id = loopback.article_id AND
	            completed_article.date_completed < loopback.date_created AND
	            loopback.parent_comment_id IS NULL AND
	            loopback.user_account_id != completed_article.user_account_id AND
	            loopback.date_deleted IS NULL AND
	            completed_article.user_account_id = get_notification_posts_v1.user_id
	        LEFT JOIN social.active_following ON
	            active_following.followee_user_account_id = loopback.user_account_id AND
	            active_following.follower_user_account_id = completed_article.user_account_id
	    WHERE
	        active_following.id IS NULL
	),
	paginated_post AS (
	    SELECT
	    	notification_post.*
	    FROM
	    	notification_post
	    ORDER BY
			notification_post.date_created DESC
		OFFSET
			(get_notification_posts_v1.page_number - 1) * get_notification_posts_v1.page_size
		LIMIT
			get_notification_posts_v1.page_size
	)
	SELECT
		coalesce(
			(
				SELECT
					array_agg(
						(paginated_post.comment_id, paginated_post.silent_post_id)::social.post_reference
						ORDER BY
							paginated_post.date_created DESC
					)
				FROM
					paginated_post
			),
			ARRAY[]::social.post_reference[]
		),
		(
			SELECT
				count(notification_post.*)::int
			FROM
				notification_post
		);
$$;

CREATE OR REPLACE FUNCTION
	social.get_posts_from_inbox_v1(
		user_id bigint,
		page_number integer,
		page_size integer
)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH inbox_comment AS (
	    SELECT
	    	reply.id,
	        reply.date_created
	    FROM
	    	core.comment
	    	JOIN social.comment AS reply ON reply.parent_comment_id = comment.id
	    WHERE
	    	comment.user_account_id = get_posts_from_inbox_v1.user_id AND
	        reply.user_account_id != get_posts_from_inbox_v1.user_id AND
	        reply.date_deleted IS NULL
	    UNION ALL
	    SELECT
	    	comment.id,
	        comment.date_created
	    FROM
	    	core.user_article
	    	JOIN social.comment ON comment.article_id = user_article.article_id
	    WHERE
	    	user_article.user_account_id = get_posts_from_inbox_v1.user_id AND
	    	user_article.date_completed IS NOT NULL AND
	        comment.user_account_id != get_posts_from_inbox_v1.user_id AND
	        comment.parent_comment_id IS NULL AND
	        comment.date_created > user_article.date_completed AND
	        comment.date_deleted IS NULL
	),
	paginated_inbox_comment AS (
	    SELECT
	    	*
	    FROM
	    	inbox_comment
	    ORDER BY
			date_created DESC
		OFFSET
			(get_posts_from_inbox_v1.page_number - 1) * get_posts_from_inbox_v1.page_size
		LIMIT
			get_posts_from_inbox_v1.page_size
	)
    SELECT
		coalesce(
			(
				SELECT
					array_agg(
						(paginated_inbox_comment.id, NULL::bigint)::social.post_reference
						ORDER BY
							paginated_inbox_comment.date_created DESC
					)
				FROM
					paginated_inbox_comment
			),
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(*)::int
		    FROM
		        inbox_comment
		);
$$;

CREATE OR REPLACE FUNCTION
	social.get_reply_posts_v1(
		user_id bigint,
		page_number integer,
		page_size integer
)
RETURNS
	social.post_references_page
LANGUAGE
	sql
STABLE
AS $$
	WITH reply AS (
	    SELECT
	    	reply.id,
	        reply.date_created
	    FROM
	    	core.comment AS parent
	    	JOIN social.comment AS reply ON
	    	    reply.parent_comment_id = parent.id AND
                parent.user_account_id = get_reply_posts_v1.user_id AND
                reply.user_account_id != get_reply_posts_v1.user_id AND
                reply.date_deleted IS NULL
	),
	paginated_reply AS (
	    SELECT
	    	reply.*
	    FROM
	    	reply
	    ORDER BY
			reply.date_created DESC
		OFFSET
			(get_reply_posts_v1.page_number - 1) * get_reply_posts_v1.page_size
		LIMIT
			get_reply_posts_v1.page_size
	)
    SELECT
		coalesce(
			(
				SELECT
					array_agg(
						(paginated_reply.id, NULL::bigint)::social.post_reference
						ORDER BY
							paginated_reply.date_created DESC
					)
				FROM
					paginated_reply
			),
			ARRAY[]::social.post_reference[]
		),
		(
		    SELECT
		    	count(reply.*)::int
		    FROM
		        reply
		);
$$;