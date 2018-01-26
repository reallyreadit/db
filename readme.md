# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6
2. Configure pgpass.conf (recommended -- allows for storing of passwords)
3. Create the database (use the username you chose when installing PostgreSQL in this and all other commands)

        psql --file=create-database.sql --host=localhost --username=postgres
4. Configure the database

        psql --dbname=rrit --file=configure-database.sql --host=localhost --username=postgres
5. Create the database objects

        PowerShell -File .\create-database-objects.ps1
    
    Note: This PowerShell script just enumerates the paths in the `database-objects` file
    and runs `psql` passing the path as the value for the `--file` argument.
6. Import source rules

        psql --dbname=rrit --file=import-source-rules.sql --host=localhost --username=postgres
7. Scheduled tasks

    The following functions are called periodically in production by a cron job:

        schemas\article_api\functions\score_articles.sql
        schemas\article_api\functions\set_aotd.sql
## Data Import/Export
Anonymized database dumps are located in the `dumps` directory.

`*-dev.tar` dumps are created using the `anonymization\anonymize-dev.sql` script and are intended to provide
developers with an anonymized set of user accounts, articles and comments for software testing purposes.

Only articles that a user has publicly commented on remain in their reading history and all other private user-specific data is homoginized.

The anonymization script sets every user account email address to `USERNAME@localhost` and every password to `password` so you can log in as
any user.
### Export

        pg_dump --host=localhost --username=postgres --file=dumps\FILE-NAME.tar --format=tar --verbose rrit
### Import
1. Drop existing database if it exists

        psql --command='DROP DATABASE rrit' --host=localhost --username=postgres
2. Create the database

        psql --file=create-database.sql --host=localhost --username=postgres
3. Configure the database for restore operation

        psql --dbname=rrit --file=configure-restore-database.sql --host=localhost --username=postgres
4. Restore the database from the dump file

        pg_restore --dbname=rrit --host=localhost --username=postgres --no-owner dumps\FILE-NAME.tar