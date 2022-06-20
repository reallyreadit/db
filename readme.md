# reallyread.it db

## Setup with Docker

See the [dev-env](https://github.com/reallyreadit/dev-env) instructions to set up this database as part of the Docker Compose project.

## Manual Setup
1. Install PostgreSQL 14: https://www.postgresql.org/download/

    The setup wizard will prompt you to create a password for the `postgres` superuser account. Since this is just a local development server you can just use `postgres` as the password so that it is easy to remember.
2. Configure a password file for the server: https://www.postgresql.org/docs/14/libpq-pgpass.html
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
    export PATH=$PATH:/Library/PostgreSQL/14/bin
    ```

## Usage Guide
After you complete the Setup Guide your local PostgreSQL server will be up and running and will start automatically with your system. Next up you'll want to restore a database dump file which will create the Readup database and populate it with data.

### Restoring Database Dumps
Restore a database dump any time you need to upgrade to a newer version of the Readup database or simply want to revert the Readup database to a clean slate. Any changes that have been made to the database since the last restore will be lost.

**Restoring sample seed data**

Yu can restore a minimal seed database with `restore-sample.ps1`. This is also what the Docker container does on startup when you did not restore a database yet (see `docker-start.sh`).

```
pwsh dev-scripts/restore-sample.ps1 -DbName rrit
```
To learn how to generate new seed data (for example, to test something specific), read the [docs in the seed folder](seed/readme.md).

**Restoring full database dumps**

Note: this section is only relevant if you have access to a full or partial database dump. We don't publicly supply these dumps, they are meant for core developers. If you're not a core developer and want to contribute a PR, you can use the default seed sample data; see below.

Run the following PowerShell script to restore a database dump, supplying the desired name for the database and the dump file. Note the following:
- If there is an existing database with the same name it will be dropped before a new one is created.
- The script cannot proceed if there are active connections to an existing database. If you receive the active connections notice then you may need to stop the `api` server or close any active connections from any other SQL clients you may have running.
- It is normal to receive a warning about a failure to refresh the materialized views. This is an issue with `pg_restore` and the materialized views will be refreshed manually before the script finishes.
<!--end list-->
    pwsh dev-scripts/restore.ps1 -DbName rrit -DumpFile /Users/jeff/Downloads/2021-01-23-dev.tar

When using a Docker db container, you can run the same command with `docker exec`. The default Docker Compose container maps this repository folder into `/db` on the container. Make sure to move your dump to this directory.

    docker exec --user postgres readup_db_1 pwsh /db/dev-scripts/restore.ps1 -DbName rrit -DumpFile /db/2021-01-23-dev.tar

## Subscriptions-related docs (deprecated)

Subscriptions have been disabled in Readup since it became free again. See [the blog post](https://blog.readup.com/2022/05/23/announcing-a-free-and-open-source-readup.html) for context. Much of the related database code, schemas and scripts remained in place however.
### Creating Subscriptions

Creating subscriptions using the Apple and Stripe test servers can be tedious and time-consuming. As an alternative you can use the following SQL scripts to create subscriptions directly in the database, bypassing the payment providers.

Replace the variables (specified using the `-v` arguments) with appropriate values, noting the following:
- Maintain the appropriate double quoting that is required for strings and dates
- The `id` argument can be any string, but you must chose a new unique value for every subscription you create.
- The `user` argument must match an existing user account name.
- The `level` argument must be one of `Budget`, `Reader` or `Super Reader`.
- The `begin` and `end` dates must be formatted as ISO-8601 and are in UTC time. You can create subscriptions in the past and the period can be as long or short as you like, but it should not overlap with any existing period for the same user.
- The `card_brand` argument must be one of `none`, `unknown`, `amex`, `diners`, `discover`, `jcb`, `mastercard`, `unionpay` or `visa`.
- The `card_country` argument must be formatted as ISO 3166-1 alpha-2.
- The `price` argument is specified in USD cents.

Create an Apple subscription:

    psql --dbname=rrit --file=dev-scripts/create-apple-subscription.sql -v id="'1'" -v user="'jeff'" -v level="'Reader'" -v begin="'2021-02-01T00:05:00'" -v end="'2021-03-01T00:05:00'"

Create a standard Stripe subscription:

    psql --dbname=rrit --file=dev-scripts/create-stripe-standard-subscription.sql -v id="'1'" -v user="'jeff'" -v level="'Reader'" -v begin="'2021-02-01T00:05:00'" -v end="'2021-03-01T00:05:00'" -v card_brand="'visa'" -v card_digits="'1234'" -v card_country="'US'" -v card_exp_month=1 -v card_exp_year=2022

Create a Stripe subscription with a custom price:

Note: Due to script limitations two users cannot share the same custom price.

    psql --dbname=rrit --file=dev-scripts/create-stripe-custom-subscription.sql -v id="'1'" -v user="'jeff'" -v price=5000 -v begin="'2021-02-01T00:05:00'" -v end="'2021-03-01T00:05:00'" -v card_brand="'visa'" -v card_digits="'1234'" -v card_country="'US'" -v card_exp_month=1 -v card_exp_year=2022
### Creating Subscription Distributions
After a subscription period ends a subscription period distribution needs to be created in order to "lock in" the distribution calculation for that period. Execute the following SQL command to create subscription distributions for any subscription periods that have ended.

This function will only create a distribution for a subscription period with an `end_date` less than or equal to the current timestamp that does not already have a corresponding distribution. In a production scenario this command will be executed as a scheduled task every few minutes.

    psql --dbname=rrit --command="SELECT * FROM subscriptions.create_distributions_for_lapsed_periods(user_account_id := NULL)"