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

Write-Host 'Dumping the data...'

pg_dump `
    --no-owner `
	--no-tablespaces `
	--no-privileges `
	--no-unlogged-table-data `
	--data-only `
	--disable-triggers `
	--file=seed/sample-data.sql `
	$DbName

# --disable-triggers avoids circular FK constraints in:
# - subscription_payment_method
# - subscription_payment_method_version
# - subscription_period
# - comment
