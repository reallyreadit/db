param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.')
)

$database = 'rrit'

# drop api objects
Write-Host 'Dropping api objects...'

Push-Location ./current

$objects = Get-Content ./database-objects

$reverseObjects = [Array]::CreateInstance([object], $objects.Count)
$objects.CopyTo($reverseObjects, 0)
[Array]::Reverse($reverseObjects)
foreach ($object in $reverseObjects) {
    if ($object.Split('/')[1].EndsWith('_api')) {
        Write-Host $object
        & ./drop-database-object.ps1 -Hostname $Hostname -Username $Username -Database $database -Object $object
    }
}

Pop-Location

# migrate core
Write-Host 'Migrating core...'

psql --host=$Hostname --username=$Username --dbname=$database --file=migrate-core.sql

# create api objects
Write-Host 'Creating api objects...'

Push-Location ./next

foreach ($object in Get-Content ./database-objects) {
    if ($object.Split('/')[1].EndsWith('_api')) {
        psql --host=$Hostname --username=$Username --dbname=$database --file=$object
    }
}

Pop-Location