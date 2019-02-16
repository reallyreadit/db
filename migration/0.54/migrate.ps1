param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.')
)

$database = 'rrit'

Write-Host 'Creating new objects...'
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/core/domains/rating_score.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/core/tables/rating.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/rate_article.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/views/user_article_rating.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/views/average_article_rating.sql

Write-Host 'Migrating existing objects...'
psql --host=$Hostname --username=$Username --dbname=$database --file=./migrate.sql

Write-Host 'Replacing existing objects...'
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/get_articles.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/get_user_articles.sql