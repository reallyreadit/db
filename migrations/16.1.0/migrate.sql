-- author leaderboards
CREATE FUNCTION stats.get_top_author_leaderboard(
    max_rank integer,
    since_date timestamp
)
RETURNS TABLE (
    name text,
    slug text,
    score int,
    rank int
)
LANGUAGE sql
STABLE
AS $$
    WITH ranking AS (
        SELECT
            author.name,
            author.slug,
            core.estimate_reading_time(
                sum(community_read.word_count)
            ) AS score,
            dense_rank() OVER (
                ORDER BY sum(community_read.word_count) DESC
            )::int AS rank
        FROM
            core.user_article
            JOIN community_reads.community_read ON
                community_read.id = user_article.article_id
            JOIN core.article_author ON
                article_author.article_id = user_article.article_id
            JOIN core.author ON
                author.id = article_author.author_id
        WHERE
            CASE WHEN get_top_author_leaderboard.since_date IS NOT NULL
                THEN user_article.date_completed >= get_top_author_leaderboard.since_date
                ELSE user_article.date_completed IS NOT NULL
            END
        GROUP BY
            author.id
    )
    SELECT
        ranking.name,
        ranking.slug,
        ranking.score,
        ranking.rank
    FROM
        ranking
    WHERE
        ranking.rank <= get_top_author_leaderboard.max_rank
    ORDER BY
        ranking.rank,
        ranking.name;
$$;