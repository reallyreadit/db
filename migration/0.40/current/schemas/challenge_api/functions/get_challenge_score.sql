CREATE FUNCTION challenge_api.get_challenge_score(
	challenge_id bigint,
	user_account_id bigint
)
RETURNS TABLE (
	day int,
	level int
)
LANGUAGE plpgsql
STABLE
AS $func$
<<locals>>
DECLARE
	enrollment_date timestamp;
	time_zone_name text;
BEGIN
	-- check if the challenge is active
	IF get_challenge_score.challenge_id IN (
		SELECT c.id
		FROM challenge_api.get_active_challenges() c
	)
	THEN
		-- check if the user won the challenge
		IF get_challenge_score.user_account_id IN (
			SELECT ca.user_account_id
			FROM challenge_award ca
			WHERE ca.challenge_id = get_challenge_score.challenge_id
		) THEN
			RETURN QUERY SELECT 0, 10;
			RETURN;
		END IF;
		-- check for an enrollment date
		SELECT
			CASE WHEN cr.action = 'enroll'
				THEN cr.date
				ELSE NULL
			END,
			cr.time_zone_name
			INTO
				locals.enrollment_date,
				locals.time_zone_name
		FROM challenge_api.challenge_response cr
		WHERE
			cr.challenge_id = get_challenge_score.challenge_id AND
			cr.user_account_id = get_challenge_score.user_account_id
		ORDER BY cr.date DESC
		LIMIT 1;
		IF locals.enrollment_date IS NOT NULL THEN
			RETURN QUERY
			WITH qualifying_read AS (
				SELECT
					read.date_completed
				FROM
					article_api.user_article_read read
					JOIN article_api.article_pages pages ON read.article_id = pages.article_id
				WHERE
					read.user_account_id = get_challenge_score.user_account_id AND
					read.date_completed >= locals.enrollment_date AND
					pages.word_count >= (184 * 5)
			),
			daily_read_count AS (
				SELECT
					series.local_day,
					count(read.*) AS read_count
				FROM
					generate_local_to_utc_date_series(
						cast(local_now(locals.time_zone_name) - '9 days'::interval AS date),
						cast(local_now(locals.time_zone_name) AS date),
						1,
						locals.time_zone_name
					) AS series
					LEFT JOIN qualifying_read read ON series.utc_range @> read.date_completed
				GROUP BY series.local_day
			),
			qualified_daily_read_count AS (
				SELECT
					drc.local_day,
					drc.read_count,
					CASE WHEN
						drc.local_day = first_value(drc.local_day) OVER local_day_desc AND
						lead(drc.read_count) OVER local_day_desc > 0
						THEN TRUE
						ELSE drc.read_count > 0
					END AS is_qualifying_day
				FROM daily_read_count drc
				WINDOW local_day_desc AS (ORDER BY drc.local_day DESC)
			),
			steaked_daily_read_count AS (
				SELECT
					qdrc.local_day,
					qdrc.read_count,
					sum(
						CASE WHEN qdrc.is_qualifying_day
							THEN 0
							ELSE 1
						END
					) OVER (ORDER BY qdrc.local_day DESC) = 0 AS is_streak_day
				FROM qualified_daily_read_count qdrc
			)
			SELECT
				cast(count(*) AS int),
				cast(count(*) FILTER (WHERE sdrc.read_count > 0) AS int)
			FROM steaked_daily_read_count sdrc
			WHERE sdrc.is_streak_day;
			RETURN;
		END IF;
	END IF;
	RETURN QUERY SELECT 0, 0;
END;
$func$;