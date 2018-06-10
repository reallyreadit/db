param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.')
)

$database = 'rrit'

# drop api objects
Write-Host 'Dropping api objects...'

Push-Location .\current

$objects = Get-Content .\database-objects

$reverseObjects = [Array]::CreateInstance([object], $objects.Count)
$objects.CopyTo($reverseObjects, 0)
[Array]::Reverse($reverseObjects)
foreach ($object in $reverseObjects) {
    if ($object.Split('\')[1].EndsWith('_api')) {
        Write-Host $object
        & .\drop-database-object.ps1 -Hostname $Hostname -Username $Username -Database $database -Object $object 
    }
}

Pop-Location

# create new core objects
Write-Host 'Creating new core objects...'

Push-Location .\next

psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\functions\is_time_zone_name.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\domains\time_zone_name.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\enums\challenge_response_action.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\functions\generate_local_to_utc_date_series.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\tables\time_zone.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\functions\get_time_zones.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\functions\local_now.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\tables\challenge.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\tables\challenge_award.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=schemas\core\tables\challenge_response.sql

Pop-Location

# migrate core
Write-Host 'Migrating core...'

psql --host=$Hostname --username=$Username --dbname=$database --file=migrate-core.sql

# insert time zones
Write-Host 'Inserting time zones...'

psql --host=$Hostname --username=$Username --dbname=$database --file=insert-time-zones.sql

# create api objects
Write-Host 'Creating api objects...'

Push-Location .\next

foreach ($object in Get-Content .\database-objects) {
    if ($object.Split('\')[1].EndsWith('_api')) {
        psql --host=$Hostname --username=$Username --dbname=$database --file=$object
    }
}

Pop-Location