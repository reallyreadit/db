param(
    $Hostname = $(throw '-Hostname is required.'),
    $Username = $(throw '-Username is required.')
)

$database = 'rrit'

# drop article_api objects
Write-Host 'Dropping article_api objects...'

psql --host=$Hostname --username=$Username --dbname=$database --file=drop-article-api-objects.sql

# migrate core
Write-Host 'Migrating core...'

psql --host=$Hostname --username=$Username --dbname=$database --file=migrate-core.sql

# create article_api objects
Write-Host 'Creating article_api objects...'

psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/views/community_read.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/views/article_score.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/score_articles.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/set_aotd.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/list_community_reads.sql
psql --host=$Hostname --username=$Username --dbname=$database --file=../../schemas/article_api/functions/list_user_community_reads.sql

# update scores
Write-Host 'Updating article scores...'
psql --host=$Hostname --username=$Username --dbname=$database --command='SELECT article_api.score_articles();'