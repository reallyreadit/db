# reallyread.it db
## Setup Guide
1. Install PostgreSQL 9.6
2. Configure pgpass.conf (recommended -- allows for storing of passwords)
3. Create the database (use the username you chose when installing PostgreSQL in this and all other commands)
    psql --file=create-database.sql --host=localhost --username=postgres
4. Configure the database
    psql --dbname=rrit --file=configure-database.sql --host=localhost --username=postgres
5. Create the database objects
    .\create-database-objects.ps1
6. Scheduled tasks
The following functions are called periodically in production by a cron job:
    schemas\article_api\functions\score_articles.sql
    schemas\article_api\functions\set_aotd.sql