param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.'),
    $Database = $(throw '-Database is required.'),
    $Object = $(throw '-Object is required.')
)

# get object info
$objectParts = $Object.Split('\')
$schema = $objectParts[1]
$type = $objectParts[2].TrimEnd('s')
$name = $objectParts[3].Substring(0, $objectParts[3].IndexOf('.sql'))

# log
Write-Host "Dropping $($type): $name...";

# create and execute command
$command
switch ($type) {
    'domain' {
        $command = "DROP DOMAIN IF EXISTS $schema.$name"
    }
    { 'enum','type' -contains $type } {
        $command = "DROP TYPE IF EXISTS $schema.$name"
    }
    'function' {
        $decl = [System.Text.RegularExpressions.Regex]::Match(
            (Get-Content $Object),
            '^CREATE\s+FUNCTION\s+([^)]+\))'
        )
        $decl = $decl.Groups[1].Value -replace '\s+DEFAULT\s+[^\s,)]+',''
        $command = "DROP FUNCTION IF EXISTS $decl"
    }
	'materialized-view' {
        $decl = [System.Text.RegularExpressions.Regex]::Match(
            (Get-Content $Object),
            '^CREATE\s+MATERIALIZED\s+VIEW\s+(\S+)'
        )
        $command = "DROP MATERIALIZED VIEW IF EXISTS $($decl.Groups[1].Value)"
    }
    'table' {
        $command = "DROP TABLE IF EXISTS $schema.$name"
    }
    'view' {
        $decl = [System.Text.RegularExpressions.Regex]::Match(
            (Get-Content $Object),
            '^CREATE\s+VIEW\s+(\S+)'
        )
        $command = "DROP VIEW IF EXISTS $($decl.Groups[1].Value)"
    }
}
psql --host=$Hostname --username=$Username --dbname=$database --command=$command