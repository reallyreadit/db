DROP FUNCTION user_account_api.get_user_account_using_old_id(
	user_account_id uuid
);
DROP TABLE id_migration.article;
DROP TABLE id_migration.author;
DROP TABLE id_migration.bulk_mailing;
DROP TABLE id_migration.comment;
DROP TABLE id_migration.email_bounce;
DROP TABLE id_migration.email_confirmation;
DROP TABLE id_migration.page;
DROP TABLE id_migration.password_reset_request;
DROP TABLE id_migration.source;
DROP TABLE id_migration.source_rule;
DROP TABLE id_migration.tag;
DROP TABLE id_migration.user_account;
DROP TABLE id_migration.user_page;
DROP SCHEMA id_migration;