CREATE TABLE core.new_platform_notification_request (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    email_address varchar (512) NOT NULL,
    ip_address text NOT NULL,
    user_agent text NOT NULL
);

CREATE FUNCTION analytics.log_new_platform_notification_request(
    email_address text,
    ip_address text,
    user_agent text
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO
        core.new_platform_notification_request (
            email_address,
            ip_address,
            user_agent
        )
    VALUES (
        log_new_platform_notification_request.email_address,
        log_new_platform_notification_request.ip_address,
        log_new_platform_notification_request.user_agent
    );
$$;