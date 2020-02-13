CREATE TYPE core.notification_authorization_request_result AS ENUM (
    'none',
    'granted',
    'denied',
    'previously_granted',
    'previously_denied'
);
CREATE TABLE core.share_result (
    id uuid PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    client_type text NOT NULL,
    user_account_id bigint REFERENCES core.user_account (id),
    action text NOT NULL,
    activity_type text NOT NULL,
    completed bool,
    error text
);
CREATE TABLE core.orientation_analytics (
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    user_account_id bigint NOT NULL REFERENCES core.user_account (id),
    tracking_play_count int NOT NULL,
    tracking_skipped bool NOT NULL,
    tracking_duration int NOT NULL,
    import_play_count int NOT NULL,
    import_skipped bool NOT NULL,
    import_duration int NOT NULL,
    notifications_result core.notification_authorization_request_result NOT NULL,
    notifications_skipped bool NOT NULL,
    notifications_duration int NOT NULL,
    share_result_id uuid REFERENCES core.share_result (id),
    share_skipped bool NOT NULL,
    share_duration int NOT NULL,
    PRIMARY KEY (date_created, user_account_id)
);
CREATE FUNCTION analytics.log_share_result(
    id uuid,
    client_type text,
    user_account_id bigint,
    action text,
    activity_type text,
    completed bool,
    error text
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO core.share_result (
        id,
        client_type,
        user_account_id,
        action,
        activity_type,
        completed,
        error
    )
    VALUES (
        log_share_result.id,
        log_share_result.client_type,
        log_share_result.user_account_id,
        log_share_result.action,
        log_share_result.activity_type,
        log_share_result.completed,
        log_share_result.error
    );
$$;
CREATE FUNCTION analytics.log_orientation_analytics(
    user_account_id bigint,
    tracking_play_count int,
    tracking_skipped bool,
    tracking_duration int,
    import_play_count int,
    import_skipped bool,
    import_duration int,
    notifications_result text,
    notifications_skipped bool,
    notifications_duration int,
    share_result_id uuid,
    share_skipped bool,
    share_duration int
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO core.orientation_analytics (
        user_account_id,
        tracking_play_count,
        tracking_skipped,
        tracking_duration,
        import_play_count,
        import_skipped,
        import_duration,
        notifications_result,
        notifications_skipped,
        notifications_duration,
        share_result_id,
        share_skipped,
        share_duration
    )
    VALUES (
        log_orientation_analytics.user_account_id,
        log_orientation_analytics.tracking_play_count,
        log_orientation_analytics.tracking_skipped,
        log_orientation_analytics.tracking_duration,
        log_orientation_analytics.import_play_count,
        log_orientation_analytics.import_skipped,
        log_orientation_analytics.import_duration,
        log_orientation_analytics.notifications_result::core.notification_authorization_request_result,
        log_orientation_analytics.notifications_skipped,
        log_orientation_analytics.notifications_duration,
        log_orientation_analytics.share_result_id,
        log_orientation_analytics.share_skipped,
        log_orientation_analytics.share_duration
    );
$$;