
The `time-zone.sql` file is dumped with:
```
pg_dump rrit_orig -t core.time_zone --no-owner \
	--no-tablespaces \
	--no-privileges \
	--no-unlogged-table-data \
	--section=data > /db/seed/time-zone.sql
```
Within the db container.

To update the seed data, again within the container:
```bash
# 1. Reset the database to only contain the schema (warning: this will remove data)
pwsh /db/dev-scripts/restore-schema.ps1 -DbName rrit -DumpFile /db/schema.sql
# 2. Run the latest.NET seeder script on rrit, see https://github.com/reallyreadit/db-sample-seeder
# 3. Dump the seed data
pwsh /db/dev-scripts/dump-seed-data.ps1 -DbName rrit
```


