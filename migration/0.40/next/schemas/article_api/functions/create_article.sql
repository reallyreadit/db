CREATE FUNCTION article_api.create_article(
	title text,
	slug text,
	source_id bigint,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	author_names text[],
	author_urls text[],
	tags text[]
) RETURNS bigint
LANGUAGE plpgsql AS $func$
DECLARE
	article_id	 		bigint;
	current_author_url	text;
	current_author_id	bigint;
	current_tag			text;
	current_tag_id		bigint;
BEGIN
	INSERT INTO article (title, slug, source_id, date_published, date_modified, section, description)
		VALUES (title, slug, source_id, date_published, date_modified, section, description)
		RETURNING id INTO article_id;
	FOR i IN 1..coalesce(array_length(author_names, 1), 0) LOOP
		current_author_url := author_urls[i];
		SELECT id INTO current_author_id FROM author WHERE url = current_author_url;
		IF current_author_id IS NULL THEN
			INSERT INTO author (name, url) VALUES (author_names[i], current_author_url)
				RETURNING id INTO current_author_id;
		END IF;
		INSERT INTO article_author (article_id, author_id) VALUES (article_id, current_author_id);
	END LOOP;
	FOREACH current_tag IN ARRAY tags
	LOOP
		SELECT id INTO current_tag_id FROM tag WHERE name = current_tag;
		IF current_tag_id IS NULL THEN
			INSERT INTO tag (name) VALUES (current_tag) RETURNING id INTO current_tag_id;
		END IF;
		INSERT INTO article_tag (article_id, tag_id) VALUES (article_id, current_tag_id);
	END LOOP;
	RETURN article_id;
END;
$func$;