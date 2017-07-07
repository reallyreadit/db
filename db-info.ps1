# params
$instances = @{
    localhost = @{
        host = 'localhost'
        db = 'rrit'
        user = 'postgres'
    }
    rds = @{
        host = 'reallyreadit.ch8jfpdyappi.us-east-2.rds.amazonaws.com'
        db = 'rrit'
        user = 'rrit'
    }
}

$schemaDir = 'schemas'

$objects = @(
    'core/functions/utc_now'
    'core/tables/user_account'
    'core/tables/email_confirmation'
    'core/tables/password_reset_request'
    'core/tables/source'
    'core/tables/article'
    'core/tables/author'
    'core/tables/article_author'
    'core/tables/tag'
    'core/tables/article_tag'
    'core/tables/page'
    'core/tables/user_page'
    'core/tables/comment'
	'core/tables/source_rule'
    'article_api/types/create_article_author'
    'article_api/types/user_article'
    'article_api/functions/list_user_articles'
    'article_api/views/user_comment'
    'user_account_api/views/user_account'
)