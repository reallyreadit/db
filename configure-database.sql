CREATE SCHEMA article_api;
CREATE SCHEMA bulk_mailing_api;
CREATE SCHEMA challenge_api;
CREATE SCHEMA core;
CREATE SCHEMA stats_api;
CREATE SCHEMA user_account_api;

ALTER DATABASE rrit SET search_path TO core;

DROP SCHEMA public;