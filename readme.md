# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6
2. Create the database

        psql --file=create-database.sql
3. Configure the database

        psql --dbname=rrit --file=configure-database.sql
4. Create the database objects

        PowerShell -File .\create-database-objects.ps1
    
    Note: This PowerShell script just enumerates the paths in the `database-objects` file
    and runs `psql` passing the path as the value for the `--file` argument.
5. Import source rules

        psql --dbname=rrit --file=import-source-rules.sql
6. Scheduled tasks

    The following functions are called periodically in production by a cron job:

        SELECT article_api.score_articles()
        SELECT article_api.set_aotd()
        REFRESH MATERIALIZED VIEW CONCURRENTLY challenge_api.challenge_contender
## Data Import/Export
Anonymized database dumps are located in the `dumps` directory.

`*-dev.tar` dumps are created using the `anonymization\anonymize-dev.sql` script and are intended to provide
developers with an anonymized set of user accounts, articles and comments for software testing purposes.

Only articles that a user has publicly commented on remain in their reading history and all other private user-specific data is homoginized.

The anonymization script sets every user account email address to `USERNAME@localhost` and every password to `password` so you can log in as
any user.
### Export

        pg_dump --file=dumps\FILE-NAME.tar --format=tar --verbose rrit
### Import
1. Drop existing database if it exists

        psql --command='DROP DATABASE rrit'
2. Create the database

        psql --file=create-database.sql
3. Configure the database for restore operation

        psql --dbname=rrit --file=configure-restore-database.sql
4. Restore the database from the dump file

        pg_restore --dbname=rrit --no-owner dumps\FILE-NAME.tar
    Refreshing challenge_api.challenge_contender may fail with an error. It will be fixed in the next step.
5. Refresh the materalized view

        psql --dbname=rrit --command='REFRESH MATERIALIZED VIEW CONCURRENTLY challenge_api.challenge_contender'