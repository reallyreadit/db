CREATE TABLE core.article_issue_report (
    id bigserial PRIMARY KEY,
    date_created timestamp NOT NULL DEFAULT core.utc_now(),
    article_id bigint NOT NULL REFERENCES core.article (id),
    user_account_id bigint NOT NULL REFERENCES core.user_account (id),
    issue text NOT NULL,
    analytics jsonb
);
CREATE FUNCTION analytics.log_article_issue_report(
    article_id bigint,
    user_account_id bigint,
    issue text,
    analytics text
)
RETURNS void
LANGUAGE sql
AS $$
    INSERT INTO
        core.article_issue_report (
            article_id,
            user_account_id,
            issue,
            analytics
        )
    VALUES (
        log_article_issue_report.article_id,
        log_article_issue_report.user_account_id,
        log_article_issue_report.issue,
        log_article_issue_report.analytics::jsonb
    );
$$;
CREATE FUNCTION analytics.get_article_issue_reports(
    start_date timestamp,
    end_date timestamp
)
RETURNS TABLE (
    date_created timestamp,
    article_url text,
    article_aotd_contender_rank int,
    user_name text,
    issue text,
    client_type text
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        report.date_created,
        page.url,
        article.aotd_contender_rank,
        user_account.name::text,
        report.issue,
        report.analytics->'client'->>'type'
    FROM
        core.article_issue_report AS report
        JOIN core.article ON
            article.id = report.article_id
        LEFT JOIN core.page ON
            page.article_id = report.article_id
        JOIN core.user_account ON
            user_account.id = report.user_account_id
    WHERE
        report.date_created <@ tsrange(get_article_issue_reports.start_date, get_article_issue_reports.end_date)
    ORDER BY
        report.date_created DESC;
$$;