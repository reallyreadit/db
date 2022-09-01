#!/bin/bash

# Turn on bash's job control
set -m

# Start the main postgres process
# see https://github.com/docker-library/postgres/blob/4e56664f1797ba4cc0f5917b6d794792a5571b45/14/bullseye/Dockerfile
docker-entrypoint.sh postgres &

# Wait on the Postgres server to become available
while !</dev/tcp/db/5432; do sleep 1; done;

# Seed the database with a sample database if it doesn't exist yet
if [ $( su - postgres -c "psql -XtAc \"select count(datname) from pg_database where datname='rrit'\"") = '1' ];
	then
		echo "Database already exists"
	else
		echo "Database does not exist - seeding sample database";
		su - postgres -c "cd /db && pwsh dev-scripts/restore-sample.ps1 -DbName rrit;"
	fi

# Bring the Postgres process back to the foreground
fg %1