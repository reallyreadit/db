CREATE TABLE captcha_response (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT utc_now(),
    action_verified text NOT NULL,
    success boolean,
    score double precision,
    action text,
    challenge_ts timestamp,
    hostname text,
    error_codes text[]
);
CREATE FUNCTION user_account_api.create_captcha_response(
    action_verified text,
	success boolean,
    score double precision,
    action text,
    challenge_ts timestamp,
    hostname text,
    error_codes text[]
)
RETURNS void
LANGUAGE SQL
AS $func$
    INSERT INTO captcha_response (action_verified, success, score, action, challenge_ts, hostname, error_codes)
    VALUES (action_verified, success, score, action, challenge_ts, hostname, error_codes);
$func$;