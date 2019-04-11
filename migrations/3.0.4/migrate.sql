CREATE OR REPLACE VIEW community_reads.listed_community_read
AS (
	SELECT
		id,
    	hot_score,
    	top_score,
    	comment_count,
    	read_count,
    	average_rating_score
	FROM community_reads.community_read
  	WHERE
  		aotd_timestamp IS DISTINCT FROM (
  			SELECT max(aotd_timestamp)
        	FROM article
  		)
);