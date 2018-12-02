CREATE MATERIALIZED VIEW stats_api.current_streak AS
SELECT
	id,
	name,
	streak
FROM
	user_account
	JOIN LATERAL stats_api.get_current_streak(id) AS streak
		ON user_account.time_zone_id IS NOT NULL
WHERE
	streak > 0;
CREATE UNIQUE INDEX current_streak_id_key ON
	stats_api.current_streak (id);