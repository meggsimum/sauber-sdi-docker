SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


CREATE DATABASE sauber_data WITH TEMPLATE = template0;
ALTER DATABASE sauber_data OWNER TO sauber_manager;

\c sauber_data

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;

CREATE SCHEMA image_mosaics;
ALTER SCHEMA image_mosaics OWNER TO sauber_manager;

CREATE TABLE IF NOT EXISTS image_mosaics.raster_metadata (
	idpk_image serial NOT NULL,
	rel_path varchar NULL,
	source_payload jsonb NULL,
	name_mosaic varchar NULL,
	is_published int2 NULL DEFAULT 0,
	CONSTRAINT raster_metadata_chk CHECK ((is_published = ANY (ARRAY[0, 1]))),
	CONSTRAINT raster_metadata_pkey PRIMARY KEY (idpk_image)
);
ALTER TABLE image_mosaics.raster_metadata OWNER TO sauber_manager;

CREATE SCHEMA IF NOT EXISTS station_data;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA station_data;
--SELECT station_data.timescaledb_pre_restore();
--ALTER DATABASE sauber_data SET timescaledb.restoring='on';

ALTER SCHEMA station_data OWNER TO sauber_manager;

CREATE TABLE station_data.logtable (
    idpk_log integer NOT NULL,
    log_ts timestamp without time zone DEFAULT now() NOT NULL,
    log_entry jsonb NOT NULL
);

ALTER TABLE station_data.logtable OWNER TO sauber_manager;

CREATE SEQUENCE station_data.logtable_idpk_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.logtable_idpk_log_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.logtable_idpk_log_seq OWNED BY station_data.logtable.idpk_log;

CREATE TABLE station_data.lut_component (
    idpk_component integer NOT NULL,
    name_component text NOT NULL,
    unit text,
    threshold text
);

ALTER TABLE station_data.lut_component OWNER TO sauber_manager;

CREATE SEQUENCE station_data.lut_component_idpk_component_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.lut_component_idpk_component_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.lut_component_idpk_component_seq OWNED BY station_data.lut_component.idpk_component;

CREATE TABLE station_data.lut_region (
    idpk_region integer NOT NULL,
    name_region text NOT NULL,
    wkb_geometry public.geometry NOT NULL
);

ALTER TABLE station_data.lut_region OWNER TO sauber_manager;

CREATE SEQUENCE station_data.lut_region_idpk_region_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.lut_region_idpk_region_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.lut_region_idpk_region_seq OWNED BY station_data.lut_region.idpk_region;

CREATE TABLE station_data.lut_station (
    idpk_station integer NOT NULL,
    name_station text NOT NULL,
    address text,
    last_updated timestamp without time zone,
    wkb_geometry public.geometry NOT NULL
);

ALTER TABLE station_data.lut_station OWNER TO sauber_manager;

CREATE SEQUENCE station_data.lut_station_idpk_station_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.lut_station_idpk_station_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.lut_station_idpk_station_seq OWNED BY station_data.lut_station.idpk_station;

CREATE TABLE station_data.raw_input (
    idpk_json integer NOT NULL,
    json_in jsonb NOT NULL
);

ALTER TABLE station_data.raw_input OWNER TO sauber_manager;

CREATE SEQUENCE station_data.raw_input_idpk_json_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.raw_input_idpk_json_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.raw_input_idpk_json_seq OWNED BY station_data.raw_input.idpk_json;

CREATE TABLE station_data.tab_prediction (
    idpk_prediction bigint NOT NULL,
    value double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL,
    fk_region integer NOT NULL
);

ALTER TABLE station_data.tab_prediction OWNER TO sauber_manager;

CREATE SEQUENCE station_data.tab_prediction_idpk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.tab_prediction_idpk_seq OWNER TO sauber_manager;

ALTER SEQUENCE station_data.tab_prediction_idpk_seq OWNED BY station_data.tab_prediction.idpk_prediction;

CREATE TABLE station_data.tab_value (
    idpk_value bigint NOT NULL,
    value double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL,
    fk_region integer NOT NULL
);

ALTER TABLE station_data.tab_value OWNER TO sauber_manager;

CREATE SEQUENCE station_data.tab_value_idpk_value_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE station_data.tab_value_idpk_value_seq OWNER TO sauber_manager;
ALTER SEQUENCE station_data.tab_value_idpk_value_seq OWNED BY station_data.tab_value.idpk_value;

ALTER TABLE ONLY station_data.logtable ALTER COLUMN idpk_log SET DEFAULT nextval('station_data.logtable_idpk_log_seq'::regclass);
ALTER TABLE ONLY station_data.lut_component ALTER COLUMN idpk_component SET DEFAULT nextval('station_data.lut_component_idpk_component_seq'::regclass);
ALTER TABLE ONLY station_data.lut_region ALTER COLUMN idpk_region SET DEFAULT nextval('station_data.lut_region_idpk_region_seq'::regclass);
ALTER TABLE ONLY station_data.lut_station ALTER COLUMN idpk_station SET DEFAULT nextval('station_data.lut_station_idpk_station_seq'::regclass);
ALTER TABLE ONLY station_data.raw_input ALTER COLUMN idpk_json SET DEFAULT nextval('station_data.raw_input_idpk_json_seq'::regclass);
ALTER TABLE ONLY station_data.tab_prediction ALTER COLUMN idpk_prediction SET DEFAULT nextval('station_data.tab_prediction_idpk_seq'::regclass);
ALTER TABLE ONLY station_data.tab_value ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);

ALTER TABLE ONLY station_data.logtable
    ADD CONSTRAINT logtable_pk PRIMARY KEY (idpk_log);
ALTER TABLE ONLY station_data.lut_component
    ADD CONSTRAINT lut_component_pk PRIMARY KEY (idpk_component);
ALTER TABLE ONLY station_data.lut_region
    ADD CONSTRAINT lut_region_pk PRIMARY KEY (idpk_region);
ALTER TABLE ONLY station_data.lut_station
    ADD CONSTRAINT lut_station_pk PRIMARY KEY (idpk_station);
ALTER TABLE ONLY station_data.raw_input
    ADD CONSTRAINT raw_input_pk PRIMARY KEY (idpk_json);
ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT tab_prediction_pk PRIMARY KEY (idpk_prediction, date_time);
ALTER TABLE ONLY station_data.tab_value
    ADD CONSTRAINT tab_value_pk PRIMARY KEY (idpk_value, date_time);

CREATE INDEX idx_dt_desc ON station_data.tab_value USING btree (date_time DESC);
CREATE INDEX idx_dt_desc_lut_asc ON station_data.tab_value USING btree (date_time DESC, fk_component, fk_station, fk_region);
CREATE INDEX idx_pred_dt_desc_lut_asc ON station_data.tab_prediction USING btree (date_time DESC, fk_component, fk_station, fk_region);
CREATE UNIQUE INDEX idx_uq_val_dt_lut ON station_data.tab_value USING btree (value, date_time DESC, fk_component, fk_station, fk_region);

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_component FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);
ALTER TABLE ONLY station_data.tab_value
    ADD CONSTRAINT fk_lut_component FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);
ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_region FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);
ALTER TABLE ONLY station_data.tab_value
    ADD CONSTRAINT fk_lut_region FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);
ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_station FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);
ALTER TABLE ONLY station_data.tab_value
    ADD CONSTRAINT fk_lut_station FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);

SELECT station_data.timescaledb_post_restore();
ALTER DATABASE sauber_data SET timescaledb.restoring='off';
ALTER DATABASE sauber_data SET timescaledb.telemetry_level='off';

SELECT station_data.create_hypertable('station_data.tab_value'::regclass, 'date_time'::name, if_not_exists => TRUE);
SELECT station_data.create_hypertable('station_data.tab_prediction'::regclass, 'date_time'::name, if_not_exists => TRUE);