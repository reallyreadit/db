CREATE TABLE email_notification (
    id bigserial PRIMARY KEY,
    notification_type text NOT NULL,
    mail jsonb,
	bounce jsonb,
	complaint jsonb
);