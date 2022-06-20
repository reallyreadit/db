# Copyright (C) 2022 reallyread.it, inc.
#
# This file is part of Readup.
#
# Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
#
# Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License version 3 along with Readup. If not, see <https://www.gnu.org/licenses/>.
# -------------------------------------------------

param (
	[Parameter(Mandatory = $true)]
	[string] $DbName
)

Write-Host 'Dropping existing database...'
psql --command="DROP DATABASE IF EXISTS $DbName WITH (FORCE)"

Write-Host 'Creating database...'
psql --command="CREATE DATABASE $DbName"
psql --dbname=$DbName --command='DROP SCHEMA public'

Write-Host 'Restoring schema...'
# .sql dumps can't be restored with pg_restore
psql --dbname=$DbName -f schema.sql

Write-Host 'Seeding sample data...'
psql --dbname=$DbName --file=/db/seed/sample-data.sql

Write-Host 'Refreshing materialized views...'
# The -f $DumpFile will have already attempted this, but it will have failed because
# the search path had not been set at that point. Retry after setting the search path.
psql --dbname=$DbName --command="ALTER DATABASE $DbName SET search_path TO core"
psql --dbname=$DbName --command='REFRESH MATERIALIZED VIEW stats.current_streak'
