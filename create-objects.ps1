param(
    $Instance = $(throw '-Instance is required.')
)

# load db info
. .\db-info.ps1

if ($instances[$Instance] -eq $null) {
    throw 'Invalid value for -Instance.'
}
$hostname = $instances[$Instance].host
$db = $instances[$Instance].db
$user = $instances[$Instance].user

# create ordered objects
echo 'Creating ordered objects...'
foreach ($object in $objects) {
    echo "Creating object: $object..."
    psql -f (Join-Path $schemaDir "$object.sql") -h $hostname $db $user
}

# create unordered objects
echo 'Creating unordered objects...'
foreach ($objectFile in (
    Get-ChildItem $schemaDir -File -Recurse |
    Select-Object -ExpandProperty FullName |
    Resolve-Path -Relative |
    Where-Object {-not $objects.Contains(($_ -replace "^\.\\$schemaDir\\",'' -replace '\\','/' -replace '\.sql$',''))}
)) {
    echo "Creating object: $objectFile..."
    psql -f $objectFile -h $hostname $db $user
}