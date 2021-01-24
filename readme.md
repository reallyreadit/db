# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6: https://www.postgresql.org/download/
2. Configure a password file for the server: https://www.postgresql.org/docs/9.6/libpq-pgpass.html
3. Restore a database dump, supplying the desired name of the database. If there is an existing database with the same name it will be dropped before a new one is created.
        
        dev-scripts/restore.ps1 -DbName rrit -DumpFile /users/jeff/downloads/2020-01-23-dev.sql