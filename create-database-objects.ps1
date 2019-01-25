foreach ($objectPath in (Get-Content ./database-objects)) {
    psql --host=localhost --username=postgres --dbname=rrit --file=$objectPath 
}