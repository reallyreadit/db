# reallyread.it db
## Backup
Run `pg_dump` with the following options:

    --format=p --no-owner --section=pre-data --section=post-data --no-privileges --no-tablespaces --no-unlogged-table-data