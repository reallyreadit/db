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