CREATE TABLE core.client_error_report (
	id bigserial PRIMARY KEY,
	date_created timestamp NOT NULL DEFAULT core.utc_now(),
	content text,
	analytics jsonb
);
CREATE FUNCTION analytics.log_client_error_report(
	content text,
	analytics text
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO
    	core.client_error_report (
    		content,
    	    analytics
    	)
    VALUES (
        log_client_error_report.content,
        log_client_error_report.analytics::jsonb
	);
$$;