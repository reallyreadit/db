foreach ($objectPath in (Get-Content .\database-objects)) {
    psql --dbname=rrit --file=$objectPath --host=localhost --username=postgres
}