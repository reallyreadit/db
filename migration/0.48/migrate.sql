DROP FUNCTION bulk_mailing_api.list_email_bounces();
DROP TABLE email_bounce;

CREATE TABLE email_notification (
    id bigserial PRIMARY KEY,
    notification_type text NOT NULL,
    mail jsonb,
	bounce jsonb,
	complaint jsonb
);

CREATE FUNCTION bulk_mailing_api.create_email_notification(
	notification_type text,
    mail text,
	bounce text,
	complaint text
)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO email_notification
        (notification_type, mail, bounce, complaint)
    VALUES
		(notification_type, mail::json, bounce::json, complaint::json);
$func$;

CREATE FUNCTION bulk_mailing_api.get_blocked_email_addresses()
RETURNS SETOF text
LANGUAGE SQL
STABLE
AS $func$
	SELECT DISTINCT lower(recipient->>'email_address')
	FROM (
		SELECT jsonb_array_elements(bounce->'bounced_recipients')
		FROM email_notification
		UNION ALL
		SELECT jsonb_array_elements(complaint->'complained_recipients')
		FROM email_notification
	) AS row (recipient);
$func$;

INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-18T09:20:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "simon2@example.com", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-03-16T04:19:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "nedampusiga@yahoo.com", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-04T03:22:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "hhardarson@kjarninn.is", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-18T09:57:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "simon@example.com", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-13T03:10:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "anitaptael2016@gmail.com", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-23T10:00:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "throwaway@example.com", "diagnostic_code": null}]}', 'null');
INSERT INTO core.email_notification (notification_type, mail, bounce, complaint) VALUES ('Bounce', 'null', '{"timestamp": "2018-01-06T07:49:00Z", "bounce_type": null, "feedback_id": null, "remote_mta_ip": null, "reporting_mta": null, "bounce_sub_type": null, "bounced_recipients": [{"action": null, "status": null, "email_address": "dorothyyqu@gmail.xom", "diagnostic_code": null}]}', 'null');