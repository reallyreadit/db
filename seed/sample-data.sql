--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3 (Debian 14.3-1.pgdg110+1)
-- Dumped by pg_dump version 14.3 (Debian 14.3-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: source; Type: TABLE DATA; Schema: core; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE core.source DISABLE TRIGGER ALL;

COPY core.source (id, name, url, hostname, slug, twitter_handle, twitter_handle_assignment, hostname_priority) FROM stdin;
1	Best website ever	https://website.com	website.com	best-website-ever	\N	none	0
\.


ALTER TABLE core.source ENABLE TRIGGER ALL;

--
-- Data for Name: article; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.article DISABLE TRIGGER ALL;

COPY core.article (id, title, slug, source_id, date_published, date_modified, section, description, aotd_timestamp, hot_score, top_score, comment_count, read_count, average_rating_score, word_count, silent_post_count, rating_count, first_poster_id, flair, aotd_contender_rank, community_read_timestamp, latest_read_timestamp, latest_post_timestamp) FROM stdin;
1	The White Swamphen Revealed	best-website-ever_the-white-swamphen-revealed	1	2022-06-19 14:19:56.611656	\N		The white swamphen (Porphyrio albus) was a rail found on Lord Howe Island, east of the Australian mainland. All contemporary accounts and illustrations were produced between 1788 and 1790, when the bird was first encountered by British ship crews.	2022-06-20 14:19:56.703522	1714	5	1	1	\N	2204	0	0	1	\N	1	2022-06-20 14:19:56.665869	2022-06-20 14:19:56.660557	2022-06-20 14:19:56.665869
2	The War On The Pronunciation of GIF	best-website-ever_the-war-on-the-pronunciation-of-gif	1	2022-06-17 14:19:56.673016	\N		The pronunciation of GIF has been disputed since the 1990s. GIF, an acronym for the Graphics Interchange Format, is popularly pronounced in English as a one-syllable word.	2022-06-20 14:19:56.691724	1714	5	1	1	\N	2144	0	0	1	\N	0	2022-06-20 14:19:56.680401	2022-06-20 14:19:56.678878	2022-06-20 14:19:56.680401
3	The Story Behind The Song	best-website-ever_the-story-behind-the-song	1	2022-06-06 14:19:56.692974	\N		"I've Just Seen a Face" is a Beatles song written and sung by Paul McCartney (pictured), first released on the album Help! in August 1965. A cheerful ballad of love at first sight, it may have been inspired by McCartney's relationship with actress Jane Asher.	\N	1286	3	1	1	\N	1515	0	0	1	\N	2	2022-06-20 14:19:56.699954	2022-06-20 14:19:56.698477	2022-06-20 14:19:56.699954
\.


ALTER TABLE core.article ENABLE TRIGGER ALL;

--
-- Data for Name: author; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.author DISABLE TRIGGER ALL;

COPY core.author (id, name, url, twitter_handle, twitter_handle_assignment, slug, email_address, contact_status) FROM stdin;
1	Mega Writer	https://website.com/mega-writer	\N	none	mega-writer	\N	none
\.


ALTER TABLE core.author ENABLE TRIGGER ALL;

--
-- Data for Name: time_zone; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.time_zone DISABLE TRIGGER ALL;

COPY core.time_zone (id, name, display_name, territory, base_utc_offset) FROM stdin;
1	Etc/GMT+12	(UTC-12:00) International Date Line West	001	-12:00:00
2	Etc/GMT+12	(UTC-12:00) International Date Line West	ZZ	-12:00:00
3	Etc/GMT+11	(UTC-11:00) Coordinated Universal Time-11	001	-11:00:00
4	Pacific/Pago_Pago	(UTC-11:00) Coordinated Universal Time-11	AS	-11:00:00
5	Pacific/Niue	(UTC-11:00) Coordinated Universal Time-11	NU	-11:00:00
6	Pacific/Midway	(UTC-11:00) Coordinated Universal Time-11	UM	-11:00:00
7	Etc/GMT+11	(UTC-11:00) Coordinated Universal Time-11	ZZ	-11:00:00
8	America/Adak	(UTC-10:00) Aleutian Islands	001	-10:00:00
9	America/Adak	(UTC-10:00) Aleutian Islands	US	-10:00:00
10	Pacific/Honolulu	(UTC-10:00) Hawaii	001	-10:00:00
11	Pacific/Rarotonga	(UTC-10:00) Hawaii	CK	-10:00:00
12	Pacific/Tahiti	(UTC-10:00) Hawaii	PF	-10:00:00
13	Pacific/Johnston	(UTC-10:00) Hawaii	UM	-10:00:00
14	Pacific/Honolulu	(UTC-10:00) Hawaii	US	-10:00:00
15	Etc/GMT+10	(UTC-10:00) Hawaii	ZZ	-10:00:00
16	Pacific/Marquesas	(UTC-09:30) Marquesas Islands	001	-09:30:00
17	Pacific/Marquesas	(UTC-09:30) Marquesas Islands	PF	-09:30:00
18	America/Anchorage	(UTC-09:00) Alaska	001	-09:00:00
19	America/Anchorage	(UTC-09:00) Alaska	US	-09:00:00
20	America/Juneau	(UTC-09:00) Alaska	US	-09:00:00
21	America/Metlakatla	(UTC-09:00) Alaska	US	-09:00:00
22	America/Nome	(UTC-09:00) Alaska	US	-09:00:00
23	America/Sitka	(UTC-09:00) Alaska	US	-09:00:00
24	America/Yakutat	(UTC-09:00) Alaska	US	-09:00:00
25	Etc/GMT+9	(UTC-09:00) Coordinated Universal Time-09	001	-09:00:00
26	Pacific/Gambier	(UTC-09:00) Coordinated Universal Time-09	PF	-09:00:00
27	Etc/GMT+9	(UTC-09:00) Coordinated Universal Time-09	ZZ	-09:00:00
28	America/Tijuana	(UTC-08:00) Baja California	001	-08:00:00
29	America/Santa_Isabel	(UTC-08:00) Baja California	MX	-08:00:00
30	America/Tijuana	(UTC-08:00) Baja California	MX	-08:00:00
31	Etc/GMT+8	(UTC-08:00) Coordinated Universal Time-08	001	-08:00:00
32	Pacific/Pitcairn	(UTC-08:00) Coordinated Universal Time-08	PN	-08:00:00
33	Etc/GMT+8	(UTC-08:00) Coordinated Universal Time-08	ZZ	-08:00:00
34	America/Los_Angeles	(UTC-08:00) Pacific Time (US & Canada)	001	-08:00:00
35	America/Dawson	(UTC-08:00) Pacific Time (US & Canada)	CA	-08:00:00
36	America/Vancouver	(UTC-08:00) Pacific Time (US & Canada)	CA	-08:00:00
37	America/Whitehorse	(UTC-08:00) Pacific Time (US & Canada)	CA	-08:00:00
38	America/Los_Angeles	(UTC-08:00) Pacific Time (US & Canada)	US	-08:00:00
39	PST8PDT	(UTC-08:00) Pacific Time (US & Canada)	ZZ	-08:00:00
40	America/Phoenix	(UTC-07:00) Arizona	001	-07:00:00
41	America/Creston	(UTC-07:00) Arizona	CA	-07:00:00
42	America/Dawson_Creek	(UTC-07:00) Arizona	CA	-07:00:00
43	America/Fort_Nelson	(UTC-07:00) Arizona	CA	-07:00:00
44	America/Hermosillo	(UTC-07:00) Arizona	MX	-07:00:00
45	America/Phoenix	(UTC-07:00) Arizona	US	-07:00:00
46	Etc/GMT+7	(UTC-07:00) Arizona	ZZ	-07:00:00
47	America/Chihuahua	(UTC-07:00) Chihuahua, La Paz, Mazatlan	001	-07:00:00
48	America/Chihuahua	(UTC-07:00) Chihuahua, La Paz, Mazatlan	MX	-07:00:00
49	America/Mazatlan	(UTC-07:00) Chihuahua, La Paz, Mazatlan	MX	-07:00:00
50	America/Denver	(UTC-07:00) Mountain Time (US & Canada)	001	-07:00:00
51	America/Cambridge_Bay	(UTC-07:00) Mountain Time (US & Canada)	CA	-07:00:00
52	America/Edmonton	(UTC-07:00) Mountain Time (US & Canada)	CA	-07:00:00
53	America/Inuvik	(UTC-07:00) Mountain Time (US & Canada)	CA	-07:00:00
54	America/Yellowknife	(UTC-07:00) Mountain Time (US & Canada)	CA	-07:00:00
55	America/Ojinaga	(UTC-07:00) Mountain Time (US & Canada)	MX	-07:00:00
56	America/Boise	(UTC-07:00) Mountain Time (US & Canada)	US	-07:00:00
57	America/Denver	(UTC-07:00) Mountain Time (US & Canada)	US	-07:00:00
58	MST7MDT	(UTC-07:00) Mountain Time (US & Canada)	ZZ	-07:00:00
59	America/Guatemala	(UTC-06:00) Central America	001	-06:00:00
60	America/Belize	(UTC-06:00) Central America	BZ	-06:00:00
61	America/Costa_Rica	(UTC-06:00) Central America	CR	-06:00:00
62	Pacific/Galapagos	(UTC-06:00) Central America	EC	-06:00:00
63	America/Guatemala	(UTC-06:00) Central America	GT	-06:00:00
64	America/Tegucigalpa	(UTC-06:00) Central America	HN	-06:00:00
65	America/Managua	(UTC-06:00) Central America	NI	-06:00:00
66	America/El_Salvador	(UTC-06:00) Central America	SV	-06:00:00
67	Etc/GMT+6	(UTC-06:00) Central America	ZZ	-06:00:00
68	America/Chicago	(UTC-06:00) Central Time (US & Canada)	001	-06:00:00
69	America/Rainy_River	(UTC-06:00) Central Time (US & Canada)	CA	-06:00:00
70	America/Rankin_Inlet	(UTC-06:00) Central Time (US & Canada)	CA	-06:00:00
71	America/Resolute	(UTC-06:00) Central Time (US & Canada)	CA	-06:00:00
72	America/Winnipeg	(UTC-06:00) Central Time (US & Canada)	CA	-06:00:00
73	America/Matamoros	(UTC-06:00) Central Time (US & Canada)	MX	-06:00:00
74	America/Chicago	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
75	America/Indiana/Knox	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
76	America/Indiana/Tell_City	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
77	America/Menominee	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
78	America/North_Dakota/Beulah	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
79	America/North_Dakota/Center	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
80	America/North_Dakota/New_Salem	(UTC-06:00) Central Time (US & Canada)	US	-06:00:00
81	CST6CDT	(UTC-06:00) Central Time (US & Canada)	ZZ	-06:00:00
82	Pacific/Easter	(UTC-06:00) Easter Island	001	-06:00:00
83	Pacific/Easter	(UTC-06:00) Easter Island	CL	-06:00:00
84	America/Mexico_City	(UTC-06:00) Guadalajara, Mexico City, Monterrey	001	-06:00:00
85	America/Bahia_Banderas	(UTC-06:00) Guadalajara, Mexico City, Monterrey	MX	-06:00:00
86	America/Merida	(UTC-06:00) Guadalajara, Mexico City, Monterrey	MX	-06:00:00
87	America/Mexico_City	(UTC-06:00) Guadalajara, Mexico City, Monterrey	MX	-06:00:00
88	America/Monterrey	(UTC-06:00) Guadalajara, Mexico City, Monterrey	MX	-06:00:00
89	America/Regina	(UTC-06:00) Saskatchewan	001	-06:00:00
90	America/Regina	(UTC-06:00) Saskatchewan	CA	-06:00:00
91	America/Swift_Current	(UTC-06:00) Saskatchewan	CA	-06:00:00
92	America/Bogota	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	001	-05:00:00
93	America/Eirunepe	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	BR	-05:00:00
94	America/Rio_Branco	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	BR	-05:00:00
95	America/Coral_Harbour	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	CA	-05:00:00
96	America/Bogota	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	CO	-05:00:00
97	America/Guayaquil	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	EC	-05:00:00
98	America/Jamaica	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	JM	-05:00:00
99	America/Cayman	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	KY	-05:00:00
100	America/Panama	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	PA	-05:00:00
101	America/Lima	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	PE	-05:00:00
102	Etc/GMT+5	(UTC-05:00) Bogota, Lima, Quito, Rio Branco	ZZ	-05:00:00
103	America/Cancun	(UTC-05:00) Chetumal	001	-05:00:00
104	America/Cancun	(UTC-05:00) Chetumal	MX	-05:00:00
105	America/New_York	(UTC-05:00) Eastern Time (US & Canada)	001	-05:00:00
106	America/Nassau	(UTC-05:00) Eastern Time (US & Canada)	BS	-05:00:00
107	America/Iqaluit	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
108	America/Montreal	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
109	America/Nipigon	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
110	America/Pangnirtung	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
111	America/Thunder_Bay	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
112	America/Toronto	(UTC-05:00) Eastern Time (US & Canada)	CA	-05:00:00
113	America/Detroit	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
114	America/Indiana/Petersburg	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
115	America/Indiana/Vincennes	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
116	America/Indiana/Winamac	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
117	America/Kentucky/Monticello	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
118	America/Louisville	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
119	America/New_York	(UTC-05:00) Eastern Time (US & Canada)	US	-05:00:00
120	EST5EDT	(UTC-05:00) Eastern Time (US & Canada)	ZZ	-05:00:00
121	America/Port-au-Prince	(UTC-05:00) Haiti	001	-05:00:00
122	America/Port-au-Prince	(UTC-05:00) Haiti	HT	-05:00:00
123	America/Havana	(UTC-05:00) Havana	001	-05:00:00
124	America/Havana	(UTC-05:00) Havana	CU	-05:00:00
125	America/Indianapolis	(UTC-05:00) Indiana (East)	001	-05:00:00
126	America/Indiana/Marengo	(UTC-05:00) Indiana (East)	US	-05:00:00
127	America/Indiana/Vevay	(UTC-05:00) Indiana (East)	US	-05:00:00
128	America/Indianapolis	(UTC-05:00) Indiana (East)	US	-05:00:00
129	America/Grand_Turk	(UTC-05:00) Turks and Caicos	001	-05:00:00
130	America/Grand_Turk	(UTC-05:00) Turks and Caicos	TC	-05:00:00
131	America/Asuncion	(UTC-04:00) Asuncion	001	-04:00:00
132	America/Asuncion	(UTC-04:00) Asuncion	PY	-04:00:00
133	America/Halifax	(UTC-04:00) Atlantic Time (Canada)	001	-04:00:00
134	Atlantic/Bermuda	(UTC-04:00) Atlantic Time (Canada)	BM	-04:00:00
135	America/Glace_Bay	(UTC-04:00) Atlantic Time (Canada)	CA	-04:00:00
136	America/Goose_Bay	(UTC-04:00) Atlantic Time (Canada)	CA	-04:00:00
137	America/Halifax	(UTC-04:00) Atlantic Time (Canada)	CA	-04:00:00
138	America/Moncton	(UTC-04:00) Atlantic Time (Canada)	CA	-04:00:00
139	America/Thule	(UTC-04:00) Atlantic Time (Canada)	GL	-04:00:00
140	America/Caracas	(UTC-04:00) Caracas	001	-04:00:00
141	America/Caracas	(UTC-04:00) Caracas	VE	-04:00:00
142	America/Cuiaba	(UTC-04:00) Cuiaba	001	-04:00:00
143	America/Campo_Grande	(UTC-04:00) Cuiaba	BR	-04:00:00
144	America/Cuiaba	(UTC-04:00) Cuiaba	BR	-04:00:00
145	America/La_Paz	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	001	-04:00:00
146	America/Antigua	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	AG	-04:00:00
147	America/Anguilla	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	AI	-04:00:00
148	America/Aruba	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	AW	-04:00:00
364	Asia/Baghdad	(UTC+03:00) Baghdad	IQ	03:00:00
149	America/Barbados	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BB	-04:00:00
150	America/St_Barthelemy	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BL	-04:00:00
151	America/La_Paz	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BO	-04:00:00
152	America/Kralendijk	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BQ	-04:00:00
153	America/Boa_Vista	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BR	-04:00:00
154	America/Manaus	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BR	-04:00:00
155	America/Porto_Velho	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	BR	-04:00:00
156	America/Blanc-Sablon	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	CA	-04:00:00
157	America/Curacao	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	CW	-04:00:00
158	America/Dominica	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	DM	-04:00:00
159	America/Santo_Domingo	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	DO	-04:00:00
160	America/Grenada	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	GD	-04:00:00
161	America/Guadeloupe	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	GP	-04:00:00
162	America/Guyana	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	GY	-04:00:00
163	America/St_Kitts	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	KN	-04:00:00
164	America/St_Lucia	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	LC	-04:00:00
165	America/Marigot	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	MF	-04:00:00
166	America/Martinique	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	MQ	-04:00:00
167	America/Montserrat	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	MS	-04:00:00
168	America/Puerto_Rico	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	PR	-04:00:00
169	America/Lower_Princes	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	SX	-04:00:00
170	America/Port_of_Spain	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	TT	-04:00:00
171	America/St_Vincent	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	VC	-04:00:00
172	America/Tortola	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	VG	-04:00:00
173	America/St_Thomas	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	VI	-04:00:00
174	Etc/GMT+4	(UTC-04:00) Georgetown, La Paz, Manaus, San Juan	ZZ	-04:00:00
175	America/Santiago	(UTC-04:00) Santiago	001	-04:00:00
176	America/Santiago	(UTC-04:00) Santiago	CL	-04:00:00
177	America/St_Johns	(UTC-03:30) Newfoundland	001	-03:30:00
178	America/St_Johns	(UTC-03:30) Newfoundland	CA	-03:30:00
179	America/Araguaina	(UTC-03:00) Araguaina	001	-03:00:00
180	America/Araguaina	(UTC-03:00) Araguaina	BR	-03:00:00
181	America/Sao_Paulo	(UTC-03:00) Brasilia	001	-03:00:00
182	America/Sao_Paulo	(UTC-03:00) Brasilia	BR	-03:00:00
183	America/Cayenne	(UTC-03:00) Cayenne, Fortaleza	001	-03:00:00
184	Antarctica/Rothera	(UTC-03:00) Cayenne, Fortaleza	AQ	-03:00:00
185	America/Belem	(UTC-03:00) Cayenne, Fortaleza	BR	-03:00:00
186	America/Fortaleza	(UTC-03:00) Cayenne, Fortaleza	BR	-03:00:00
187	America/Maceio	(UTC-03:00) Cayenne, Fortaleza	BR	-03:00:00
188	America/Recife	(UTC-03:00) Cayenne, Fortaleza	BR	-03:00:00
189	America/Santarem	(UTC-03:00) Cayenne, Fortaleza	BR	-03:00:00
190	Atlantic/Stanley	(UTC-03:00) Cayenne, Fortaleza	FK	-03:00:00
191	America/Cayenne	(UTC-03:00) Cayenne, Fortaleza	GF	-03:00:00
192	America/Paramaribo	(UTC-03:00) Cayenne, Fortaleza	SR	-03:00:00
193	Etc/GMT+3	(UTC-03:00) Cayenne, Fortaleza	ZZ	-03:00:00
194	America/Buenos_Aires	(UTC-03:00) City of Buenos Aires	001	-03:00:00
195	America/Argentina/La_Rioja	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
196	America/Argentina/Rio_Gallegos	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
197	America/Argentina/Salta	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
198	America/Argentina/San_Juan	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
199	America/Argentina/San_Luis	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
200	America/Argentina/Tucuman	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
201	America/Argentina/Ushuaia	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
202	America/Buenos_Aires	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
203	America/Catamarca	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
204	America/Cordoba	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
205	America/Jujuy	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
206	America/Mendoza	(UTC-03:00) City of Buenos Aires	AR	-03:00:00
207	America/Godthab	(UTC-03:00) Greenland	001	-03:00:00
208	America/Godthab	(UTC-03:00) Greenland	GL	-03:00:00
209	America/Montevideo	(UTC-03:00) Montevideo	001	-03:00:00
210	America/Montevideo	(UTC-03:00) Montevideo	UY	-03:00:00
211	America/Punta_Arenas	(UTC-03:00) Punta Arenas	001	-03:00:00
212	Antarctica/Palmer	(UTC-03:00) Punta Arenas	AQ	-03:00:00
213	America/Punta_Arenas	(UTC-03:00) Punta Arenas	CL	-03:00:00
214	America/Miquelon	(UTC-03:00) Saint Pierre and Miquelon	001	-03:00:00
215	America/Miquelon	(UTC-03:00) Saint Pierre and Miquelon	PM	-03:00:00
216	America/Bahia	(UTC-03:00) Salvador	001	-03:00:00
217	America/Bahia	(UTC-03:00) Salvador	BR	-03:00:00
218	Etc/GMT+2	(UTC-02:00) Coordinated Universal Time-02	001	-02:00:00
219	America/Noronha	(UTC-02:00) Coordinated Universal Time-02	BR	-02:00:00
365	Europe/Istanbul	(UTC+03:00) Istanbul	001	03:00:00
220	Atlantic/South_Georgia	(UTC-02:00) Coordinated Universal Time-02	GS	-02:00:00
221	Etc/GMT+2	(UTC-02:00) Coordinated Universal Time-02	ZZ	-02:00:00
222	Atlantic/Azores	(UTC-01:00) Azores	001	-01:00:00
223	America/Scoresbysund	(UTC-01:00) Azores	GL	-01:00:00
224	Atlantic/Azores	(UTC-01:00) Azores	PT	-01:00:00
225	Atlantic/Cape_Verde	(UTC-01:00) Cabo Verde Is.	001	-01:00:00
226	Atlantic/Cape_Verde	(UTC-01:00) Cabo Verde Is.	CV	-01:00:00
227	Etc/GMT+1	(UTC-01:00) Cabo Verde Is.	ZZ	-01:00:00
228	Etc/GMT	(UTC) Coordinated Universal Time	001	00:00:00
229	America/Danmarkshavn	(UTC) Coordinated Universal Time	GL	00:00:00
230	Etc/GMT	(UTC) Coordinated Universal Time	ZZ	00:00:00
231	Etc/UTC	(UTC) Coordinated Universal Time	ZZ	00:00:00
232	Africa/Casablanca	(UTC+00:00) Casablanca	001	00:00:00
233	Africa/El_Aaiun	(UTC+00:00) Casablanca	EH	00:00:00
234	Africa/Casablanca	(UTC+00:00) Casablanca	MA	00:00:00
235	Europe/London	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	001	00:00:00
236	Atlantic/Canary	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	ES	00:00:00
237	Atlantic/Faeroe	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	FO	00:00:00
238	Europe/London	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	GB	00:00:00
239	Europe/Guernsey	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	GG	00:00:00
240	Europe/Dublin	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	IE	00:00:00
241	Europe/Isle_of_Man	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	IM	00:00:00
242	Europe/Jersey	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	JE	00:00:00
243	Atlantic/Madeira	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	PT	00:00:00
244	Europe/Lisbon	(UTC+00:00) Dublin, Edinburgh, Lisbon, London	PT	00:00:00
245	Atlantic/Reykjavik	(UTC+00:00) Monrovia, Reykjavik	001	00:00:00
246	Africa/Ouagadougou	(UTC+00:00) Monrovia, Reykjavik	BF	00:00:00
247	Africa/Abidjan	(UTC+00:00) Monrovia, Reykjavik	CI	00:00:00
248	Africa/Accra	(UTC+00:00) Monrovia, Reykjavik	GH	00:00:00
249	Africa/Banjul	(UTC+00:00) Monrovia, Reykjavik	GM	00:00:00
250	Africa/Conakry	(UTC+00:00) Monrovia, Reykjavik	GN	00:00:00
251	Africa/Bissau	(UTC+00:00) Monrovia, Reykjavik	GW	00:00:00
252	Atlantic/Reykjavik	(UTC+00:00) Monrovia, Reykjavik	IS	00:00:00
253	Africa/Monrovia	(UTC+00:00) Monrovia, Reykjavik	LR	00:00:00
254	Africa/Bamako	(UTC+00:00) Monrovia, Reykjavik	ML	00:00:00
255	Africa/Nouakchott	(UTC+00:00) Monrovia, Reykjavik	MR	00:00:00
256	Atlantic/St_Helena	(UTC+00:00) Monrovia, Reykjavik	SH	00:00:00
257	Africa/Freetown	(UTC+00:00) Monrovia, Reykjavik	SL	00:00:00
258	Africa/Dakar	(UTC+00:00) Monrovia, Reykjavik	SN	00:00:00
259	Africa/Lome	(UTC+00:00) Monrovia, Reykjavik	TG	00:00:00
260	Europe/Berlin	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	001	01:00:00
261	Europe/Andorra	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	AD	01:00:00
262	Europe/Vienna	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	AT	01:00:00
263	Europe/Zurich	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	CH	01:00:00
264	Europe/Berlin	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	DE	01:00:00
265	Europe/Busingen	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	DE	01:00:00
266	Europe/Gibraltar	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	GI	01:00:00
267	Europe/Rome	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	IT	01:00:00
268	Europe/Vaduz	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	LI	01:00:00
269	Europe/Luxembourg	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	LU	01:00:00
270	Europe/Monaco	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	MC	01:00:00
271	Europe/Malta	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	MT	01:00:00
272	Europe/Amsterdam	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	NL	01:00:00
273	Europe/Oslo	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	NO	01:00:00
274	Europe/Stockholm	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	SE	01:00:00
275	Arctic/Longyearbyen	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	SJ	01:00:00
276	Europe/San_Marino	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	SM	01:00:00
277	Europe/Vatican	(UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna	VA	01:00:00
278	Europe/Budapest	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	001	01:00:00
279	Europe/Tirane	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	AL	01:00:00
280	Europe/Prague	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	CZ	01:00:00
281	Europe/Budapest	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	HU	01:00:00
282	Europe/Podgorica	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	ME	01:00:00
283	Europe/Belgrade	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	RS	01:00:00
284	Europe/Ljubljana	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	SI	01:00:00
285	Europe/Bratislava	(UTC+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague	SK	01:00:00
286	Europe/Paris	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	001	01:00:00
287	Europe/Brussels	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	BE	01:00:00
288	Europe/Copenhagen	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	DK	01:00:00
289	Africa/Ceuta	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	ES	01:00:00
290	Europe/Madrid	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	ES	01:00:00
291	Europe/Paris	(UTC+01:00) Brussels, Copenhagen, Madrid, Paris	FR	01:00:00
292	Europe/Warsaw	(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb	001	01:00:00
293	Europe/Sarajevo	(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb	BA	01:00:00
294	Europe/Zagreb	(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb	HR	01:00:00
295	Europe/Skopje	(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb	MK	01:00:00
296	Europe/Warsaw	(UTC+01:00) Sarajevo, Skopje, Warsaw, Zagreb	PL	01:00:00
297	Africa/Lagos	(UTC+01:00) West Central Africa	001	01:00:00
298	Africa/Luanda	(UTC+01:00) West Central Africa	AO	01:00:00
299	Africa/Porto-Novo	(UTC+01:00) West Central Africa	BJ	01:00:00
300	Africa/Kinshasa	(UTC+01:00) West Central Africa	CD	01:00:00
301	Africa/Bangui	(UTC+01:00) West Central Africa	CF	01:00:00
302	Africa/Brazzaville	(UTC+01:00) West Central Africa	CG	01:00:00
303	Africa/Douala	(UTC+01:00) West Central Africa	CM	01:00:00
304	Africa/Algiers	(UTC+01:00) West Central Africa	DZ	01:00:00
305	Africa/Libreville	(UTC+01:00) West Central Africa	GA	01:00:00
306	Africa/Malabo	(UTC+01:00) West Central Africa	GQ	01:00:00
307	Africa/Niamey	(UTC+01:00) West Central Africa	NE	01:00:00
308	Africa/Lagos	(UTC+01:00) West Central Africa	NG	01:00:00
309	Africa/Sao_Tome	(UTC+01:00) West Central Africa	ST	01:00:00
310	Africa/Ndjamena	(UTC+01:00) West Central Africa	TD	01:00:00
311	Africa/Tunis	(UTC+01:00) West Central Africa	TN	01:00:00
312	Etc/GMT-1	(UTC+01:00) West Central Africa	ZZ	01:00:00
313	Asia/Amman	(UTC+02:00) Amman	001	02:00:00
314	Asia/Amman	(UTC+02:00) Amman	JO	02:00:00
315	Europe/Bucharest	(UTC+02:00) Athens, Bucharest	001	02:00:00
316	Asia/Nicosia	(UTC+02:00) Athens, Bucharest	CY	02:00:00
317	Europe/Athens	(UTC+02:00) Athens, Bucharest	GR	02:00:00
318	Europe/Bucharest	(UTC+02:00) Athens, Bucharest	RO	02:00:00
319	Asia/Beirut	(UTC+02:00) Beirut	001	02:00:00
320	Asia/Beirut	(UTC+02:00) Beirut	LB	02:00:00
321	Africa/Cairo	(UTC+02:00) Cairo	001	02:00:00
322	Africa/Cairo	(UTC+02:00) Cairo	EG	02:00:00
323	Europe/Chisinau	(UTC+02:00) Chisinau	001	02:00:00
324	Europe/Chisinau	(UTC+02:00) Chisinau	MD	02:00:00
325	Asia/Damascus	(UTC+02:00) Damascus	001	02:00:00
326	Asia/Damascus	(UTC+02:00) Damascus	SY	02:00:00
327	Asia/Hebron	(UTC+02:00) Gaza, Hebron	001	02:00:00
328	Asia/Gaza	(UTC+02:00) Gaza, Hebron	PS	02:00:00
329	Asia/Hebron	(UTC+02:00) Gaza, Hebron	PS	02:00:00
330	Africa/Johannesburg	(UTC+02:00) Harare, Pretoria	001	02:00:00
331	Africa/Bujumbura	(UTC+02:00) Harare, Pretoria	BI	02:00:00
332	Africa/Gaborone	(UTC+02:00) Harare, Pretoria	BW	02:00:00
333	Africa/Lubumbashi	(UTC+02:00) Harare, Pretoria	CD	02:00:00
334	Africa/Maseru	(UTC+02:00) Harare, Pretoria	LS	02:00:00
335	Africa/Blantyre	(UTC+02:00) Harare, Pretoria	MW	02:00:00
336	Africa/Maputo	(UTC+02:00) Harare, Pretoria	MZ	02:00:00
337	Africa/Kigali	(UTC+02:00) Harare, Pretoria	RW	02:00:00
338	Africa/Mbabane	(UTC+02:00) Harare, Pretoria	SZ	02:00:00
339	Africa/Johannesburg	(UTC+02:00) Harare, Pretoria	ZA	02:00:00
340	Africa/Lusaka	(UTC+02:00) Harare, Pretoria	ZM	02:00:00
341	Africa/Harare	(UTC+02:00) Harare, Pretoria	ZW	02:00:00
342	Etc/GMT-2	(UTC+02:00) Harare, Pretoria	ZZ	02:00:00
343	Europe/Kiev	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	001	02:00:00
344	Europe/Mariehamn	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	AX	02:00:00
345	Europe/Sofia	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	BG	02:00:00
346	Europe/Tallinn	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	EE	02:00:00
347	Europe/Helsinki	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	FI	02:00:00
348	Europe/Vilnius	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	LT	02:00:00
349	Europe/Riga	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	LV	02:00:00
350	Europe/Kiev	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	UA	02:00:00
351	Europe/Uzhgorod	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	UA	02:00:00
352	Europe/Zaporozhye	(UTC+02:00) Helsinki, Kyiv, Riga, Sofia, Tallinn, Vilnius	UA	02:00:00
353	Asia/Jerusalem	(UTC+02:00) Jerusalem	001	02:00:00
354	Asia/Jerusalem	(UTC+02:00) Jerusalem	IL	02:00:00
355	Europe/Kaliningrad	(UTC+02:00) Kaliningrad	001	02:00:00
356	Europe/Kaliningrad	(UTC+02:00) Kaliningrad	RU	02:00:00
357	Africa/Khartoum	(UTC+02:00) Khartoum	001	02:00:00
358	Africa/Khartoum	(UTC+02:00) Khartoum	SD	02:00:00
359	Africa/Tripoli	(UTC+02:00) Tripoli	001	02:00:00
360	Africa/Tripoli	(UTC+02:00) Tripoli	LY	02:00:00
361	Africa/Windhoek	(UTC+02:00) Windhoek	001	02:00:00
362	Africa/Windhoek	(UTC+02:00) Windhoek	NA	02:00:00
363	Asia/Baghdad	(UTC+03:00) Baghdad	001	03:00:00
366	Asia/Famagusta	(UTC+03:00) Istanbul	CY	03:00:00
367	Europe/Istanbul	(UTC+03:00) Istanbul	TR	03:00:00
368	Asia/Riyadh	(UTC+03:00) Kuwait, Riyadh	001	03:00:00
369	Asia/Bahrain	(UTC+03:00) Kuwait, Riyadh	BH	03:00:00
370	Asia/Kuwait	(UTC+03:00) Kuwait, Riyadh	KW	03:00:00
371	Asia/Qatar	(UTC+03:00) Kuwait, Riyadh	QA	03:00:00
372	Asia/Riyadh	(UTC+03:00) Kuwait, Riyadh	SA	03:00:00
373	Asia/Aden	(UTC+03:00) Kuwait, Riyadh	YE	03:00:00
374	Europe/Minsk	(UTC+03:00) Minsk	001	03:00:00
375	Europe/Minsk	(UTC+03:00) Minsk	BY	03:00:00
376	Europe/Moscow	(UTC+03:00) Moscow, St. Petersburg, Volgograd	001	03:00:00
377	Europe/Kirov	(UTC+03:00) Moscow, St. Petersburg, Volgograd	RU	03:00:00
378	Europe/Moscow	(UTC+03:00) Moscow, St. Petersburg, Volgograd	RU	03:00:00
379	Europe/Volgograd	(UTC+03:00) Moscow, St. Petersburg, Volgograd	RU	03:00:00
380	Europe/Simferopol	(UTC+03:00) Moscow, St. Petersburg, Volgograd	UA	03:00:00
381	Africa/Nairobi	(UTC+03:00) Nairobi	001	03:00:00
382	Antarctica/Syowa	(UTC+03:00) Nairobi	AQ	03:00:00
383	Africa/Djibouti	(UTC+03:00) Nairobi	DJ	03:00:00
384	Africa/Asmera	(UTC+03:00) Nairobi	ER	03:00:00
385	Africa/Addis_Ababa	(UTC+03:00) Nairobi	ET	03:00:00
386	Africa/Nairobi	(UTC+03:00) Nairobi	KE	03:00:00
387	Indian/Comoro	(UTC+03:00) Nairobi	KM	03:00:00
388	Indian/Antananarivo	(UTC+03:00) Nairobi	MG	03:00:00
389	Africa/Mogadishu	(UTC+03:00) Nairobi	SO	03:00:00
390	Africa/Juba	(UTC+03:00) Nairobi	SS	03:00:00
391	Africa/Dar_es_Salaam	(UTC+03:00) Nairobi	TZ	03:00:00
392	Africa/Kampala	(UTC+03:00) Nairobi	UG	03:00:00
393	Indian/Mayotte	(UTC+03:00) Nairobi	YT	03:00:00
394	Etc/GMT-3	(UTC+03:00) Nairobi	ZZ	03:00:00
395	Asia/Tehran	(UTC+03:30) Tehran	001	03:30:00
396	Asia/Tehran	(UTC+03:30) Tehran	IR	03:30:00
397	Asia/Dubai	(UTC+04:00) Abu Dhabi, Muscat	001	04:00:00
398	Asia/Dubai	(UTC+04:00) Abu Dhabi, Muscat	AE	04:00:00
399	Asia/Muscat	(UTC+04:00) Abu Dhabi, Muscat	OM	04:00:00
400	Etc/GMT-4	(UTC+04:00) Abu Dhabi, Muscat	ZZ	04:00:00
401	Europe/Astrakhan	(UTC+04:00) Astrakhan, Ulyanovsk	001	04:00:00
402	Europe/Astrakhan	(UTC+04:00) Astrakhan, Ulyanovsk	RU	04:00:00
403	Europe/Ulyanovsk	(UTC+04:00) Astrakhan, Ulyanovsk	RU	04:00:00
404	Asia/Baku	(UTC+04:00) Baku	001	04:00:00
405	Asia/Baku	(UTC+04:00) Baku	AZ	04:00:00
406	Europe/Samara	(UTC+04:00) Izhevsk, Samara	001	04:00:00
407	Europe/Samara	(UTC+04:00) Izhevsk, Samara	RU	04:00:00
408	Indian/Mauritius	(UTC+04:00) Port Louis	001	04:00:00
409	Indian/Mauritius	(UTC+04:00) Port Louis	MU	04:00:00
410	Indian/Reunion	(UTC+04:00) Port Louis	RE	04:00:00
411	Indian/Mahe	(UTC+04:00) Port Louis	SC	04:00:00
412	Europe/Saratov	(UTC+04:00) Saratov	001	04:00:00
413	Europe/Saratov	(UTC+04:00) Saratov	RU	04:00:00
414	Asia/Tbilisi	(UTC+04:00) Tbilisi	001	04:00:00
415	Asia/Tbilisi	(UTC+04:00) Tbilisi	GE	04:00:00
416	Asia/Yerevan	(UTC+04:00) Yerevan	001	04:00:00
417	Asia/Yerevan	(UTC+04:00) Yerevan	AM	04:00:00
418	Asia/Kabul	(UTC+04:30) Kabul	001	04:30:00
419	Asia/Kabul	(UTC+04:30) Kabul	AF	04:30:00
420	Asia/Tashkent	(UTC+05:00) Ashgabat, Tashkent	001	05:00:00
421	Antarctica/Mawson	(UTC+05:00) Ashgabat, Tashkent	AQ	05:00:00
422	Asia/Aqtau	(UTC+05:00) Ashgabat, Tashkent	KZ	05:00:00
423	Asia/Aqtobe	(UTC+05:00) Ashgabat, Tashkent	KZ	05:00:00
424	Asia/Atyrau	(UTC+05:00) Ashgabat, Tashkent	KZ	05:00:00
425	Asia/Oral	(UTC+05:00) Ashgabat, Tashkent	KZ	05:00:00
426	Indian/Maldives	(UTC+05:00) Ashgabat, Tashkent	MV	05:00:00
427	Indian/Kerguelen	(UTC+05:00) Ashgabat, Tashkent	TF	05:00:00
428	Asia/Dushanbe	(UTC+05:00) Ashgabat, Tashkent	TJ	05:00:00
429	Asia/Ashgabat	(UTC+05:00) Ashgabat, Tashkent	TM	05:00:00
430	Asia/Samarkand	(UTC+05:00) Ashgabat, Tashkent	UZ	05:00:00
431	Asia/Tashkent	(UTC+05:00) Ashgabat, Tashkent	UZ	05:00:00
432	Etc/GMT-5	(UTC+05:00) Ashgabat, Tashkent	ZZ	05:00:00
433	Asia/Yekaterinburg	(UTC+05:00) Ekaterinburg	001	05:00:00
434	Asia/Yekaterinburg	(UTC+05:00) Ekaterinburg	RU	05:00:00
435	Asia/Karachi	(UTC+05:00) Islamabad, Karachi	001	05:00:00
436	Asia/Karachi	(UTC+05:00) Islamabad, Karachi	PK	05:00:00
437	Asia/Calcutta	(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi	001	05:30:00
438	Asia/Calcutta	(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi	IN	05:30:00
439	Asia/Colombo	(UTC+05:30) Sri Jayawardenepura	001	05:30:00
440	Asia/Colombo	(UTC+05:30) Sri Jayawardenepura	LK	05:30:00
441	Asia/Katmandu	(UTC+05:45) Kathmandu	001	05:45:00
442	Asia/Katmandu	(UTC+05:45) Kathmandu	NP	05:45:00
443	Asia/Almaty	(UTC+06:00) Astana	001	06:00:00
444	Antarctica/Vostok	(UTC+06:00) Astana	AQ	06:00:00
445	Asia/Urumqi	(UTC+06:00) Astana	CN	06:00:00
446	Indian/Chagos	(UTC+06:00) Astana	IO	06:00:00
447	Asia/Bishkek	(UTC+06:00) Astana	KG	06:00:00
448	Asia/Almaty	(UTC+06:00) Astana	KZ	06:00:00
449	Asia/Qyzylorda	(UTC+06:00) Astana	KZ	06:00:00
450	Etc/GMT-6	(UTC+06:00) Astana	ZZ	06:00:00
451	Asia/Dhaka	(UTC+06:00) Dhaka	001	06:00:00
452	Asia/Dhaka	(UTC+06:00) Dhaka	BD	06:00:00
453	Asia/Thimphu	(UTC+06:00) Dhaka	BT	06:00:00
454	Asia/Omsk	(UTC+06:00) Omsk	001	06:00:00
455	Asia/Omsk	(UTC+06:00) Omsk	RU	06:00:00
456	Asia/Rangoon	(UTC+06:30) Yangon (Rangoon)	001	06:30:00
457	Indian/Cocos	(UTC+06:30) Yangon (Rangoon)	CC	06:30:00
458	Asia/Rangoon	(UTC+06:30) Yangon (Rangoon)	MM	06:30:00
459	Asia/Bangkok	(UTC+07:00) Bangkok, Hanoi, Jakarta	001	07:00:00
460	Antarctica/Davis	(UTC+07:00) Bangkok, Hanoi, Jakarta	AQ	07:00:00
461	Indian/Christmas	(UTC+07:00) Bangkok, Hanoi, Jakarta	CX	07:00:00
462	Asia/Jakarta	(UTC+07:00) Bangkok, Hanoi, Jakarta	ID	07:00:00
463	Asia/Pontianak	(UTC+07:00) Bangkok, Hanoi, Jakarta	ID	07:00:00
464	Asia/Phnom_Penh	(UTC+07:00) Bangkok, Hanoi, Jakarta	KH	07:00:00
465	Asia/Vientiane	(UTC+07:00) Bangkok, Hanoi, Jakarta	LA	07:00:00
466	Asia/Bangkok	(UTC+07:00) Bangkok, Hanoi, Jakarta	TH	07:00:00
467	Asia/Saigon	(UTC+07:00) Bangkok, Hanoi, Jakarta	VN	07:00:00
468	Etc/GMT-7	(UTC+07:00) Bangkok, Hanoi, Jakarta	ZZ	07:00:00
469	Asia/Barnaul	(UTC+07:00) Barnaul, Gorno-Altaysk	001	07:00:00
470	Asia/Barnaul	(UTC+07:00) Barnaul, Gorno-Altaysk	RU	07:00:00
471	Asia/Hovd	(UTC+07:00) Hovd	001	07:00:00
472	Asia/Hovd	(UTC+07:00) Hovd	MN	07:00:00
473	Asia/Krasnoyarsk	(UTC+07:00) Krasnoyarsk	001	07:00:00
474	Asia/Krasnoyarsk	(UTC+07:00) Krasnoyarsk	RU	07:00:00
475	Asia/Novokuznetsk	(UTC+07:00) Krasnoyarsk	RU	07:00:00
476	Asia/Novosibirsk	(UTC+07:00) Novosibirsk	001	07:00:00
477	Asia/Novosibirsk	(UTC+07:00) Novosibirsk	RU	07:00:00
478	Asia/Tomsk	(UTC+07:00) Tomsk	001	07:00:00
479	Asia/Tomsk	(UTC+07:00) Tomsk	RU	07:00:00
480	Asia/Shanghai	(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi	001	08:00:00
481	Asia/Shanghai	(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi	CN	08:00:00
482	Asia/Hong_Kong	(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi	HK	08:00:00
483	Asia/Macau	(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi	MO	08:00:00
484	Asia/Irkutsk	(UTC+08:00) Irkutsk	001	08:00:00
485	Asia/Irkutsk	(UTC+08:00) Irkutsk	RU	08:00:00
486	Asia/Singapore	(UTC+08:00) Kuala Lumpur, Singapore	001	08:00:00
487	Asia/Brunei	(UTC+08:00) Kuala Lumpur, Singapore	BN	08:00:00
488	Asia/Makassar	(UTC+08:00) Kuala Lumpur, Singapore	ID	08:00:00
489	Asia/Kuala_Lumpur	(UTC+08:00) Kuala Lumpur, Singapore	MY	08:00:00
490	Asia/Kuching	(UTC+08:00) Kuala Lumpur, Singapore	MY	08:00:00
491	Asia/Manila	(UTC+08:00) Kuala Lumpur, Singapore	PH	08:00:00
492	Asia/Singapore	(UTC+08:00) Kuala Lumpur, Singapore	SG	08:00:00
493	Etc/GMT-8	(UTC+08:00) Kuala Lumpur, Singapore	ZZ	08:00:00
494	Australia/Perth	(UTC+08:00) Perth	001	08:00:00
495	Antarctica/Casey	(UTC+08:00) Perth	AQ	08:00:00
496	Australia/Perth	(UTC+08:00) Perth	AU	08:00:00
497	Asia/Taipei	(UTC+08:00) Taipei	001	08:00:00
498	Asia/Taipei	(UTC+08:00) Taipei	TW	08:00:00
499	Asia/Ulaanbaatar	(UTC+08:00) Ulaanbaatar	001	08:00:00
500	Asia/Choibalsan	(UTC+08:00) Ulaanbaatar	MN	08:00:00
501	Asia/Ulaanbaatar	(UTC+08:00) Ulaanbaatar	MN	08:00:00
502	Asia/Pyongyang	(UTC+08:30) Pyongyang	001	08:30:00
503	Asia/Pyongyang	(UTC+08:30) Pyongyang	KP	08:30:00
504	Australia/Eucla	(UTC+08:45) Eucla	001	08:45:00
505	Australia/Eucla	(UTC+08:45) Eucla	AU	08:45:00
506	Asia/Chita	(UTC+09:00) Chita	001	09:00:00
507	Asia/Chita	(UTC+09:00) Chita	RU	09:00:00
508	Asia/Tokyo	(UTC+09:00) Osaka, Sapporo, Tokyo	001	09:00:00
509	Asia/Jayapura	(UTC+09:00) Osaka, Sapporo, Tokyo	ID	09:00:00
510	Asia/Tokyo	(UTC+09:00) Osaka, Sapporo, Tokyo	JP	09:00:00
511	Pacific/Palau	(UTC+09:00) Osaka, Sapporo, Tokyo	PW	09:00:00
512	Asia/Dili	(UTC+09:00) Osaka, Sapporo, Tokyo	TL	09:00:00
513	Etc/GMT-9	(UTC+09:00) Osaka, Sapporo, Tokyo	ZZ	09:00:00
514	Asia/Seoul	(UTC+09:00) Seoul	001	09:00:00
515	Asia/Seoul	(UTC+09:00) Seoul	KR	09:00:00
516	Asia/Yakutsk	(UTC+09:00) Yakutsk	001	09:00:00
517	Asia/Khandyga	(UTC+09:00) Yakutsk	RU	09:00:00
518	Asia/Yakutsk	(UTC+09:00) Yakutsk	RU	09:00:00
519	Australia/Adelaide	(UTC+09:30) Adelaide	001	09:30:00
520	Australia/Adelaide	(UTC+09:30) Adelaide	AU	09:30:00
521	Australia/Broken_Hill	(UTC+09:30) Adelaide	AU	09:30:00
522	Australia/Darwin	(UTC+09:30) Darwin	001	09:30:00
523	Australia/Darwin	(UTC+09:30) Darwin	AU	09:30:00
524	Australia/Brisbane	(UTC+10:00) Brisbane	001	10:00:00
525	Australia/Brisbane	(UTC+10:00) Brisbane	AU	10:00:00
526	Australia/Lindeman	(UTC+10:00) Brisbane	AU	10:00:00
527	Australia/Sydney	(UTC+10:00) Canberra, Melbourne, Sydney	001	10:00:00
528	Australia/Melbourne	(UTC+10:00) Canberra, Melbourne, Sydney	AU	10:00:00
529	Australia/Sydney	(UTC+10:00) Canberra, Melbourne, Sydney	AU	10:00:00
530	Pacific/Port_Moresby	(UTC+10:00) Guam, Port Moresby	001	10:00:00
531	Antarctica/DumontDUrville	(UTC+10:00) Guam, Port Moresby	AQ	10:00:00
532	Pacific/Truk	(UTC+10:00) Guam, Port Moresby	FM	10:00:00
533	Pacific/Guam	(UTC+10:00) Guam, Port Moresby	GU	10:00:00
534	Pacific/Saipan	(UTC+10:00) Guam, Port Moresby	MP	10:00:00
535	Pacific/Port_Moresby	(UTC+10:00) Guam, Port Moresby	PG	10:00:00
536	Etc/GMT-10	(UTC+10:00) Guam, Port Moresby	ZZ	10:00:00
537	Australia/Hobart	(UTC+10:00) Hobart	001	10:00:00
538	Australia/Currie	(UTC+10:00) Hobart	AU	10:00:00
539	Australia/Hobart	(UTC+10:00) Hobart	AU	10:00:00
540	Asia/Vladivostok	(UTC+10:00) Vladivostok	001	10:00:00
541	Asia/Ust-Nera	(UTC+10:00) Vladivostok	RU	10:00:00
542	Asia/Vladivostok	(UTC+10:00) Vladivostok	RU	10:00:00
543	Australia/Lord_Howe	(UTC+10:30) Lord Howe Island	001	10:30:00
544	Australia/Lord_Howe	(UTC+10:30) Lord Howe Island	AU	10:30:00
545	Pacific/Bougainville	(UTC+11:00) Bougainville Island	001	11:00:00
546	Pacific/Bougainville	(UTC+11:00) Bougainville Island	PG	11:00:00
547	Asia/Srednekolymsk	(UTC+11:00) Chokurdakh	001	11:00:00
548	Asia/Srednekolymsk	(UTC+11:00) Chokurdakh	RU	11:00:00
549	Asia/Magadan	(UTC+11:00) Magadan	001	11:00:00
550	Asia/Magadan	(UTC+11:00) Magadan	RU	11:00:00
551	Pacific/Norfolk	(UTC+11:00) Norfolk Island	001	11:00:00
552	Pacific/Norfolk	(UTC+11:00) Norfolk Island	NF	11:00:00
553	Asia/Sakhalin	(UTC+11:00) Sakhalin	001	11:00:00
554	Asia/Sakhalin	(UTC+11:00) Sakhalin	RU	11:00:00
555	Pacific/Guadalcanal	(UTC+11:00) Solomon Is., New Caledonia	001	11:00:00
556	Antarctica/Macquarie	(UTC+11:00) Solomon Is., New Caledonia	AU	11:00:00
557	Pacific/Kosrae	(UTC+11:00) Solomon Is., New Caledonia	FM	11:00:00
558	Pacific/Ponape	(UTC+11:00) Solomon Is., New Caledonia	FM	11:00:00
559	Pacific/Noumea	(UTC+11:00) Solomon Is., New Caledonia	NC	11:00:00
560	Pacific/Guadalcanal	(UTC+11:00) Solomon Is., New Caledonia	SB	11:00:00
561	Pacific/Efate	(UTC+11:00) Solomon Is., New Caledonia	VU	11:00:00
562	Etc/GMT-11	(UTC+11:00) Solomon Is., New Caledonia	ZZ	11:00:00
563	Asia/Kamchatka	(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky	001	12:00:00
564	Asia/Anadyr	(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky	RU	12:00:00
565	Asia/Kamchatka	(UTC+12:00) Anadyr, Petropavlovsk-Kamchatsky	RU	12:00:00
566	Pacific/Auckland	(UTC+12:00) Auckland, Wellington	001	12:00:00
567	Antarctica/McMurdo	(UTC+12:00) Auckland, Wellington	AQ	12:00:00
568	Pacific/Auckland	(UTC+12:00) Auckland, Wellington	NZ	12:00:00
569	Etc/GMT-12	(UTC+12:00) Coordinated Universal Time+12	001	12:00:00
570	Pacific/Tarawa	(UTC+12:00) Coordinated Universal Time+12	KI	12:00:00
571	Pacific/Kwajalein	(UTC+12:00) Coordinated Universal Time+12	MH	12:00:00
572	Pacific/Majuro	(UTC+12:00) Coordinated Universal Time+12	MH	12:00:00
573	Pacific/Nauru	(UTC+12:00) Coordinated Universal Time+12	NR	12:00:00
574	Pacific/Funafuti	(UTC+12:00) Coordinated Universal Time+12	TV	12:00:00
575	Pacific/Wake	(UTC+12:00) Coordinated Universal Time+12	UM	12:00:00
576	Pacific/Wallis	(UTC+12:00) Coordinated Universal Time+12	WF	12:00:00
577	Etc/GMT-12	(UTC+12:00) Coordinated Universal Time+12	ZZ	12:00:00
578	Pacific/Fiji	(UTC+12:00) Fiji	001	12:00:00
579	Pacific/Fiji	(UTC+12:00) Fiji	FJ	12:00:00
580	Pacific/Chatham	(UTC+12:45) Chatham Islands	001	12:45:00
581	Pacific/Chatham	(UTC+12:45) Chatham Islands	NZ	12:45:00
582	Etc/GMT-13	(UTC+13:00) Coordinated Universal Time+13	001	13:00:00
583	Pacific/Enderbury	(UTC+13:00) Coordinated Universal Time+13	KI	13:00:00
584	Pacific/Fakaofo	(UTC+13:00) Coordinated Universal Time+13	TK	13:00:00
585	Etc/GMT-13	(UTC+13:00) Coordinated Universal Time+13	ZZ	13:00:00
586	Pacific/Tongatapu	(UTC+13:00) Nuku'alofa	001	13:00:00
587	Pacific/Tongatapu	(UTC+13:00) Nuku'alofa	TO	13:00:00
588	Pacific/Apia	(UTC+13:00) Samoa	001	13:00:00
589	Pacific/Apia	(UTC+13:00) Samoa	WS	13:00:00
590	Pacific/Kiritimati	(UTC+14:00) Kiritimati Island	001	14:00:00
591	Pacific/Kiritimati	(UTC+14:00) Kiritimati Island	KI	14:00:00
592	Etc/GMT-14	(UTC+14:00) Kiritimati Island	ZZ	14:00:00
\.


ALTER TABLE core.time_zone ENABLE TRIGGER ALL;

--
-- Data for Name: user_account; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.user_account DISABLE TRIGGER ALL;

COPY core.user_account (id, name, email, password_hash, password_salt, date_created, role, time_zone_id, creation_analytics, is_email_confirmed, aotd_alert, reply_alert_count, loopback_alert_count, post_alert_count, follower_alert_count, has_linked_twitter_account, date_deleted, date_orientation_completed, subscription_end_date) FROM stdin;
1	PrimordialReader	sample@email.com	\\x30406eb87aefe0705336286575aec3216820f089a055f4fad031ae58d254f8b3	\\xacc98c7efecc72623f21146c02fde002	2022-06-20 14:19:56.571133	regular	347	{"action": null, "client": null, "current_path": null, "initial_path": null, "referrer_url": null, "marketing_variant": 0}	f	f	0	0	0	0	f	\N	\N	\N
\.


ALTER TABLE core.user_account ENABLE TRIGGER ALL;

--
-- Data for Name: article_author; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.article_author DISABLE TRIGGER ALL;

COPY core.article_author (article_id, author_id, date_assigned, date_unassigned, assignment_method, assigned_by_user_account_id, unassigned_by_user_account_id) FROM stdin;
1	1	2022-06-20 14:19:56.63009	\N	metadata	\N	\N
2	1	2022-06-20 14:19:56.673595	\N	metadata	\N	\N
3	1	2022-06-20 14:19:56.693398	\N	metadata	\N	\N
\.


ALTER TABLE core.article_author ENABLE TRIGGER ALL;

--
-- Data for Name: article_image; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.article_image DISABLE TRIGGER ALL;

COPY core.article_image (article_id, date_created, creator_user_id, url) FROM stdin;
1	2022-06-20 14:19:56.638801	1	https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Liverpool_white_swamphen.jpg/136px-Liverpool_white_swamphen.jpg
2	2022-06-20 14:19:56.676151	1	https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Stephen_Webby_slide_at_the_2013_Webby_Awards.jpg/171px-Stephen_Webby_slide_at_the_2013_Webby_Awards.jpg
3	2022-06-20 14:19:56.695739	1	https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Paul_McCartney_with_Linda_McCartney_-_Wings_-_1976.jpg/171px-Paul_McCartney_with_Linda_McCartney_-_Wings_-_1976.jpg
\.


ALTER TABLE core.article_image ENABLE TRIGGER ALL;

--
-- Data for Name: article_issue_report; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.article_issue_report DISABLE TRIGGER ALL;

COPY core.article_issue_report (id, date_created, article_id, user_account_id, issue, analytics) FROM stdin;
\.


ALTER TABLE core.article_issue_report ENABLE TRIGGER ALL;

--
-- Data for Name: tag; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.tag DISABLE TRIGGER ALL;

COPY core.tag (id, name, slug) FROM stdin;
\.


ALTER TABLE core.tag ENABLE TRIGGER ALL;

--
-- Data for Name: article_tag; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.article_tag DISABLE TRIGGER ALL;

COPY core.article_tag (article_id, tag_id) FROM stdin;
\.


ALTER TABLE core.article_tag ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_identity; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_identity DISABLE TRIGGER ALL;

COPY core.auth_service_identity (id, date_created, provider, provider_user_id, real_user_rating, sign_up_analytics) FROM stdin;
\.


ALTER TABLE core.auth_service_identity ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_request_token; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_request_token DISABLE TRIGGER ALL;

COPY core.auth_service_request_token (id, date_created, provider, token_value, token_secret, date_cancelled, sign_up_analytics) FROM stdin;
\.


ALTER TABLE core.auth_service_request_token ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_access_token; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_access_token DISABLE TRIGGER ALL;

COPY core.auth_service_access_token (date_created, last_stored, identity_id, request_id, token_value, token_secret, date_revoked) FROM stdin;
\.


ALTER TABLE core.auth_service_access_token ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_authentication; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_authentication DISABLE TRIGGER ALL;

COPY core.auth_service_authentication (id, date_authenticated, identity_id, session_id) FROM stdin;
\.


ALTER TABLE core.auth_service_authentication ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_association; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_association DISABLE TRIGGER ALL;

COPY core.auth_service_association (date_associated, identity_id, authentication_id, user_account_id, association_method, date_dissociated) FROM stdin;
\.


ALTER TABLE core.auth_service_association ENABLE TRIGGER ALL;

--
-- Data for Name: comment; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.comment DISABLE TRIGGER ALL;

COPY core.comment (id, date_created, text, article_id, user_account_id, parent_comment_id, analytics, date_deleted) FROM stdin;
1	2022-06-20 14:19:56.665869	It was a good read!	1	1	\N	{"client": {"mode": null, "type": "desktop/app", "version": null}}	\N
2	2022-06-20 14:19:56.680401	It was a decent read!	2	1	\N	{"client": {"mode": null, "type": "desktop/app", "version": null}}	\N
3	2022-06-20 14:19:56.699954	It was a decent read!	3	1	\N	{"client": {"mode": null, "type": "desktop/app", "version": null}}	\N
\.


ALTER TABLE core.comment ENABLE TRIGGER ALL;

--
-- Data for Name: silent_post; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.silent_post DISABLE TRIGGER ALL;

COPY core.silent_post (id, article_id, user_account_id, date_created, analytics, date_deleted) FROM stdin;
\.


ALTER TABLE core.silent_post ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_post; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_post DISABLE TRIGGER ALL;

COPY core.auth_service_post (id, identity_id, date_posted, comment_id, silent_post_id, content, provider_post_id) FROM stdin;
\.


ALTER TABLE core.auth_service_post ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_refresh_token; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_refresh_token DISABLE TRIGGER ALL;

COPY core.auth_service_refresh_token (date_created, identity_id, raw_value) FROM stdin;
\.


ALTER TABLE core.auth_service_refresh_token ENABLE TRIGGER ALL;

--
-- Data for Name: auth_service_user; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.auth_service_user DISABLE TRIGGER ALL;

COPY core.auth_service_user (date_created, identity_id, email_address, is_email_address_private, name, handle) FROM stdin;
\.


ALTER TABLE core.auth_service_user ENABLE TRIGGER ALL;

--
-- Data for Name: payout_account; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.payout_account DISABLE TRIGGER ALL;

COPY core.payout_account (id, user_account_id, date_created, date_details_submitted, date_payouts_enabled) FROM stdin;
\.


ALTER TABLE core.payout_account ENABLE TRIGGER ALL;

--
-- Data for Name: author_payout; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.author_payout DISABLE TRIGGER ALL;

COPY core.author_payout (id, date_created, payout_account_id, amount) FROM stdin;
\.


ALTER TABLE core.author_payout ENABLE TRIGGER ALL;

--
-- Data for Name: author_user_account_assignment; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.author_user_account_assignment DISABLE TRIGGER ALL;

COPY core.author_user_account_assignment (id, author_id, user_account_id, date_assigned) FROM stdin;
\.


ALTER TABLE core.author_user_account_assignment ENABLE TRIGGER ALL;

--
-- Data for Name: captcha_response; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.captcha_response DISABLE TRIGGER ALL;

COPY core.captcha_response (id, date_created, action_verified, success, score, action, challenge_ts, hostname, error_codes) FROM stdin;
\.


ALTER TABLE core.captcha_response ENABLE TRIGGER ALL;

--
-- Data for Name: challenge; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.challenge DISABLE TRIGGER ALL;

COPY core.challenge (id, name, start_date, end_date, award_limit) FROM stdin;
\.


ALTER TABLE core.challenge ENABLE TRIGGER ALL;

--
-- Data for Name: challenge_award; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.challenge_award DISABLE TRIGGER ALL;

COPY core.challenge_award (id, challenge_id, user_account_id, date_awarded, date_fulfilled, reference) FROM stdin;
\.


ALTER TABLE core.challenge_award ENABLE TRIGGER ALL;

--
-- Data for Name: challenge_response; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.challenge_response DISABLE TRIGGER ALL;

COPY core.challenge_response (id, challenge_id, user_account_id, date, action, time_zone_id) FROM stdin;
\.


ALTER TABLE core.challenge_response ENABLE TRIGGER ALL;

--
-- Data for Name: client_error_report; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.client_error_report DISABLE TRIGGER ALL;

COPY core.client_error_report (id, date_created, content, analytics) FROM stdin;
\.


ALTER TABLE core.client_error_report ENABLE TRIGGER ALL;

--
-- Data for Name: comment_addendum; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.comment_addendum DISABLE TRIGGER ALL;

COPY core.comment_addendum (id, date_created, comment_id, text_content) FROM stdin;
\.


ALTER TABLE core.comment_addendum ENABLE TRIGGER ALL;

--
-- Data for Name: comment_revision; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.comment_revision DISABLE TRIGGER ALL;

COPY core.comment_revision (id, date_created, comment_id, original_text_content) FROM stdin;
\.


ALTER TABLE core.comment_revision ENABLE TRIGGER ALL;

--
-- Data for Name: display_preference; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.display_preference DISABLE TRIGGER ALL;

COPY core.display_preference (id, user_account_id, last_modified, theme, text_size, hide_links) FROM stdin;
1	1	2022-06-20 14:19:56.571133	light	1	t
\.


ALTER TABLE core.display_preference ENABLE TRIGGER ALL;

--
-- Data for Name: donation_recipient; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.donation_recipient DISABLE TRIGGER ALL;

COPY core.donation_recipient (id, date_created, name, website, tax_id) FROM stdin;
\.


ALTER TABLE core.donation_recipient ENABLE TRIGGER ALL;

--
-- Data for Name: donation_account; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.donation_account DISABLE TRIGGER ALL;

COPY core.donation_account (id, author_id, user_account_id, date_created, date_user_account_assigned, donation_recipient_id) FROM stdin;
\.


ALTER TABLE core.donation_account ENABLE TRIGGER ALL;

--
-- Data for Name: donation_payout; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.donation_payout DISABLE TRIGGER ALL;

COPY core.donation_payout (id, date_created, donation_account_id, donation_recipient_id, amount, receipt) FROM stdin;
\.


ALTER TABLE core.donation_payout ENABLE TRIGGER ALL;

--
-- Data for Name: email_confirmation; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.email_confirmation DISABLE TRIGGER ALL;

COPY core.email_confirmation (id, date_created, user_account_id, email_address, date_confirmed) FROM stdin;
\.


ALTER TABLE core.email_confirmation ENABLE TRIGGER ALL;

--
-- Data for Name: email_notification; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.email_notification DISABLE TRIGGER ALL;

COPY core.email_notification (id, notification_type, mail, bounce, complaint) FROM stdin;
\.


ALTER TABLE core.email_notification ENABLE TRIGGER ALL;

--
-- Data for Name: email_share; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.email_share DISABLE TRIGGER ALL;

COPY core.email_share (id, date_sent, article_id, user_account_id, message) FROM stdin;
\.


ALTER TABLE core.email_share ENABLE TRIGGER ALL;

--
-- Data for Name: email_share_recipient; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.email_share_recipient DISABLE TRIGGER ALL;

COPY core.email_share_recipient (id, email_share_id, email_address, user_account_id, is_successful) FROM stdin;
\.


ALTER TABLE core.email_share_recipient ENABLE TRIGGER ALL;

--
-- Data for Name: extension_installation; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.extension_installation DISABLE TRIGGER ALL;

COPY core.extension_installation (id, "timestamp", installation_id, user_account_id, platform) FROM stdin;
\.


ALTER TABLE core.extension_installation ENABLE TRIGGER ALL;

--
-- Data for Name: extension_removal; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.extension_removal DISABLE TRIGGER ALL;

COPY core.extension_removal (id, "timestamp", installation_id, user_account_id, reason) FROM stdin;
\.


ALTER TABLE core.extension_removal ENABLE TRIGGER ALL;

--
-- Data for Name: following; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.following DISABLE TRIGGER ALL;

COPY core.following (id, follower_user_account_id, followee_user_account_id, date_followed, date_unfollowed, follow_analytics, unfollow_analytics) FROM stdin;
\.


ALTER TABLE core.following ENABLE TRIGGER ALL;

--
-- Data for Name: free_trial_credit; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.free_trial_credit DISABLE TRIGGER ALL;

COPY core.free_trial_credit (id, date_created, user_account_id, credit_trigger, credit_type, amount_credited, amount_remaining) FROM stdin;
1	2022-06-20 14:19:56.571133	1	account_created	article_view	5	2
\.


ALTER TABLE core.free_trial_credit ENABLE TRIGGER ALL;

--
-- Data for Name: new_platform_notification_request; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.new_platform_notification_request DISABLE TRIGGER ALL;

COPY core.new_platform_notification_request (id, date_created, email_address, ip_address, user_agent) FROM stdin;
\.


ALTER TABLE core.new_platform_notification_request ENABLE TRIGGER ALL;

--
-- Data for Name: notification_event; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_event DISABLE TRIGGER ALL;

COPY core.notification_event (id, date_created, type, bulk_email_author_id, bulk_email_subject, bulk_email_body, bulk_email_subscription_status_filter, bulk_email_free_for_life_filter, bulk_email_user_created_after_filter, bulk_email_user_created_before_filter) FROM stdin;
\.


ALTER TABLE core.notification_event ENABLE TRIGGER ALL;

--
-- Data for Name: password_reset_request; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.password_reset_request DISABLE TRIGGER ALL;

COPY core.password_reset_request (id, date_created, user_account_id, email_address, date_completed, auth_service_authentication_id) FROM stdin;
\.


ALTER TABLE core.password_reset_request ENABLE TRIGGER ALL;

--
-- Data for Name: notification_data; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_data DISABLE TRIGGER ALL;

COPY core.notification_data (id, event_id, article_id, comment_id, silent_post_id, following_id, email_confirmation_id, password_reset_request_id) FROM stdin;
\.


ALTER TABLE core.notification_data ENABLE TRIGGER ALL;

--
-- Data for Name: notification_receipt; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_receipt DISABLE TRIGGER ALL;

COPY core.notification_receipt (id, event_id, user_account_id, date_alert_cleared, via_email, via_extension, via_push, event_type) FROM stdin;
\.


ALTER TABLE core.notification_receipt ENABLE TRIGGER ALL;

--
-- Data for Name: notification_interaction; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_interaction DISABLE TRIGGER ALL;

COPY core.notification_interaction (id, receipt_id, channel, action, date_created, url, reply_id) FROM stdin;
\.


ALTER TABLE core.notification_interaction ENABLE TRIGGER ALL;

--
-- Data for Name: notification_preference; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_preference DISABLE TRIGGER ALL;

COPY core.notification_preference (id, user_account_id, last_modified, company_update_via_email, aotd_via_email, aotd_via_extension, aotd_via_push, aotd_digest_via_email, reply_via_email, reply_via_extension, reply_via_push, reply_digest_via_email, loopback_via_email, loopback_via_extension, loopback_via_push, loopback_digest_via_email, post_via_email, post_via_extension, post_via_push, post_digest_via_email, follower_via_email, follower_via_extension, follower_via_push, follower_digest_via_email) FROM stdin;
1	1	2022-06-20 14:19:56.571133	t	t	t	t	never	t	t	t	never	t	t	t	never	t	t	t	never	t	t	t	never
\.


ALTER TABLE core.notification_preference ENABLE TRIGGER ALL;

--
-- Data for Name: notification_push_auth_denial; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_push_auth_denial DISABLE TRIGGER ALL;

COPY core.notification_push_auth_denial (id, date_denied, user_account_id, installation_id, device_name) FROM stdin;
\.


ALTER TABLE core.notification_push_auth_denial ENABLE TRIGGER ALL;

--
-- Data for Name: notification_push_device; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.notification_push_device DISABLE TRIGGER ALL;

COPY core.notification_push_device (id, date_registered, date_unregistered, unregistration_reason, user_account_id, installation_id, name, token) FROM stdin;
\.


ALTER TABLE core.notification_push_device ENABLE TRIGGER ALL;

--
-- Data for Name: share_result; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.share_result DISABLE TRIGGER ALL;

COPY core.share_result (id, date_created, client_type, user_account_id, action, activity_type, completed, error) FROM stdin;
\.


ALTER TABLE core.share_result ENABLE TRIGGER ALL;

--
-- Data for Name: orientation_analytics; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.orientation_analytics DISABLE TRIGGER ALL;

COPY core.orientation_analytics (date_created, user_account_id, tracking_play_count, tracking_skipped, tracking_duration, import_play_count, import_skipped, import_duration, notifications_result, notifications_skipped, notifications_duration, share_result_id, share_skipped, share_duration) FROM stdin;
\.


ALTER TABLE core.orientation_analytics ENABLE TRIGGER ALL;

--
-- Data for Name: page; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.page DISABLE TRIGGER ALL;

COPY core.page (id, article_id, number, word_count, readable_word_count, url) FROM stdin;
1	1	1	2204	2204	https://website.com/the-white-swamphen
2	2	1	2144	2144	https://website.com/gif-pronunciation
3	3	1	1515	1515	https://website.com/the-story-behind-the-song
\.


ALTER TABLE core.page ENABLE TRIGGER ALL;

--
-- Data for Name: provisional_user_account; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.provisional_user_account DISABLE TRIGGER ALL;

COPY core.provisional_user_account (id, date_created, date_merged, merged_user_account_id, creation_analytics) FROM stdin;
\.


ALTER TABLE core.provisional_user_account ENABLE TRIGGER ALL;

--
-- Data for Name: provisional_user_article; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.provisional_user_article DISABLE TRIGGER ALL;

COPY core.provisional_user_article (article_id, provisional_user_account_id, date_created, last_modified, read_state, words_read, date_completed, readable_word_count, analytics, date_viewed) FROM stdin;
\.


ALTER TABLE core.provisional_user_article ENABLE TRIGGER ALL;

--
-- Data for Name: provisional_user_article_progress; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.provisional_user_article_progress DISABLE TRIGGER ALL;

COPY core.provisional_user_article_progress (provisional_user_account_id, article_id, period, words_read, client_type) FROM stdin;
\.


ALTER TABLE core.provisional_user_article_progress ENABLE TRIGGER ALL;

--
-- Data for Name: rating; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.rating DISABLE TRIGGER ALL;

COPY core.rating (id, "timestamp", score, article_id, user_account_id) FROM stdin;
\.


ALTER TABLE core.rating ENABLE TRIGGER ALL;

--
-- Data for Name: source_rule; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.source_rule DISABLE TRIGGER ALL;

COPY core.source_rule (id, hostname, path, priority, action) FROM stdin;
\.


ALTER TABLE core.source_rule ENABLE TRIGGER ALL;

--
-- Data for Name: star; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.star DISABLE TRIGGER ALL;

COPY core.star (user_account_id, article_id, date_starred) FROM stdin;
\.


ALTER TABLE core.star ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_account; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_account DISABLE TRIGGER ALL;

COPY core.subscription_account (provider, provider_account_id, user_account_id, date_created, environment) FROM stdin;
\.


ALTER TABLE core.subscription_account ENABLE TRIGGER ALL;

--
-- Data for Name: subscription; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription DISABLE TRIGGER ALL;

COPY core.subscription (provider, provider_subscription_id, provider_account_id, date_created, latest_receipt) FROM stdin;
\.


ALTER TABLE core.subscription ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_payment_method; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_payment_method DISABLE TRIGGER ALL;

COPY core.subscription_payment_method (provider, provider_payment_method_id, provider_account_id, date_created, wallet, brand, last_four_digits, country, current_version_date) FROM stdin;
\.


ALTER TABLE core.subscription_payment_method ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_default_payment_method; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_default_payment_method DISABLE TRIGGER ALL;

COPY core.subscription_default_payment_method (provider, provider_account_id, date_assigned, date_unassigned, provider_payment_method_id) FROM stdin;
\.


ALTER TABLE core.subscription_default_payment_method ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_level; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_level DISABLE TRIGGER ALL;

COPY core.subscription_level (id, name, amount) FROM stdin;
\.


ALTER TABLE core.subscription_level ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_payment_method_version; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_payment_method_version DISABLE TRIGGER ALL;

COPY core.subscription_payment_method_version (provider, provider_payment_method_id, date_created, event_source, expiration_month, expiration_year) FROM stdin;
\.


ALTER TABLE core.subscription_payment_method_version ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_price; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_price DISABLE TRIGGER ALL;

COPY core.subscription_price (provider, provider_price_id, date_created, level_id, custom_amount) FROM stdin;
\.


ALTER TABLE core.subscription_price ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_period; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_period DISABLE TRIGGER ALL;

COPY core.subscription_period (provider, provider_period_id, provider_subscription_id, provider_price_id, provider_payment_method_id, begin_date, end_date, renewal_grace_period_end_date, date_created, payment_status, date_paid, date_refunded, refund_reason, next_provider_period_id, prorated_price_amount) FROM stdin;
\.


ALTER TABLE core.subscription_period ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_period_distribution; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_period_distribution DISABLE TRIGGER ALL;

COPY core.subscription_period_distribution (provider, provider_period_id, date_created, platform_amount, provider_amount, unknown_author_minutes_read, unknown_author_amount) FROM stdin;
\.


ALTER TABLE core.subscription_period_distribution ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_period_author_distribution; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_period_author_distribution DISABLE TRIGGER ALL;

COPY core.subscription_period_author_distribution (provider, provider_period_id, author_id, minutes_read, amount) FROM stdin;
\.


ALTER TABLE core.subscription_period_author_distribution ENABLE TRIGGER ALL;

--
-- Data for Name: subscription_renewal_status_change; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.subscription_renewal_status_change DISABLE TRIGGER ALL;

COPY core.subscription_renewal_status_change (id, provider, provider_subscription_id, date_created, auto_renew_enabled, provider_price_id, expiration_intent) FROM stdin;
\.


ALTER TABLE core.subscription_renewal_status_change ENABLE TRIGGER ALL;

--
-- Data for Name: twitter_bot_tweet; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.twitter_bot_tweet DISABLE TRIGGER ALL;

COPY core.twitter_bot_tweet (id, handle, date_tweeted, article_id, comment_id, content, tweet_id) FROM stdin;
\.


ALTER TABLE core.twitter_bot_tweet ENABLE TRIGGER ALL;

--
-- Data for Name: user_article; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.user_article DISABLE TRIGGER ALL;

COPY core.user_article (id, article_id, user_account_id, date_created, last_modified, read_state, words_read, date_completed, readable_word_count, analytics, date_viewed, free_trial_credit_id) FROM stdin;
1	1	1	2022-06-20 14:19:56.654304	2022-06-20 14:19:56.660557	{2204}	2204	2022-06-20 14:19:56.660557	2204	{"client": {"mode": null, "type": "desktop/app", "version": null}}	2022-06-20 14:19:56.654304	1
2	2	1	2022-06-20 14:19:56.677306	2022-06-20 14:19:56.678878	{2144}	2144	2022-06-20 14:19:56.678878	2144	{"client": {"mode": null, "type": "desktop/app", "version": null}}	2022-06-20 14:19:56.677306	1
3	3	1	2022-06-20 14:19:56.696818	2022-06-20 14:19:56.698477	{1515}	1515	2022-06-20 14:19:56.698477	1515	{"client": {"mode": null, "type": "desktop/app", "version": null}}	2022-06-20 14:19:56.696818	1
\.


ALTER TABLE core.user_article ENABLE TRIGGER ALL;

--
-- Data for Name: user_article_progress; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.user_article_progress DISABLE TRIGGER ALL;

COPY core.user_article_progress (id, user_account_id, article_id, period, words_read, client_type) FROM stdin;
1	1	1	2022-06-20 14:15:00	2204	"desktop/app"
2	1	2	2022-06-20 14:15:00	2144	"desktop/app"
3	1	3	2022-06-20 14:15:00	1515	"desktop/app"
\.


ALTER TABLE core.user_article_progress ENABLE TRIGGER ALL;

--
-- Data for Name: website_traffic_weekly_total; Type: TABLE DATA; Schema: core; Owner: -
--

ALTER TABLE core.website_traffic_weekly_total DISABLE TRIGGER ALL;

COPY core.website_traffic_weekly_total (week, unique_visit_count, last_updated, unique_authenticated_visit_count) FROM stdin;
\.


ALTER TABLE core.website_traffic_weekly_total ENABLE TRIGGER ALL;

--
-- Name: article_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.article_id_seq', 3, true);


--
-- Name: article_issue_report_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.article_issue_report_id_seq', 1, false);


--
-- Name: auth_service_authentication_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.auth_service_authentication_id_seq', 1, false);


--
-- Name: auth_service_identity_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.auth_service_identity_id_seq', 1, false);


--
-- Name: auth_service_post_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.auth_service_post_id_seq', 1, false);


--
-- Name: auth_service_request_token_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.auth_service_request_token_id_seq', 1, false);


--
-- Name: author_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.author_id_seq', 1, true);


--
-- Name: author_user_account_assignment_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.author_user_account_assignment_id_seq', 1, false);


--
-- Name: captcha_response_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.captcha_response_id_seq', 1, false);


--
-- Name: challenge_award_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.challenge_award_id_seq', 1, false);


--
-- Name: challenge_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.challenge_id_seq', 1, false);


--
-- Name: challenge_response_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.challenge_response_id_seq', 1, false);


--
-- Name: client_error_report_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.client_error_report_id_seq', 1, false);


--
-- Name: comment_addendum_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.comment_addendum_id_seq', 1, false);


--
-- Name: comment_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.comment_id_seq', 3, true);


--
-- Name: comment_revision_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.comment_revision_id_seq', 1, false);


--
-- Name: display_preference_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.display_preference_id_seq', 1, true);


--
-- Name: donation_account_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.donation_account_id_seq', 1, false);


--
-- Name: donation_payout_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.donation_payout_id_seq', 1, false);


--
-- Name: donation_recipient_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.donation_recipient_id_seq', 1, false);


--
-- Name: email_confirmation_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.email_confirmation_id_seq', 1, false);


--
-- Name: email_notification_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.email_notification_id_seq', 1, false);


--
-- Name: email_share_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.email_share_id_seq', 1, false);


--
-- Name: email_share_recipient_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.email_share_recipient_id_seq', 1, false);


--
-- Name: extension_installation_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.extension_installation_id_seq', 1, false);


--
-- Name: extension_removal_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.extension_removal_id_seq', 1, false);


--
-- Name: following_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.following_id_seq', 1, false);


--
-- Name: free_trial_credit_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.free_trial_credit_id_seq', 1, true);


--
-- Name: new_platform_notification_request_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.new_platform_notification_request_id_seq', 1, false);


--
-- Name: notification_data_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_data_id_seq', 1, false);


--
-- Name: notification_event_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_event_id_seq', 1, false);


--
-- Name: notification_interaction_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_interaction_id_seq', 1, false);


--
-- Name: notification_preference_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_preference_id_seq', 1, true);


--
-- Name: notification_push_auth_denial_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_push_auth_denial_id_seq', 1, false);


--
-- Name: notification_push_device_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_push_device_id_seq', 1, false);


--
-- Name: notification_receipt_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.notification_receipt_id_seq', 1, false);


--
-- Name: page_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.page_id_seq', 3, true);


--
-- Name: password_reset_request_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.password_reset_request_id_seq', 1, false);


--
-- Name: provisional_user_account_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.provisional_user_account_id_seq', 1, false);


--
-- Name: rating_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.rating_id_seq', 1, false);


--
-- Name: silent_post_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.silent_post_id_seq', 1, false);


--
-- Name: source_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.source_id_seq', 1, true);


--
-- Name: source_rule_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.source_rule_id_seq', 1, false);


--
-- Name: subscription_renewal_status_change_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.subscription_renewal_status_change_id_seq', 1, false);


--
-- Name: tag_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.tag_id_seq', 1, false);


--
-- Name: twitter_bot_tweet_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.twitter_bot_tweet_id_seq', 1, false);


--
-- Name: user_account_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.user_account_id_seq', 1, true);


--
-- Name: user_article_progress_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.user_article_progress_id_seq', 3, true);


--
-- Name: user_page_id_seq; Type: SEQUENCE SET; Schema: core; Owner: -
--

SELECT pg_catalog.setval('core.user_page_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

