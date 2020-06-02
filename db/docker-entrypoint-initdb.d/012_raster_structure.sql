SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


CREATE DATABASE raster_data WITH TEMPLATE = template1;
ALTER DATABASE raster_data OWNER TO sauber_manager;

\c raster_data

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;

CREATE SCHEMA image_mosaics;
ALTER SCHEMA image_mosaics OWNER TO sauber_manager;

CREATE TABLE IF NOT EXISTS imagemosaic_test.tab_log (
	idpk_image serial NOT NULL,
	rel_path varchar NULL,
	source_payload jsonb NULL,
	name_mosaic varchar NULL,
	is_published int2 NULL DEFAULT 0,
	CONSTRAINT tab_log_chk CHECK ((is_published = ANY (ARRAY[0, 1]))),
	CONSTRAINT tab_log_pkey PRIMARY KEY (idpk_image)
);
GRANT SELECT ON imagemosaic_test.tab_log TO anon;
GRANT INSERT (is_published) ON imagemosaic_test.tab_log TO anon;