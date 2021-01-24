param (
	[Parameter(Mandatory = $true)]
	[string] $DbName,
	[Parameter(Mandatory = $true)]
	[string] $DumpFile
)

Write-Host 'Verifying dump file exists...'
if (-not (Test-Path $DumpFile)) {
	Write-Host 'Dump file not found.'
	Exit
}

Write-Host 'Checking for active connections...'
[int]$activeConnections = psql --no-align --tuples-only --command="SELECT count(*) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DbName'"
if ($activeConnections -gt 0) {
	Write-Host 'Close active connections and try again.'
	Exit
}

Write-Host 'Dropping existing database...'
psql --command="DROP DATABASE IF EXISTS $DbName"

Write-Host 'Creating database...'
psql --command="CREATE DATABASE $DbName"
psql --dbname=$DbName --command='ALTER DATABASE rrit SET search_path TO core'
psql --dbname=$DbName --command='DROP SCHEMA public'

Write-Host 'Restoring dump file...'
pg_restore --dbname=$DbName --no-owner $DumpFile

Write-Host 'Refreshing materialized views...'
psql --dbname=$DbName --command='REFRESH MATERIALIZED VIEW stats.current_streak'