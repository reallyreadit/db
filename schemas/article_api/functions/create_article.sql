CREATE FUNCTION article_api.create_article(
	title text,
	slug text,
	source_id uuid,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	authors article_api.create_article_author[],
	tags text[]
) RETURNS article
LANGUAGE plpgsql AS $func$
DECLARE
	new_article 		article;
	current_author		article_api.create_article_author;
	current_author_id	uuid;
	current_tag			text;
	current_tag_id		uuid;
BEGIN
	INSERT INTO article (title, slug, source_id, date_published, date_modified, section, description)
		VALUES (title, slug, source_id, date_published, date_modified, section, description)
		RETURNING * INTO new_article;
	FOREACH current_author IN ARRAY authors
	LOOP
		SELECT id INTO current_author_id FROM author WHERE url = current_author.url;
		IF current_author_id IS NULL THEN
			INSERT INTO author (name, url) VALUES (current_author.name, current_author.url)
				RETURNING id INTO current_author_id;
		END IF;
		INSERT INTO article_author (article_id, author_id) VALUES (new_article.id, current_author_id);
	END LOOP;
	FOREACH current_tag IN ARRAY tags
	LOOP
		SELECT id INTO current_tag_id FROM tag WHERE name = current_tag;
		IF current_tag_id IS NULL THEN
			INSERT INTO tag (name) VALUES (current_tag) RETURNING id INTO current_tag_id;
		END IF;
		INSERT INTO article_tag (article_id, tag_id) VALUES (new_article.id, current_tag_id);
	END LOOP;
	RETURN new_article;
END;
$func$