-- update daily totals report
DROP FUNCTION analytics.get_key_metrics(
    start_date timestamp,
    end_date timestamp
);
CREATE FUNCTION analytics.get_daily_totals(
    start_date timestamp,
    end_date timestamp
)
RETURNS TABLE(
    day timestamp,
    signup_app_count bigint,
    signup_browser_count bigint,
    signup_unknown_count bigint,
    read_app_count bigint,
    read_browser_count bigint,
    read_unknown_count bigint,
    post_app_count bigint,
    post_browser_count bigint,
    post_unknown_count bigint,
    reply_app_count bigint,
    reply_browser_count bigint,
    reply_unknown_count bigint,
    post_tweet_app_count bigint,
    post_tweet_browser_count bigint,
    extension_installation_count bigint,
    extension_removal_count bigint
)
LANGUAGE sql
STABLE
AS $$
	WITH report_period AS (
		SELECT
		    date AS day,
			tsrange(date, date + '1 day'::interval) AS range
		FROM generate_series(
		    get_daily_totals.start_date,
		    get_daily_totals.end_date,
		    '1 day'::interval
		) AS series (date)
	)
	SELECT
		report_period.day,
		coalesce(signup_totals.app_count, 0),
		coalesce(signup_totals.browser_count, 0),
		coalesce(signup_totals.unknown_count, 0),
		coalesce(read_totals.app_count, 0),
		coalesce(read_totals.browser_count, 0),
		coalesce(read_totals.unknown_count, 0),
		coalesce(comment_totals.post_app_count, 0) + coalesce(silent_post_totals.app_count, 0),
		coalesce(comment_totals.post_browser_count, 0) + coalesce(silent_post_totals.browser_count, 0),
		coalesce(comment_totals.post_unknown_count, 0) + coalesce(silent_post_totals.unknown_count, 0),
	    coalesce(comment_totals.reply_app_count, 0),
	    coalesce(comment_totals.reply_browser_count, 0),
	    coalesce(comment_totals.reply_unknown_count, 0),
	    coalesce(post_tweet_total.app_count, 0) AS post_tweet_app_count,
		coalesce(post_tweet_total.browser_count, 0) AS post_tweet_browser_count,
	    coalesce(extension_installation_total.count, 0) AS extension_installation_count,
	    coalesce(extension_removal_total.count, 0) AS extension_removal_count
	FROM
		report_period
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'App') AS app_count,
				count(*) FILTER (WHERE creation_analytics->'client'->>'mode' = 'Browser') AS browser_count,
				count(*) FILTER (WHERE creation_analytics IS NULL) AS unknown_count
			FROM
				user_account
				JOIN report_period ON user_account.date_created <@ report_period.range
			GROUP BY report_period.day
		) AS signup_totals ON signup_totals.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'ios/app') AS app_count,
				count(*) FILTER (WHERE analytics->'client'->>'type' = 'web/extension') AS browser_count,
				count(*) FILTER (WHERE analytics IS NULL) AS unknown_count
			FROM
				user_article
				JOIN report_period ON user_article.date_completed <@ report_period.range
			GROUP BY report_period.day
		) AS read_totals ON read_totals.day = report_period.day
		LEFT JOIN (
            SELECT
                report_period.day,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NULL AND
                        (
                            comment.analytics->'client'->>'mode' = 'App' OR
                            comment.analytics->'client'->>'type' = 'ios/app'
                        )
                ) AS post_app_count,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NULL AND
                        (
                            comment.analytics->'client'->>'mode' = 'Browser' OR
                            comment.analytics->'client'->>'type' = 'web/extension'
                        )
                ) AS post_browser_count,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NULL AND
                        comment.analytics IS NULL
                ) AS post_unknown_count,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NOT NULL AND
                        (
                            comment.analytics->'client'->>'mode' = 'App' OR
                            comment.analytics->'client'->>'type' = 'ios/app'
                        )
                ) AS reply_app_count,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NOT NULL AND
                        (
                            comment.analytics->'client'->>'mode' = 'Browser' OR
                            comment.analytics->'client'->>'type' = 'web/extension'
                        )
                ) AS reply_browser_count,
                count(*) FILTER (
                    WHERE
                        comment.parent_comment_id IS NOT NULL AND
                        comment.analytics IS NULL
                ) AS reply_unknown_count
            FROM
                report_period
                JOIN core.comment ON
                    comment.date_created <@ report_period.range
            GROUP BY
                report_period.day
        ) AS comment_totals ON
            comment_totals.day = report_period.day
		LEFT JOIN (
            SELECT
                report_period.day,
                count(*) FILTER (
                    WHERE
                        silent_post.analytics->'client'->>'mode' = 'App' OR
                        silent_post.analytics->'client'->>'type' = 'ios/app'
                ) AS app_count,
                count(*) FILTER (
                    WHERE
                        silent_post.analytics->'client'->>'mode' = 'Browser' OR
                        silent_post.analytics->'client'->>'type' = 'web/extension'
                ) AS browser_count,
                count(*) FILTER (WHERE silent_post.analytics IS NULL) AS unknown_count
            FROM
                report_period
                JOIN core.silent_post ON
                    silent_post.date_created <@ report_period.range
            GROUP BY
                report_period.day
        ) AS silent_post_totals ON
            silent_post_totals.day = report_period.day
        LEFT JOIN (
            SELECT
                report_period.day,
                count(*) FILTER (
                    WHERE
                        comment.analytics->'client'->>'mode' = 'App' OR
                        comment.analytics->'client'->>'type' = 'ios/app' OR
                        silent_post.analytics->'client'->>'mode' = 'App' OR
                        silent_post.analytics->'client'->>'type' = 'ios/app'
                ) AS app_count,
                count(*) FILTER (
                    WHERE
                        comment.analytics->'client'->>'mode' = 'Browser' OR
                        comment.analytics->'client'->>'type' = 'web/extension' OR
                        silent_post.analytics->'client'->>'mode' = 'Browser' OR
                        silent_post.analytics->'client'->>'type' = 'web/extension'
                ) AS browser_count
            FROM
                report_period
                JOIN core.auth_service_post ON
                    auth_service_post.date_posted <@ report_period.range
                LEFT JOIN core.comment ON
                    comment.id = auth_service_post.comment_id
                LEFT JOIN core.silent_post ON
                    silent_post.id = auth_service_post.silent_post_id
            GROUP BY
                report_period.day
        ) AS post_tweet_total ON
            post_tweet_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
			    count(*) AS count
			FROM
				extension_installation
		    	JOIN report_period ON extension_installation.timestamp <@ report_period.range
		    GROUP BY
		    	report_period.day
		) AS extension_installation_total ON extension_installation_total.day = report_period.day
		LEFT JOIN (
			SELECT
				report_period.day,
			    count(*) AS count
			FROM
				extension_removal
		    	JOIN report_period ON extension_removal.timestamp <@ report_period.range
		    GROUP BY
		    	report_period.day
		) AS extension_removal_total ON extension_removal_total.day = report_period.day
	ORDER BY report_period.day DESC;
$$;

-- update signups report
DROP FUNCTION analytics.get_user_account_creations(
    start_date timestamp,
    end_date timestamp
);
CREATE FUNCTION analytics.get_signups(
    start_date timestamp,
    end_date timestamp
)
RETURNS TABLE(
    id bigint,
    name text,
    email text,
    date_created timestamp,
    time_zone_name text,
    client_mode text,
    marketing_variant integer,
    referrer_url text,
    initial_path text,
    current_path text,
    action text,
    orientation_share_count bigint,
    article_view_count bigint,
    article_read_count bigint,
    post_tweet_count bigint
)
LANGUAGE sql
STABLE
AS $$
	SELECT
		user_account.id,
	    user_account.name,
	    user_account.email,
	    user_account.date_created,
	    time_zone.name,
	    user_account.creation_analytics->'client'->>'mode',
	    (user_account.creation_analytics->>'marketing_variant')::int,
	    user_account.creation_analytics->>'referrer_url',
	    user_account.creation_analytics->>'initial_path',
	    user_account.creation_analytics->>'current_path',
	    user_account.creation_analytics->>'action',
	    coalesce(orientation_share.count, 0),
	    coalesce(user_article_stats.view_count, 0),
	    coalesce(user_article_stats.read_count, 0),
	    coalesce(post_tweets.count, 0)
	FROM
		user_account
    	LEFT JOIN time_zone ON
    	    time_zone.id = user_account.time_zone_id
	    LEFT JOIN (
            SELECT
                share_result.user_account_id,
                count(*) AS count
            FROM
                core.share_result
            WHERE
                share_result.action = 'OrientationShare' AND
                (
                    share_result.completed OR
                    share_result.client_type = 'web_app_client'
                )
            GROUP BY
                share_result.user_account_id
        ) AS orientation_share ON
            orientation_share.user_account_id = user_account.id
        LEFT JOIN (
            SELECT
                user_article.user_account_id,
                count(*) AS view_count,
                count(*) FILTER (WHERE user_article.date_completed IS NOT NULL) AS read_count
            FROM
                core.user_article
            GROUP BY
                user_article.user_account_id
        ) AS user_article_stats ON
            user_article_stats.user_account_id = user_account.id
        LEFT JOIN (
            SELECT
                association.user_account_id,
                count(*) AS count
            FROM
                core.auth_service_post AS post
                JOIN auth_service_identity AS identity ON
                    identity.id = post.identity_id
                JOIN auth_service_association AS association ON
                    association.identity_id = identity.id
            GROUP BY
                association.user_account_id
        ) AS post_tweets ON
            post_tweets.user_account_id = user_account.id
    WHERE
    	user_account.date_created <@ tsrange(get_signups.start_date, get_signups.end_date)
    ORDER BY
    	user_account.date_created DESC
$$;

-- create activations report
CREATE TABLE core.website_traffic_weekly_total (
    week timestamp PRIMARY KEY,
    unique_visit_count int NOT NULL
);
CREATE FUNCTION analytics.get_conversions(
    start_date timestamp,
    end_date timestamp
)
RETURNS TABLE (
    week timestamp,
    visit_count bigint,
    signup_count bigint,
    signup_conversion numeric,
    share_count bigint,
    share_conversion numeric,
    article_view_count bigint,
    article_view_conversion numeric,
    article_read_count bigint,
    article_read_conversion numeric,
    post_tweet_count bigint,
    post_tweet_conversion numeric
)
LANGUAGE sql
STABLE
AS $$
    WITH report_period AS (
        SELECT
            first_day AS week,
            tsrange(first_day, first_day + '1 week'::interval) AS range
        FROM
            generate_series(
                get_conversions.start_date,
                get_conversions.end_date,
                '1 week'::interval
            ) AS week (first_day)
    ),
    user_activation AS (
        SELECT
            user_account.id AS user_id,
            user_account.date_created AS signup_date,
            read_activation.first_article_view,
            read_activation.first_article_read,
            tweet_activation.first_tweet
        FROM
            core.user_account
            LEFT JOIN (
                SELECT
                    user_article.user_account_id,
                    min(user_article.date_created) AS first_article_view,
                    min(user_article.date_completed) AS first_article_read
                FROM
                    core.user_article
                GROUP BY
                    user_article.user_account_id
            ) AS read_activation ON
                read_activation.user_account_id = user_account.id
            LEFT JOIN (
                SELECT
                    association.user_account_id,
                    min(post.date_posted) AS first_tweet
                FROM
                    core.auth_service_post AS post
                    JOIN core.auth_service_identity AS identity ON
                        identity.id = post.identity_id
                    JOIN core.auth_service_association AS association ON
                        association.identity_id = identity.id
                GROUP BY
                    association.user_account_id
            ) AS tweet_activation ON
                tweet_activation.user_account_id = user_account.id
    )
    SELECT
        report_period.week,
        visit_total.count,
        signup_total.count,
        (
            CASE WHEN visit_total.count > 0
                THEN signup_total.count::numeric / visit_total.count
                ELSE 0
            END
        ),
        first_orientation_share_total.count,
        (
            CASE WHEN signup_total.count > 0
                THEN first_orientation_share_total.count::numeric / signup_total.count
                ELSE 0
            END
        ),
        activation_total.view_count,
        (
            CASE WHEN signup_total.count > 0
                THEN activation_total.view_count::numeric / signup_total.count
                ELSE 0
            END
        ),
        activation_total.read_count,
        (
            CASE WHEN activation_total.view_count > 0
                THEN activation_total.read_count::numeric / activation_total.view_count
                ELSE 0
            END
        ),
        activation_total.tweet_count,
        (
            CASE WHEN activation_total.read_count > 0
                THEN activation_total.tweet_count::numeric / activation_total.read_count
                ELSE 0
            END
        )
    FROM
        report_period
        JOIN (
            SELECT
                report_period.week,
                coalesce(sum(traffic_total.unique_visit_count), 0) AS count
            FROM
                report_period
                LEFT JOIN core.website_traffic_weekly_total AS traffic_total ON
                    traffic_total.week <@ report_period.range
            GROUP BY
                report_period.week
        ) AS visit_total ON
            visit_total.week = report_period.week
        JOIN (
            SELECT
                report_period.week,
                coalesce(count(user_account.id), 0) AS count
            FROM
                report_period
                LEFT JOIN core.user_account ON
                    user_account.date_created <@ report_period.range
            GROUP BY
                report_period.week
        ) AS signup_total ON
            signup_total.week = report_period.week
        JOIN (
            SELECT
                report_period.week,
                coalesce(count(DISTINCT share_result.user_account_id), 0) AS count
            FROM
                report_period
                LEFT JOIN core.share_result ON
                    share_result.date_created <@ report_period.range AND
                    share_result.action = 'OrientationShare' AND
                    (
                        share_result.completed OR
                        share_result.client_type = 'web_app_client'
                    )
            GROUP BY
                report_period.week
        ) AS first_orientation_share_total ON
            first_orientation_share_total.week = report_period.week
        JOIN (
            SELECT
                report_period.week,
                coalesce(count(user_activation.user_id) FILTER (WHERE user_activation.first_article_view < user_activation.signup_date + '1 week'::interval), 0) AS view_count,
                coalesce(count(user_activation.user_id) FILTER (WHERE user_activation.first_article_read < user_activation.signup_date + '1 week'::interval), 0) AS read_count,
                coalesce(count(user_activation.user_id) FILTER (WHERE user_activation.first_tweet < user_activation.signup_date + '1 week'::interval), 0) AS tweet_count
            FROM
                report_period
                LEFT JOIN user_activation ON
                    user_activation.signup_date <@ report_period.range
            GROUP BY
                report_period.week
        ) AS activation_total ON
            activation_total.week = report_period.week
    ORDER BY
        report_period.week DESC
$$;