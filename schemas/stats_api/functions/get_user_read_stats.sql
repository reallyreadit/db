CREATE FUNCTION stats_api.get_user_read_stats(
	user_account_id bigint
)
RETURNS TABLE (
	user_account_id bigint,
	user_count bigint,
	read_count bigint,
	read_count_rank bigint
)
LANGUAGE SQL
STABLE
AS $func$
	WITH ranking AS (
		SELECT
			user_account_id,
			(
				SELECT count(*)
				FROM user_account
			) AS user_count,
			count(*) AS read_count,
			dense_rank() OVER (ORDER BY count(*) DESC) AS read_count_rank
		FROM
			user_page
		WHERE
			date_completed IS NOT NULL
		GROUP BY
			user_account_id
	)
	SELECT *
	FROM ranking
	WHERE user_account_id = get_user_read_stats.user_account_id;
$func$;