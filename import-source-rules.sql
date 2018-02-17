INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('avc.com', '^/\d{4}/\d{2}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('bimmerfest.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('bimmerfest.com', '^/news/.+', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('blackhatworld.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('centerforhealthandhealingnj.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('coriginventures.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('crucial.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('dartmouthcoach.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('disposalnj.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('dumpstersoceancountynj.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('dumpstersondemand.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ellevest.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('flickr.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('flipsnack.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('flipsnack.com', '^/blog/.+', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('freepik.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('freepik.com', '^/blog', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('developers.google.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('docs.google.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('grkfresh.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('hairlossrevolution.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('iammikewilliams.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('imgur.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('blog.imgur.com', '^/\d{4}/\d{2}/\d{2}/.+', 1, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('internshala.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('blog.internshala.com', '^/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ismile-dds.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ismile-dds.com', '^/blog', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('jenniearle.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('justetf.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('knowyourmeme.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('mediaite.com', '^/online/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('nookipedia.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('nytimes.com', '^/section/[^/]+$', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('pastebin.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('producthunt.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('psychologytoday.com', '^/blog/[^/]+/\d{6}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('rawstory.com', '^/\d{4}/\d{2}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('shelaf.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('shelaf.com', '^/\d{4}/\d{2}/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('socialcapital.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('spotifyjobs.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('stacieoverby.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('sungjwoo.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('sungjwoo.com', '^/\d{4}/\d{2}/\d{2}/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('thoughtchalk.com', '^/\d{4}/\d{2}/\d{2}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('twitter.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('blog.twitter.com', '^/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ventureasheville.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ventureasheville.com', '^/blog', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('motherboard.vice.com', '^/en_us/article/[^/]+/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('vimeo.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('vimeo.com', '^/blog', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('vinifritti.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('weather.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('weather.com', '^/news/news/.+', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('webmd.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('webmd.com', '^/[^/]+/news/\d{6}/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('westlakedermatology.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('westlakedermatology.com', '^/blog/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('wikia.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('wikiwand.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('wunderground.com', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('wunderground.com', '^/(cat6|blog|news)/.+', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('lecker.de', '^/weihnachten/adventskalender', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('netzwelt.de', '^/$', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('netzwelt.de', '^/adventskalender', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('anea.es', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('moviesgolds.net', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('hosted.ap.org', '^/dynamic/stories/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('ashasexualhealth.org', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('briefmenow.org', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('craigslist.org', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('blog.craigslist.org', '^/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('dmv.org', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('harpers.org', '^/(archive|blog)/\d{4}/\d{2}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('mysteriousuniverse.org', '^/\d{4}/\d{2}/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('theamericanscholar.org', '^/.+', 0, 'read');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('theamericanscholar.org', '^/(the-daily-scholar|issues|past-issues|dept|podcast|subscribe|about-us|contact-us|support|advertising)(/|$)', 1, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('untf.unwomen.org', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('untf.unwomen.org', '^/en/news-and-events/stories/\d{4}/\d{2}/', 1, 'default');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('todaypk.se', '^/', 0, 'ignore');
INSERT INTO core.source_rule (hostname, path, priority, action) VALUES ('telegraph.co.uk', '^/[^/]+/$', 0, 'ignore');