# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6: https://www.postgresql.org/download/
2. Configure a password file for the server: https://www.postgresql.org/docs/9.6/libpq-pgpass.html
    The following format should be used so that the password file is used for all databases. Don't forget to set the appropriate permissions on Unix systems.
    
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
5. Restore a database dump, supplying the desired name of the database. If there is an existing database with the same name it will be dropped before a new one is created.
        
        pwsh dev-scripts/restore.ps1 -DbName rrit -DumpFile /Users/jeff/Downloads/2020-01-23-dev.tar