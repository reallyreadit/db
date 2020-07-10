-- remove duplicate user articles
WITH duplicate_user_article AS (
    SELECT
        user_article.id,
        user_article.article_id,
        user_article.user_account_id,
        user_article.date_created,
        user_article.last_modified,
        user_article.date_completed,
        user_article.words_read
    FROM
        core.user_article
    WHERE
        (
            user_article.article_id,
            user_article.user_account_id
        ) IN (
            SELECT
                user_article.article_id,
                user_article.user_account_id
            FROM
                core.user_article
            GROUP BY
                user_article.article_id,
                user_article.user_account_id
            HAVING
                count(*) > 1
        )
)
DELETE FROM
    core.user_article
WHERE
    user_article.id IN (
        SELECT
            duplicate_user_article.id
        FROM
            duplicate_user_article
        EXCEPT
        (
            SELECT DISTINCT ON (
                    duplicate_user_article.article_id,
                    duplicate_user_article.user_account_id
                )
                duplicate_user_article.id
            FROM
                duplicate_user_article
            ORDER BY
                duplicate_user_article.article_id,
                duplicate_user_article.user_account_id,
                duplicate_user_article.date_completed DESC NULLS LAST,
                duplicate_user_article.words_read DESC,
                duplicate_user_article.last_modified DESC NULLS LAST,
                duplicate_user_article.date_created DESC
        )
    );

-- add unique constraint
ALTER TABLE
    core.user_article
ADD CONSTRAINT
    user_article_unique_article_id_user_account_id
UNIQUE (
    article_id,
    user_account_id
);

-- add author user account assignment table
CREATE TABLE
    core.author_user_account_assignment (
        id bigserial PRIMARY KEY,
        author_id bigint NOT NULL UNIQUE REFERENCES core.author (id),
        user_account_id bigint NOT NULL UNIQUE REFERENCES core.user_account (id),
        date_assigned timestamp NOT NULL
    );

-- update article query to check for author
CREATE OR REPLACE FUNCTION article_api.get_articles(
    user_account_id bigint,
    VARIADIC article_ids bigint[]
)
RETURNS SETOF article_api.article
LANGUAGE sql STABLE
AS $$
	SELECT
		article.id,
		article.title,
		article.slug,
		source.name,
		article.date_published,
		article.section,
		article.description,
		article.aotd_timestamp,
		article_pages.urls[1],
		coalesce(article_authors.names, '{}'),
		coalesce(article_tags.names, '{}'),
		article.word_count::bigint,
		article.comment_count::bigint,
		article.read_count::bigint,
		user_article.date_created,
	    CASE WHEN article_authors.user_is_author
	        THEN 100
	        ELSE coalesce(
               article_api.get_percent_complete(
                  user_article.readable_word_count,
                  user_article.words_read
               ),
               0
            )
		END AS percent_complete,
	    CASE WHEN article_authors.user_is_author
	        THEN TRUE
	        ELSE user_article.date_completed IS NOT NULL
	    END AS is_read,
		star.date_starred,
		article.average_rating_score,
		user_article_rating.score,
	    coalesce(posts.dates, '{}'),
	    article.hot_score,
	    article.rating_count,
	    first_poster.name,
	    article.flair,
	    article.aotd_contender_rank
	FROM
		core.article
		JOIN article_api.article_pages ON
			article_pages.article_id = article.id AND
			article_pages.article_id = ANY (get_articles.article_ids)
		JOIN source ON
		    source.id = article.source_id
		LEFT JOIN (
		    SELECT
		        article_author.article_id,
		        array_agg(author.name) AS names,
		        count(author_user_account_assignment.id) > 0 AS user_is_author
		    FROM
		        core.article_author
		        JOIN core.author ON
		            author.id = article_author.author_id
		        LEFT JOIN author_user_account_assignment ON
		            author_user_account_assignment.author_id = author.id AND
		            author_user_account_assignment.user_account_id = get_articles.user_account_id
		    WHERE
		        article_author.article_id = ANY (get_articles.article_ids)
		    GROUP BY
		        article_author.article_id
        ) AS article_authors ON
			article_authors.article_id = article.id
		LEFT JOIN article_api.article_tags ON
			article_tags.article_id = article.id AND
			article_tags.article_id = ANY (get_articles.article_ids)
		LEFT JOIN core.user_article ON
			user_article.user_account_id = get_articles.user_account_id AND
			user_article.article_id = article.id
		LEFT JOIN core.star ON
			star.user_account_id = get_articles.user_account_id AND
			star.article_id = article.id
		LEFT JOIN article_api.user_article_rating ON
			user_article_rating.user_account_id = get_articles.user_account_id AND
			user_article_rating.article_id = article.id AND
			user_article_rating.article_id = ANY (get_articles.article_ids)
		LEFT JOIN (
			SELECT
				post.article_id,
				array_agg(post.date_created) AS dates
		    FROM
		    	social.post
		    WHERE
		    	post.article_id = ANY (get_articles.article_ids) AND
		        post.user_account_id = get_articles.user_account_id
			GROUP BY
				post.article_id
		) AS posts ON
		    posts.article_id = article.id
		LEFT JOIN core.user_account AS first_poster ON
		    first_poster.id = article.first_poster_id
	ORDER BY
	    array_position(get_articles.article_ids, article.id)
$$;

DROP VIEW article_api.article_authors;