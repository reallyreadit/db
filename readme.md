# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6: https://www.postgresql.org/download/

    The setup wizard will prompt you to create a password for the `postgres` superuser account. Since this is just a local development server you can just use `postgres` as the password so that it is easy to remember.
2. Configure a password file for the server: https://www.postgresql.org/docs/9.6/libpq-pgpass.html
    The following format should be used so that the password file is used for all databases. Don't forget to set the appropriate permissions on Unix systems.

	If you chose `postgres` as your superuser account password you can just copy the following values. Otherwise, replace the password with the one you entered in Step 1.

    ```
    localhost:5432:*:postgres:postgres
    ```
3. Set the `PGUSER` environment variable so that username and password arguments aren't required for database scripts.

    ```
    export PGUSER=postgres
    ```
4. Add the PostgreSQL `bin` directory to your path for easy access to the command line utility `psql`.
    ```
    export PATH=$PATH:/Library/PostgreSQL/9.6/bin
    ```
## Usage Guide
After you complete the Setup Guide your local PostgreSQL server will be up and running and will start automatically with your system. Next up you'll want to restore a database dump file which will create the Readup database and populate it with data.
### Restoring Database Dumps
Restore a database dump any time you need to upgrade to a newer version of the Readup database or simply want to revert the Readup database to a clean slate. Any changes that have been made to the database since the last restore will be lost.

Run the following PowerShell script to restore a database dump, supplying the desired name of the database. Note the following:
- If there is an existing database with the same name it will be dropped before a new one is created.
- The script cannot proceed if there are active connections to an existing database. If you receive the active connections notice then you may need to stop the `api` server or close any active connections from any other SQL clients you may have running.
- It is normal to receive a warning about a failure to refresh the materialized views. This is an issue with `pg_restore` and the materialized views will be refreshed manually before the script finishes.
<!--end list-->
    pwsh dev-scripts/restore.ps1 -DbName rrit -DumpFile /Users/jeff/Downloads/2020-01-23-dev.tar