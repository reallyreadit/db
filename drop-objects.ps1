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

# drop unordered functions
foreach ($funcFile in (
    Get-ChildItem $funcDir |
    Select-Object -ExpandProperty Name |
    Where-Object {-not $objects.Contains(($_ -replace '\.sql$',''))}
)) {
    echo "Dropping function: $($funcFile -replace '\.sql$','')..."
    $decl = [System.Text.RegularExpressions.Regex]::Match(
        (Get-Content (Join-Path $funcDir $funcFile)),
        '^CREATE\s+FUNCTION\s+([^)]+\))'
    )
    $decl = $decl.Groups[1].Value -replace '\s+DEFAULT\s+[^\s,)]+','';
    psql -c "DROP FUNCTION IF EXISTS $decl" -h $hostname $db $user
}

# drop ordered objects
echo 'Dropping objects...'
$reverseKeys = [Array]::CreateInstance([string], $objects.Count)
$objects.Keys.CopyTo($reverseKeys, 0)
[Array]::Reverse($reverseKeys)
foreach ($name in $reverseKeys) {
    switch ($objects[$name]) {
        'table' {
            echo "Dropping table: $name..."
            psql -c "DROP TABLE IF EXISTS $name" -h $hostname $db $user
        }
        'function' {
            echo "Dropping function: $name..."
            $decl = [System.Text.RegularExpressions.Regex]::Match(
                (Get-Content (Join-Path $funcDir "$name.sql")),
                '^CREATE\s+FUNCTION\s+([^)]+\))'
            )
            $decl = $decl.Groups[1].Value -replace '\s+DEFAULT\s+[^\s,)]+','';
            psql -c "DROP FUNCTION IF EXISTS $decl" -h $hostname $db $user
        }
        'view' {
            echo "Dropping view: $name..."
            $decl = [System.Text.RegularExpressions.Regex]::Match(
                (Get-Content (Join-Path $viewDir "$name.sql")),
                '^CREATE\s+VIEW\s+(\S+)'
            )
            psql -c "DROP VIEW IF EXISTS $($decl.Groups[1].Value)" -h $hostname $db $user
        }
        'type' {
            echo "Dropping type: $name..."
            psql -c "DROP TYPE IF EXISTS $name" -h $hostname $db $user
        }
    }
}