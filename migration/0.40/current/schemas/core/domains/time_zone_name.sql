CREATE DOMAIN time_zone_name AS text
CHECK (is_time_zone_name(VALUE));