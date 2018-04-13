param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.')
)

$database = 'rrit'

# drop everything except the core schema
Write-Host 'Dropping everything except the core schema...'

Push-Location .\current

$objects = Get-Content .\database-objects

$reverseObjects = [Array]::CreateInstance([object], $objects.Count)
$objects.CopyTo($reverseObjects, 0)
[Array]::Reverse($reverseObjects)
foreach ($object in $reverseObjects) {
    if ($object.Split('\')[1] -ne 'core') {
        Write-Host $object
        & .\drop-database-object.ps1 -Hostname $Hostname -Username $Username -Database $database -Object $object 
    }
}

Pop-Location

# generate new ids
Write-Host 'Generating new ids...'

psql --host=$Hostname --username=$Username --dbname=$database --command='CREATE SCHEMA id_migration;'

Push-Location .\next

foreach ($object in Get-Content .\database-objects) {
    if ($object.Split('\')[1] -eq 'id_migration') {
        psql --host=$Hostname --username=$Username --dbname=$database --file=$object
    }
}

Pop-Location

# drop foreign keys
Write-Host 'Dropping foreign keys...'

psql --host=$Hostname --username=$Username --dbname=$database --file=drop-foreign-keys.sql

# migrate primary keys
Write-Host 'Migrating primary keys...'

psql --host=$Hostname --username=$Username --dbname=$database --file=migrate-primary-keys.sql

# create foreign keys
Write-Host 'Creating foreign keys...'

psql --host=$Hostname --username=$Username --dbname=$database --file=create-foreign-keys.sql

# drop pgcrypto
Write-Host 'Dropping pgcrypto...'

psql --host=$Hostname --username=$Username --dbname=$database --command='DROP EXTENSION pgcrypto;'
psql --host=$Hostname --username=$Username --dbname=$database --command='DROP SCHEMA pgcrypto;'

# create everything except the core and id_migration schemas
Write-Host 'Creating everything except the core and id_migration schemas...'

Push-Location .\next

foreach ($object in Get-Content .\database-objects) {
    if ('core','id_migration' -notcontains $object.Split('\')[1]) {
        psql --host=$Hostname --username=$Username --dbname=$database --file=$object
    }
}

Pop-Location