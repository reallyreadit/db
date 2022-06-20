# Copyright (C) 2022 reallyread.it, inc.
#
# This file is part of Readup.
#
# Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
#
# Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License version 3 along with Readup. If not, see <https://www.gnu.org/licenses/>.

param (
	[Parameter(Mandatory = $true)]
	[string] $DbName
)

Write-Host 'Dumping the schema...'

# These pg_dump flags are the ones Jeff historically used when dumping the schema from the
# production AWS RDS server.
pg_dump `
    --no-owner `
	--no-tablespaces `
	--no-privileges `
	--no-unlogged-table-data `
	--section=pre-data `
	--section=post-data $DbName > schema.sql
