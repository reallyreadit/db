DROP FUNCTION article_api.create_article(
	title text,
	slug text,
	source_id uuid,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	authors article_api.create_article_author[],
	tags text[]
);
DROP FUNCTION bulk_mailing_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipients bulk_mailing_api.create_bulk_mailing_recipient[]
);
DROP TYPE article_api.create_article_author;
DROP TYPE bulk_mailing_api.create_bulk_mailing_recipient;
CREATE FUNCTION article_api.create_article(
	title text,
	slug text,
	source_id uuid,
	date_published timestamp,
	date_modified timestamp,
	section text,
	description text,
	author_names text[],
	author_urls text[],
	tags text[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	article_id	 		uuid;
	current_author_url	text;
	current_author_id	uuid;
	current_tag			text;
	current_tag_id		uuid;
BEGIN
	INSERT INTO article (title, slug, source_id, date_published, date_modified, section, description)
		VALUES (title, slug, source_id, date_published, date_modified, section, description)
		RETURNING id INTO article_id;
	FOR i IN 1..array_length(author_names, 1) LOOP
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
CREATE FUNCTION bulk_mailing_api.create_bulk_mailing(
	subject text,
	body text,
	list text,
	user_account_id uuid,
	recipient_ids uuid[],
	recipient_results boolean[]
) RETURNS uuid
LANGUAGE plpgsql AS $func$
DECLARE
	bulk_mailing_id uuid;
BEGIN
	INSERT INTO bulk_mailing (subject, body, list, user_account_id)
		VALUES (subject, body, list, user_account_id)
		RETURNING id INTO bulk_mailing_id;
	FOR i IN 1..array_length(recipient_ids, 1) LOOP
		INSERT INTO bulk_mailing_recipient (bulk_mailing_id, user_account_id, is_successful)
			VALUES (bulk_mailing_id, recipient_ids[i], recipient_results[i]);
	END LOOP;
	RETURN bulk_mailing_id;
END;
$func$;