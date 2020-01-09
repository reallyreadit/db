SELECT
	range.local_timestamp,
    (sum(progress.words_read) / 184::double precision) / 60 AS hours_reading
FROM
	generate_local_timestamp_to_utc_range_series(
		start => '2019-11-01',
		stop => '2019-11-07',
		step => '1 day'::interval,
		time_zone_name => 'America/New_York'
	) AS range
	JOIN user_article_progress AS progress ON (
	    progress.period > '2019-11-01T05:00:00' AND
	    progress.period < '2019-11-08T05:00:00' AND
	    progress.period <@ range.utc_range
	)
GROUP BY
	range.local_timestamp;