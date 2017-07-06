CREATE SCHEMA article_api;
CREATE SCHEMA core;
CREATE SCHEMA pgcrypto;
CREATE SCHEMA user_account_api;

ALTER DATABASE rrit SET search_path TO core;

DROP SCHEMA public;

CREATE EXTENSION pgcrypto SCHEMA pgcrypto;