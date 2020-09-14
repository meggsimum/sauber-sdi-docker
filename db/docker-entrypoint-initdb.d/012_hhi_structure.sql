--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.5

-- Started on 2020-09-11 17:17:31

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
-- TOC entry 4926 (class 1262 OID 253015)
-- Name: sauber_data; Type: DATABASE; Schema: -; Owner: sauber_manager
--

CREATE DATABASE sauber_data WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'German_Germany.1252' LC_CTYPE = 'German_Germany.1252';


ALTER DATABASE sauber_data OWNER TO sauber_manager;

\connect sauber_data

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
-- TOC entry 4928 (class 0 OID 0)
-- Dependencies: 4926
-- Name: sauber_data; Type: DATABASE PROPERTIES; Schema: -; Owner: sauber_manager
--

ALTER DATABASE sauber_data SET "timescaledb.restoring" TO 'off';


\connect sauber_data

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
-- TOC entry 28 (class 2615 OID 254611)
-- Name: station_data; Type: SCHEMA; Schema: -; Owner: sauber_manager
--

CREATE SCHEMA station_data;


ALTER SCHEMA station_data OWNER TO sauber_manager;

--
-- TOC entry 3 (class 3079 OID 254612)
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA station_data;


--
-- TOC entry 4930 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';


--
-- TOC entry 30 (class 2615 OID 254597)
-- Name: image_mosaics; Type: SCHEMA; Schema: -; Owner: sauber_manager
--

CREATE SCHEMA image_mosaics;


ALTER SCHEMA image_mosaics OWNER TO sauber_manager;

--
-- TOC entry 29 (class 2615 OID 261525)
-- Name: nrw_pm10_gm1h24h; Type: SCHEMA; Schema: -; Owner: sauber_user
--

CREATE SCHEMA nrw_pm10_gm1h24h;


ALTER SCHEMA nrw_pm10_gm1h24h OWNER TO sauber_user;

--
-- TOC entry 15 (class 2615 OID 255211)
-- Name: raster_data; Type: SCHEMA; Schema: -; Owner: sauber_manager
--

CREATE SCHEMA raster_data;


ALTER SCHEMA raster_data OWNER TO sauber_manager;

--
-- TOC entry 2 (class 3079 OID 253016)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 4932 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;

--
-- TOC entry 1661 (class 1255 OID 258053)
-- Name: createlogentry(jsonb); Type: FUNCTION; Schema: station_data; Owner: sauber_manager
--

CREATE FUNCTION station_data.createlogentry(pload jsonb DEFAULT '{"none": "none"}'::jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    json_payload ALIAS for $1 ;
  BEGIN

   EXECUTE FORMAT (
          '
          insert into station_data.logtable (log_entry) VALUES (%L)
          ', json_payload
           );

  END;
$_$;


ALTER FUNCTION station_data.createlogentry(pload jsonb) OWNER TO sauber_manager;

--
-- TOC entry 1663 (class 1255 OID 279245)
-- Name: get_prediction(text, text, timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: station_data; Owner: postgres
--

CREATE FUNCTION station_data.get_prediction(station_id text, component_id text, start_time timestamp without time zone, end_time timestamp without time zone) RETURNS TABLE(zeitpunkt timestamp without time zone, vorhersagewert double precision, komponente text, station text, geom public.geometry)
    LANGUAGE plpgsql
    AS $_$
BEGIN

RETURN QUERY 
SELECT
	p.date_time,
    p.val,
    c.name_component,
    s.name_station,
    s.wkb_geometry

   FROM station_data.tab_prediction p
     JOIN station_data.lut_component c ON c.idpk_component = p.fk_component
     JOIN station_data.lut_station s ON s.idpk_station = p.fk_station
   WHERE 
     s.name_station like $1
   AND 
     c.name_component like $2
   AND 
     p.date_time >= $3
   AND
     p.date_time <= $4


ORDER BY p.date_time DESC;
END;
$_$;


ALTER FUNCTION station_data.get_prediction(station_id text, component_id text, start_time timestamp without time zone, end_time timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 1662 (class 1255 OID 278392)
-- Name: parse_json(); Type: FUNCTION; Schema: station_data; Owner: postgres
--

CREATE FUNCTION station_data.parse_json() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  payload JSONB;
  message JSONB;
  prediction JSONB;

  j JSONB;
  pred_dt TIMESTAMP;
  pred_val DOUBLE PRECISION;

  message_timestamp TIMESTAMP;
  category_name TEXT;
  message_payload JSONB;

  type_id TEXT;
  unit_id TEXT;
  region_id TEXT;
  station_id TEXT;
  coordinates GEOMETRY;
  interval_len INT;
  creation_time TIMESTAMP;
  prediction_end_time TIMESTAMP;
  prediction_start_time TIMESTAMP;

  time_to_prediction SMALLINT;

BEGIN
	
  DROP TABLE IF EXISTS tmp_json_vals;
  --Create tmp tables to hold parsed values
  CREATE TEMP TABLE tmp_json_vals (
    tmp_dt TIMESTAMP, 
    tmp_val DOUBLE PRECISION, 
    tmp_station TEXT, 
    tmp_geom GEOMETRY,
    tmp_region TEXT, 
    tmp_component TEXT,
    tmp_timetopred SMALLINT
  ) ON COMMIT DROP;	

  --Get last raw JSON FROM  input table
  --This function gets called only after successful JSON insert
  --> Last JSON should be latest input
  -- chance for empty [] input -> function called on outdated json? 
  SELECT json_payload 
    FROM  station_data.raw_input 
    ORDER BY idpk_json DESC 
    LIMIT 1 
  INTO payload;
	
  SELECT json_message 
    FROM  station_data.raw_input 
    ORDER BY idpk_json DESC 
    LIMIT 1 
  INTO message;
  
  -- read all msg params  
  
  message_timestamp := to_timestamp((message->'TIMESTAMP')::bigint);
  category_name := message->'category';
  
  message_payload := message->'payload';
  
  type_id := message_payload->>'type';
  unit_id := message_payload->>'unit';
  region_id := message_payload->>'region';
  interval_len := message_payload->'interval';
  station_id := message_payload->>'stationId';
  coordinates := message_payload->>'coordinates';
  creation_time := to_timestamp((message_payload->'creationTime')::bigint);
  prediction_end_time := to_timestamp((message_payload->'predictionEndTime')::bigint);
  prediction_start_time := to_timestamp((message_payload->'predictionStartTime')::bigint);
  
  --Loop over data
  --Assign json values to variables
  prediction := payload->'prediction';
  
  FOR j IN
  SELECT * FROM jsonb_array_elements(prediction) 
  LOOP
    pred_dt := to_timestamp((j->>'DateTime')::bigint); 
    pred_val := j->>type_id;
    time_to_prediction := extract(EPOCH FROM pred_dt - prediction_start_time)/3600; 
    --RAISE NOTICE E'pred val: %\n pred dt: %\n pred start time: %\n time delta: %\n', pred_val, pred_dt, prediction_start_time, time_to_prediction; 
    INSERT INTO tmp_json_vals (tmp_dt,tmp_val,tmp_station, tmp_geom, tmp_region,tmp_component, tmp_timetopred) VALUES (pred_dt, pred_val, station_id, coordinates, region_id, type_id, time_to_prediction);
  END LOOP;

-- INSERT station data 
  INSERT INTO 
    station_data.lut_station
  (
    name_station,
    address,
    wkb_geometry
  )
  VALUES (
    station_id,
    (SELECT 'Einsteinufer 37 10587 Berlin'), --replace when available
    coordinates
  ) ON CONFLICT (name_station) DO NOTHING;
  
  -- update station last write time
  UPDATE 
    station_data.lut_station 
  SET 
    last_updated = now()
  WHERE name_station like station_id;
  
RAISE NOTICE E' here';
  -- INSERT component metadata 
  INSERT INTO 
    station_data.lut_component
  (
    name_component,
    unit,
    threshold
  )
  VALUES (
    type_id,
	unit_id,
    (SELECT 'dummy_threshold') -- replace when available
  )
  ON CONFLICT (name_component)DO NOTHING;

  -- INSERT region metadata 
  
  INSERT INTO 
    station_data.lut_region
  (
    name_region
  )
  VALUES (
	region_id
  ) 
  ON CONFLICT (name_region) DO NOTHING;	


-- INSERT values 

  WITH 
    lut_stat AS
    (SELECT * FROM  station_data.lut_station)
    ,
    lut_comp AS
    (SELECT * FROM  station_data.lut_component)
    ,
    lut_reg AS
    (SELECT * FROM  station_data.lut_region)

  INSERT INTO 
    station_data.tab_prediction
  (
	val,
    date_time,
    fk_component,
    fk_station,
    fk_region,
    offset_hrs
  )
  
  SELECT tmp_json_vals.tmp_val,tmp_json_vals.tmp_dt, lut_comp.idpk_component, lut_stat.idpk_station, lut_reg.idpk_region, tmp_json_vals.tmp_timetopred
  
  FROM tmp_json_vals
  JOIN lut_stat ON tmp_json_vals.tmp_station = lut_stat.name_station
  JOIN lut_comp on tmp_json_vals.tmp_component = lut_comp.name_component
  JOIN lut_reg on tmp_json_vals.tmp_region =  lut_reg.name_region
  WHERE tmp_json_vals.tmp_dt >= prediction_start_time
  ON CONFLICT (val, date_time, fk_component, fk_station, fk_region) DO NOTHING;

  EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',message);
  
  RETURN FORMAT('Parsed input values for station %L.', station_id);

END;
$$;


ALTER FUNCTION station_data.parse_json() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 303 (class 1259 OID 255078)
-- Name: tab_prediction; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.tab_prediction (
    idpk_value bigint NOT NULL,
    val double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL,
    fk_region integer NOT NULL,
    offset_hrs text NOT NULL
);


ALTER TABLE station_data.tab_prediction OWNER TO sauber_manager;

--
-- TOC entry 314 (class 1259 OID 278206)
-- Name: _hyper_1_13_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_1_13_chunk (
    CONSTRAINT constraint_13 CHECK (((date_time >= '2020-07-16 00:00:00'::timestamp without time zone) AND (date_time < '2020-07-23 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_prediction);


ALTER TABLE _timescaledb_internal._hyper_1_13_chunk OWNER TO sauber_manager;

--
-- TOC entry 317 (class 1259 OID 279175)
-- Name: _hyper_1_16_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_1_16_chunk (
    CONSTRAINT constraint_16 CHECK (((date_time >= '2020-08-06 00:00:00'::timestamp without time zone) AND (date_time < '2020-08-13 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_prediction);


ALTER TABLE _timescaledb_internal._hyper_1_16_chunk OWNER TO sauber_manager;

--
-- TOC entry 307 (class 1259 OID 257999)
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK (((date_time >= '2020-05-28 00:00:00'::timestamp without time zone) AND (date_time < '2020-06-04 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_prediction);


ALTER TABLE _timescaledb_internal._hyper_1_2_chunk OWNER TO sauber_manager;

--
-- TOC entry 310 (class 1259 OID 269941)
-- Name: _hyper_1_8_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_1_8_chunk (
    CONSTRAINT constraint_8 CHECK (((date_time >= '2020-07-23 00:00:00'::timestamp without time zone) AND (date_time < '2020-07-30 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_prediction);


ALTER TABLE _timescaledb_internal._hyper_1_8_chunk OWNER TO sauber_manager;

--
-- TOC entry 311 (class 1259 OID 269966)
-- Name: _hyper_1_9_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_1_9_chunk (
    CONSTRAINT constraint_9 CHECK (((date_time >= '2020-07-30 00:00:00'::timestamp without time zone) AND (date_time < '2020-08-06 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_prediction);


ALTER TABLE _timescaledb_internal._hyper_1_9_chunk OWNER TO sauber_manager;

--
-- TOC entry 301 (class 1259 OID 255073)
-- Name: tab_measurement; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.tab_measurement (
    idpk_prediction bigint NOT NULL,
    val double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL,
    fk_region integer NOT NULL
);


ALTER TABLE station_data.tab_measurement OWNER TO sauber_manager;

--
-- TOC entry 315 (class 1259 OID 278782)
-- Name: _hyper_2_14_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_2_14_chunk (
    CONSTRAINT constraint_14 CHECK (((date_time >= '2020-07-23 00:00:00'::timestamp without time zone) AND (date_time < '2020-07-30 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_measurement);


ALTER TABLE _timescaledb_internal._hyper_2_14_chunk OWNER TO sauber_manager;

--
-- TOC entry 316 (class 1259 OID 278791)
-- Name: _hyper_2_15_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE TABLE _timescaledb_internal._hyper_2_15_chunk (
    CONSTRAINT constraint_15 CHECK (((date_time >= '2020-07-16 00:00:00'::timestamp without time zone) AND (date_time < '2020-07-23 00:00:00'::timestamp without time zone)))
)
INHERITS (station_data.tab_measurement);


ALTER TABLE _timescaledb_internal._hyper_2_15_chunk OWNER TO sauber_manager;

--
-- TOC entry 309 (class 1259 OID 260698)
-- Name: raster_metadata; Type: TABLE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE TABLE image_mosaics.raster_metadata (
    idpk_image integer NOT NULL,
    image_path character varying NOT NULL,
    source_payload jsonb NOT NULL,
    workspace text NOT NULL,
    coverage_store text NOT NULL,
    image_mosaic text NOT NULL,
    is_published smallint DEFAULT 0 NOT NULL,
    CONSTRAINT raster_metadata_chk CHECK ((is_published = ANY (ARRAY[0, 1])))
);


ALTER TABLE image_mosaics.raster_metadata OWNER TO sauber_manager;

--
-- TOC entry 308 (class 1259 OID 260696)
-- Name: raster_metadata_idpk_image_seq; Type: SEQUENCE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE SEQUENCE image_mosaics.raster_metadata_idpk_image_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_mosaics.raster_metadata_idpk_image_seq OWNER TO sauber_manager;

--
-- TOC entry 4936 (class 0 OID 0)
-- Dependencies: 308
-- Name: raster_metadata_idpk_image_seq; Type: SEQUENCE OWNED BY; Schema: image_mosaics; Owner: sauber_manager
--

ALTER SEQUENCE image_mosaics.raster_metadata_idpk_image_seq OWNED BY image_mosaics.raster_metadata.idpk_image;


--
-- TOC entry 313 (class 1259 OID 270455)
-- Name: fc_nrw_pm10_gm1h24h_2020073004; Type: TABLE; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

CREATE TABLE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004 (
    rid integer NOT NULL,
    rast public.raster,
    CONSTRAINT enforce_height_rast CHECK ((public.st_height(rast) = 61)),
    CONSTRAINT enforce_nodata_values_rast CHECK ((public._raster_constraint_nodata_values(rast) = '{NULL}'::numeric[])),
    CONSTRAINT enforce_num_bands_rast CHECK ((public.st_numbands(rast) = 1)),
    CONSTRAINT enforce_out_db_rast CHECK ((public._raster_constraint_out_db(rast) = '{f}'::boolean[])),
    CONSTRAINT enforce_pixel_types_rast CHECK ((public._raster_constraint_pixel_types(rast) = '{32BUI}'::text[])),
    CONSTRAINT enforce_same_alignment_rast CHECK (public.st_samealignment(rast, '0100000000000000000000F03F000000000000F0BF0000000000000000000000000000000000000000000000000000000000000000E864000001000100'::public.raster)),
    CONSTRAINT enforce_scalex_rast CHECK ((round((public.st_scalex(rast))::numeric, 10) = round((1)::numeric, 10))),
    CONSTRAINT enforce_scaley_rast CHECK ((round((public.st_scaley(rast))::numeric, 10) = round((- (1)::numeric), 10))),
    CONSTRAINT enforce_srid_rast CHECK ((public.st_srid(rast) = 25832)),
    CONSTRAINT enforce_width_rast CHECK ((public.st_width(rast) = 36))
);


ALTER TABLE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004 OWNER TO sauber_user;

--
-- TOC entry 312 (class 1259 OID 270453)
-- Name: fc_nrw_pm10_gm1h24h_2020073004_rid_seq; Type: SEQUENCE; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

CREATE SEQUENCE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004_rid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004_rid_seq OWNER TO sauber_user;

--
-- TOC entry 4938 (class 0 OID 0)
-- Dependencies: 312
-- Name: fc_nrw_pm10_gm1h24h_2020073004_rid_seq; Type: SEQUENCE OWNED BY; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

ALTER SEQUENCE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004_rid_seq OWNED BY nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004.rid;


--
-- TOC entry 306 (class 1259 OID 255214)
-- Name: nrw_no2_2020010100; Type: TABLE; Schema: raster_data; Owner: postgres
--

CREATE TABLE raster_data.nrw_no2_2020010100 (
    rid integer NOT NULL,
    rast public.raster,
    filename text,
    CONSTRAINT enforce_height_rast CHECK ((public.st_height(rast) = 43)),
    CONSTRAINT enforce_nodata_values_rast CHECK ((public._raster_constraint_nodata_values(rast) = '{NULL,NULL,NULL,NULL}'::numeric[])),
    CONSTRAINT enforce_num_bands_rast CHECK ((public.st_numbands(rast) = 4)),
    CONSTRAINT enforce_out_db_rast CHECK ((public._raster_constraint_out_db(rast) = '{f,f,f,f}'::boolean[])),
    CONSTRAINT enforce_pixel_types_rast CHECK ((public._raster_constraint_pixel_types(rast) = '{8BUI,8BUI,8BUI,8BUI}'::text[])),
    CONSTRAINT enforce_same_alignment_rast CHECK (public.st_samealignment(rast, '01000000005C4803DD18AD3740CBF58D966FF641C0705F072EF3052F41E8D9AC8A05D2574100000000000000000000000000000000E610000001000100'::public.raster)),
    CONSTRAINT enforce_scalex_rast CHECK ((round((public.st_scalex(rast))::numeric, 10) = round(23.6761606343283, 10))),
    CONSTRAINT enforce_scaley_rast CHECK ((round((public.st_scaley(rast))::numeric, 10) = round((- 35.9252803986706), 10))),
    CONSTRAINT enforce_srid_rast CHECK ((public.st_srid(rast) = 4326)),
    CONSTRAINT enforce_width_rast CHECK ((public.st_width(rast) = 67))
);


ALTER TABLE raster_data.nrw_no2_2020010100 OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 255212)
-- Name: nrw_no2_2020010100_rid_seq; Type: SEQUENCE; Schema: raster_data; Owner: postgres
--

CREATE SEQUENCE raster_data.nrw_no2_2020010100_rid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE raster_data.nrw_no2_2020010100_rid_seq OWNER TO postgres;

--
-- TOC entry 4939 (class 0 OID 0)
-- Dependencies: 305
-- Name: nrw_no2_2020010100_rid_seq; Type: SEQUENCE OWNED BY; Schema: raster_data; Owner: postgres
--

ALTER SEQUENCE raster_data.nrw_no2_2020010100_rid_seq OWNED BY raster_data.nrw_no2_2020010100.rid;


--
-- TOC entry 293 (class 1259 OID 255041)
-- Name: lut_component; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.lut_component (
    idpk_component integer NOT NULL,
    name_component text NOT NULL,
    unit text,
    threshold text
);


ALTER TABLE station_data.lut_component OWNER TO sauber_manager;

--
-- TOC entry 297 (class 1259 OID 255057)
-- Name: lut_station; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.lut_station (
    idpk_station integer NOT NULL,
    name_station text NOT NULL,
    address text,
    last_updated timestamp without time zone,
    wkb_geometry public.geometry(Point,4326) NOT NULL
);


ALTER TABLE station_data.lut_station OWNER TO sauber_manager;

--
-- TOC entry 318 (class 1259 OID 281353)
-- Name: fv_wfs; Type: VIEW; Schema: station_data; Owner: postgres
--

CREATE VIEW station_data.fv_wfs AS
 WITH sel AS (
         SELECT tp.date_time,
            tp.val AS wert,
            tp.fk_component,
            tp.fk_station
           FROM ((station_data.tab_prediction tp
             JOIN station_data.lut_component co_1 ON ((tp.fk_component = co_1.idpk_component)))
             JOIN station_data.lut_station s_1 ON ((tp.fk_station = s_1.idpk_station)))
          ORDER BY tp.date_time DESC
        )
 SELECT row_number() OVER () AS idpk,
    sel.fk_component AS component_id,
    co.name_component AS component_name,
    sel.fk_station AS station_id,
    s.name_station AS station_name,
    json_agg(json_build_object('datetime', sel.date_time, 'val', sel.wert) ORDER BY sel.date_time DESC) AS series,
    s.wkb_geometry AS geom
   FROM ((sel
     JOIN station_data.lut_component co ON ((sel.fk_component = co.idpk_component)))
     JOIN station_data.lut_station s ON ((sel.fk_station = s.idpk_station)))
  GROUP BY s.idpk_station, sel.fk_component, sel.fk_station, co.name_component, s.name_station, s.wkb_geometry;


ALTER TABLE station_data.fv_wfs OWNER TO sauber_manager;

--
-- TOC entry 291 (class 1259 OID 255032)
-- Name: logtable; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.logtable (
    idpk_log integer NOT NULL,
    log_ts timestamp without time zone DEFAULT now() NOT NULL,
    log_entry jsonb NOT NULL
);


ALTER TABLE station_data.logtable OWNER TO sauber_manager;

--
-- TOC entry 292 (class 1259 OID 255039)
-- Name: logtable_idpk_log_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.logtable_idpk_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.logtable_idpk_log_seq OWNER TO sauber_manager;

--
-- TOC entry 4943 (class 0 OID 0)
-- Dependencies: 292
-- Name: logtable_idpk_log_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.logtable_idpk_log_seq OWNED BY station_data.logtable.idpk_log;


--
-- TOC entry 294 (class 1259 OID 255047)
-- Name: lut_component_idpk_component_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.lut_component_idpk_component_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.lut_component_idpk_component_seq OWNER TO sauber_manager;

--
-- TOC entry 4945 (class 0 OID 0)
-- Dependencies: 294
-- Name: lut_component_idpk_component_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.lut_component_idpk_component_seq OWNED BY station_data.lut_component.idpk_component;


--
-- TOC entry 295 (class 1259 OID 255049)
-- Name: lut_region; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.lut_region (
    idpk_region integer NOT NULL,
    name_region text NOT NULL
);


ALTER TABLE station_data.lut_region OWNER TO sauber_manager;

--
-- TOC entry 296 (class 1259 OID 255055)
-- Name: lut_region_idpk_region_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.lut_region_idpk_region_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.lut_region_idpk_region_seq OWNER TO sauber_manager;

--
-- TOC entry 4948 (class 0 OID 0)
-- Dependencies: 296
-- Name: lut_region_idpk_region_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.lut_region_idpk_region_seq OWNED BY station_data.lut_region.idpk_region;


--
-- TOC entry 298 (class 1259 OID 255063)
-- Name: lut_station_idpk_station_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.lut_station_idpk_station_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.lut_station_idpk_station_seq OWNER TO sauber_manager;

--
-- TOC entry 4950 (class 0 OID 0)
-- Dependencies: 298
-- Name: lut_station_idpk_station_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.lut_station_idpk_station_seq OWNED BY station_data.lut_station.idpk_station;


--
-- TOC entry 299 (class 1259 OID 255065)
-- Name: raw_input; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.raw_input (
    idpk_json integer NOT NULL,
    json_payload jsonb NOT NULL,
    json_message jsonb NOT NULL
);


ALTER TABLE station_data.raw_input OWNER TO sauber_manager;

--
-- TOC entry 300 (class 1259 OID 255071)
-- Name: raw_input_idpk_json_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.raw_input_idpk_json_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.raw_input_idpk_json_seq OWNER TO sauber_manager;

--
-- TOC entry 4953 (class 0 OID 0)
-- Dependencies: 300
-- Name: raw_input_idpk_json_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.raw_input_idpk_json_seq OWNED BY station_data.raw_input.idpk_json;


--
-- TOC entry 302 (class 1259 OID 255076)
-- Name: tab_prediction_idpk_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.tab_prediction_idpk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.tab_prediction_idpk_seq OWNER TO sauber_manager;

--
-- TOC entry 4955 (class 0 OID 0)
-- Dependencies: 302
-- Name: tab_prediction_idpk_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.tab_prediction_idpk_seq OWNED BY station_data.tab_measurement.idpk_prediction;


--
-- TOC entry 304 (class 1259 OID 255081)
-- Name: tab_value_idpk_value_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.tab_value_idpk_value_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.tab_value_idpk_value_seq OWNER TO sauber_manager;

--
-- TOC entry 4956 (class 0 OID 0)
-- Dependencies: 304
-- Name: tab_value_idpk_value_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.tab_value_idpk_value_seq OWNED BY station_data.tab_prediction.idpk_value;


--
-- TOC entry 4613 (class 2604 OID 278209)
-- Name: _hyper_1_13_chunk idpk_value; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4619 (class 2604 OID 279178)
-- Name: _hyper_1_16_chunk idpk_value; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4592 (class 2604 OID 258002)
-- Name: _hyper_1_2_chunk idpk_value; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4597 (class 2604 OID 269944)
-- Name: _hyper_1_8_chunk idpk_value; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4599 (class 2604 OID 269969)
-- Name: _hyper_1_9_chunk idpk_value; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4615 (class 2604 OID 278785)
-- Name: _hyper_2_14_chunk idpk_prediction; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_14_chunk ALTER COLUMN idpk_prediction SET DEFAULT nextval('station_data.tab_prediction_idpk_seq'::regclass);


--
-- TOC entry 4617 (class 2604 OID 278794)
-- Name: _hyper_2_15_chunk idpk_prediction; Type: DEFAULT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_15_chunk ALTER COLUMN idpk_prediction SET DEFAULT nextval('station_data.tab_prediction_idpk_seq'::regclass);


--
-- TOC entry 4594 (class 2604 OID 260701)
-- Name: raster_metadata idpk_image; Type: DEFAULT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.raster_metadata ALTER COLUMN idpk_image SET DEFAULT nextval('image_mosaics.raster_metadata_idpk_image_seq'::regclass);


--
-- TOC entry 4601 (class 2604 OID 270458)
-- Name: fc_nrw_pm10_gm1h24h_2020073004 rid; Type: DEFAULT; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

ALTER TABLE ONLY nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004 ALTER COLUMN rid SET DEFAULT nextval('nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004_rid_seq'::regclass);


--
-- TOC entry 4580 (class 2604 OID 255217)
-- Name: nrw_no2_2020010100 rid; Type: DEFAULT; Schema: raster_data; Owner: postgres
--

ALTER TABLE ONLY raster_data.nrw_no2_2020010100 ALTER COLUMN rid SET DEFAULT nextval('raster_data.nrw_no2_2020010100_rid_seq'::regclass);


--
-- TOC entry 4573 (class 2604 OID 255083)
-- Name: logtable idpk_log; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.logtable ALTER COLUMN idpk_log SET DEFAULT nextval('station_data.logtable_idpk_log_seq'::regclass);


--
-- TOC entry 4574 (class 2604 OID 255084)
-- Name: lut_component idpk_component; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_component ALTER COLUMN idpk_component SET DEFAULT nextval('station_data.lut_component_idpk_component_seq'::regclass);


--
-- TOC entry 4575 (class 2604 OID 255085)
-- Name: lut_region idpk_region; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_region ALTER COLUMN idpk_region SET DEFAULT nextval('station_data.lut_region_idpk_region_seq'::regclass);


--
-- TOC entry 4576 (class 2604 OID 255086)
-- Name: lut_station idpk_station; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_station ALTER COLUMN idpk_station SET DEFAULT nextval('station_data.lut_station_idpk_station_seq'::regclass);


--
-- TOC entry 4577 (class 2604 OID 255087)
-- Name: raw_input idpk_json; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.raw_input ALTER COLUMN idpk_json SET DEFAULT nextval('station_data.raw_input_idpk_json_seq'::regclass);


--
-- TOC entry 4578 (class 2604 OID 255088)
-- Name: tab_measurement idpk_prediction; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_measurement ALTER COLUMN idpk_prediction SET DEFAULT nextval('station_data.tab_prediction_idpk_seq'::regclass);


--
-- TOC entry 4579 (class 2604 OID 255089)
-- Name: tab_prediction idpk_value; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_value_idpk_value_seq'::regclass);


--
-- TOC entry 4742 (class 2606 OID 278230)
-- Name: _hyper_1_13_chunk 13_52_tab_prediction_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk
    ADD CONSTRAINT "13_52_tab_prediction_pk" PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4750 (class 2606 OID 278788)
-- Name: _hyper_2_14_chunk 14_53_tab_meas_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_14_chunk
    ADD CONSTRAINT "14_53_tab_meas_pk" PRIMARY KEY (idpk_prediction, date_time);


--
-- TOC entry 4754 (class 2606 OID 278797)
-- Name: _hyper_2_15_chunk 15_54_tab_meas_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_2_15_chunk
    ADD CONSTRAINT "15_54_tab_meas_pk" PRIMARY KEY (idpk_prediction, date_time);


--
-- TOC entry 4758 (class 2606 OID 279199)
-- Name: _hyper_1_16_chunk 16_58_tab_prediction_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk
    ADD CONSTRAINT "16_58_tab_prediction_pk" PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4723 (class 2606 OID 269962)
-- Name: _hyper_1_8_chunk 8_32_tab_prediction_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_32_tab_prediction_pk" PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4731 (class 2606 OID 269987)
-- Name: _hyper_1_9_chunk 9_36_tab_prediction_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk
    ADD CONSTRAINT "9_36_tab_prediction_pk" PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4719 (class 2606 OID 258020)
-- Name: _hyper_1_2_chunk _hyper_1_2_chunk_tab_prediction_pk; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT _hyper_1_2_chunk_tab_prediction_pk PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4721 (class 2606 OID 260708)
-- Name: raster_metadata raster_metadata_pkey; Type: CONSTRAINT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.raster_metadata
    ADD CONSTRAINT raster_metadata_pkey PRIMARY KEY (idpk_image);


--
-- TOC entry 4603 (class 2606 OID 270493)
-- Name: fc_nrw_pm10_gm1h24h_2020073004 enforce_max_extent_rast; Type: CHECK CONSTRAINT; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

ALTER TABLE nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004
    ADD CONSTRAINT enforce_max_extent_rast CHECK ((public.st_envelope(rast) OPERATOR(public.@) '0103000020E8640000010000000500000000000000000000000000000000806EC0000000000000000000000000000000000000000000806F4000000000000000000000000000806F400000000000806EC000000000000000000000000000806EC0'::public.geometry)) NOT VALID;


--
-- TOC entry 4739 (class 2606 OID 270463)
-- Name: fc_nrw_pm10_gm1h24h_2020073004 fc_nrw_pm10_gm1h24h_2020073004_pkey; Type: CONSTRAINT; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

ALTER TABLE ONLY nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004
    ADD CONSTRAINT fc_nrw_pm10_gm1h24h_2020073004_pkey PRIMARY KEY (rid);


--
-- TOC entry 4582 (class 2606 OID 255284)
-- Name: nrw_no2_2020010100 enforce_max_extent_rast; Type: CHECK CONSTRAINT; Schema: raster_data; Owner: postgres
--

ALTER TABLE raster_data.nrw_no2_2020010100
    ADD CONSTRAINT enforce_max_extent_rast CHECK ((public.st_envelope(rast) OPERATOR(public.@) '0103000020E61000000100000005000000705F072EF3052F4173D7122A76C75741705F072EF3052F41E8D9AC8A05D257412FDD240618692F41E8D9AC8A05D257412FDD240618692F4173D7122A76C75741705F072EF3052F4173D7122A76C75741'::public.geometry)) NOT VALID;


--
-- TOC entry 4710 (class 2606 OID 255222)
-- Name: nrw_no2_2020010100 nrw_no2_2020010100_pkey; Type: CONSTRAINT; Schema: raster_data; Owner: postgres
--

ALTER TABLE ONLY raster_data.nrw_no2_2020010100
    ADD CONSTRAINT nrw_no2_2020010100_pkey PRIMARY KEY (rid);


--
-- TOC entry 4685 (class 2606 OID 255091)
-- Name: logtable logtable_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.logtable
    ADD CONSTRAINT logtable_pk PRIMARY KEY (idpk_log);


--
-- TOC entry 4687 (class 2606 OID 255093)
-- Name: lut_component lut_component_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_component
    ADD CONSTRAINT lut_component_pk PRIMARY KEY (idpk_component);


--
-- TOC entry 4690 (class 2606 OID 255095)
-- Name: lut_region lut_region_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_region
    ADD CONSTRAINT lut_region_pk PRIMARY KEY (idpk_region);


--
-- TOC entry 4693 (class 2606 OID 255097)
-- Name: lut_station lut_station_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_station
    ADD CONSTRAINT lut_station_pk PRIMARY KEY (idpk_station);


--
-- TOC entry 4696 (class 2606 OID 255099)
-- Name: raw_input raw_input_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.raw_input
    ADD CONSTRAINT raw_input_pk PRIMARY KEY (idpk_json);


--
-- TOC entry 4700 (class 2606 OID 255101)
-- Name: tab_measurement tab_meas_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_measurement
    ADD CONSTRAINT tab_meas_pk PRIMARY KEY (idpk_prediction, date_time);


--
-- TOC entry 4708 (class 2606 OID 255103)
-- Name: tab_prediction tab_prediction_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT tab_prediction_pk PRIMARY KEY (idpk_value, date_time);


--
-- TOC entry 4743 (class 1259 OID 278231)
-- Name: _hyper_1_13_chunk_idx_dt_desc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_13_chunk_idx_dt_desc ON _timescaledb_internal._hyper_1_13_chunk USING btree (date_time DESC);


--
-- TOC entry 4744 (class 1259 OID 278232)
-- Name: _hyper_1_13_chunk_idx_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_13_chunk_idx_dt_desc_lut_asc ON _timescaledb_internal._hyper_1_13_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4745 (class 1259 OID 281237)
-- Name: _hyper_1_13_chunk_idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_13_chunk_idx_dt_desc_lut_asc_temp ON _timescaledb_internal._hyper_1_13_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4746 (class 1259 OID 281231)
-- Name: _hyper_1_13_chunk_idx_dt_desc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_13_chunk_idx_dt_desc_temp ON _timescaledb_internal._hyper_1_13_chunk USING btree (date_time DESC);


--
-- TOC entry 4747 (class 1259 OID 278233)
-- Name: _hyper_1_13_chunk_idx_uq_val_dt_lut; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_13_chunk_idx_uq_val_dt_lut ON _timescaledb_internal._hyper_1_13_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4748 (class 1259 OID 281243)
-- Name: _hyper_1_13_chunk_idx_uq_val_dt_lut_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_13_chunk_idx_uq_val_dt_lut_temp ON _timescaledb_internal._hyper_1_13_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4759 (class 1259 OID 279200)
-- Name: _hyper_1_16_chunk_idx_dt_desc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_16_chunk_idx_dt_desc ON _timescaledb_internal._hyper_1_16_chunk USING btree (date_time DESC);


--
-- TOC entry 4760 (class 1259 OID 279201)
-- Name: _hyper_1_16_chunk_idx_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_16_chunk_idx_dt_desc_lut_asc ON _timescaledb_internal._hyper_1_16_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4761 (class 1259 OID 281238)
-- Name: _hyper_1_16_chunk_idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_16_chunk_idx_dt_desc_lut_asc_temp ON _timescaledb_internal._hyper_1_16_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4762 (class 1259 OID 281232)
-- Name: _hyper_1_16_chunk_idx_dt_desc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_16_chunk_idx_dt_desc_temp ON _timescaledb_internal._hyper_1_16_chunk USING btree (date_time DESC);


--
-- TOC entry 4763 (class 1259 OID 279202)
-- Name: _hyper_1_16_chunk_idx_uq_val_dt_lut; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_16_chunk_idx_uq_val_dt_lut ON _timescaledb_internal._hyper_1_16_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4764 (class 1259 OID 281244)
-- Name: _hyper_1_16_chunk_idx_uq_val_dt_lut_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_16_chunk_idx_uq_val_dt_lut_temp ON _timescaledb_internal._hyper_1_16_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4712 (class 1259 OID 258021)
-- Name: _hyper_1_2_chunk_idx_dt_desc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_2_chunk_idx_dt_desc ON _timescaledb_internal._hyper_1_2_chunk USING btree (date_time DESC);


--
-- TOC entry 4713 (class 1259 OID 258022)
-- Name: _hyper_1_2_chunk_idx_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_2_chunk_idx_dt_desc_lut_asc ON _timescaledb_internal._hyper_1_2_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4714 (class 1259 OID 281234)
-- Name: _hyper_1_2_chunk_idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_2_chunk_idx_dt_desc_lut_asc_temp ON _timescaledb_internal._hyper_1_2_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4715 (class 1259 OID 281228)
-- Name: _hyper_1_2_chunk_idx_dt_desc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_2_chunk_idx_dt_desc_temp ON _timescaledb_internal._hyper_1_2_chunk USING btree (date_time DESC);


--
-- TOC entry 4716 (class 1259 OID 258023)
-- Name: _hyper_1_2_chunk_idx_uq_val_dt_lut; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_2_chunk_idx_uq_val_dt_lut ON _timescaledb_internal._hyper_1_2_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4717 (class 1259 OID 281240)
-- Name: _hyper_1_2_chunk_idx_uq_val_dt_lut_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_2_chunk_idx_uq_val_dt_lut_temp ON _timescaledb_internal._hyper_1_2_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4724 (class 1259 OID 269963)
-- Name: _hyper_1_8_chunk_idx_dt_desc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_8_chunk_idx_dt_desc ON _timescaledb_internal._hyper_1_8_chunk USING btree (date_time DESC);


--
-- TOC entry 4725 (class 1259 OID 269964)
-- Name: _hyper_1_8_chunk_idx_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_8_chunk_idx_dt_desc_lut_asc ON _timescaledb_internal._hyper_1_8_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4726 (class 1259 OID 281235)
-- Name: _hyper_1_8_chunk_idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_8_chunk_idx_dt_desc_lut_asc_temp ON _timescaledb_internal._hyper_1_8_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4727 (class 1259 OID 281229)
-- Name: _hyper_1_8_chunk_idx_dt_desc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_8_chunk_idx_dt_desc_temp ON _timescaledb_internal._hyper_1_8_chunk USING btree (date_time DESC);


--
-- TOC entry 4728 (class 1259 OID 269965)
-- Name: _hyper_1_8_chunk_idx_uq_val_dt_lut; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_8_chunk_idx_uq_val_dt_lut ON _timescaledb_internal._hyper_1_8_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4729 (class 1259 OID 281241)
-- Name: _hyper_1_8_chunk_idx_uq_val_dt_lut_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_8_chunk_idx_uq_val_dt_lut_temp ON _timescaledb_internal._hyper_1_8_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4732 (class 1259 OID 269988)
-- Name: _hyper_1_9_chunk_idx_dt_desc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_9_chunk_idx_dt_desc ON _timescaledb_internal._hyper_1_9_chunk USING btree (date_time DESC);


--
-- TOC entry 4733 (class 1259 OID 269989)
-- Name: _hyper_1_9_chunk_idx_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_9_chunk_idx_dt_desc_lut_asc ON _timescaledb_internal._hyper_1_9_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4734 (class 1259 OID 281236)
-- Name: _hyper_1_9_chunk_idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_9_chunk_idx_dt_desc_lut_asc_temp ON _timescaledb_internal._hyper_1_9_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4735 (class 1259 OID 281230)
-- Name: _hyper_1_9_chunk_idx_dt_desc_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_1_9_chunk_idx_dt_desc_temp ON _timescaledb_internal._hyper_1_9_chunk USING btree (date_time DESC);


--
-- TOC entry 4736 (class 1259 OID 269990)
-- Name: _hyper_1_9_chunk_idx_uq_val_dt_lut; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_9_chunk_idx_uq_val_dt_lut ON _timescaledb_internal._hyper_1_9_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4737 (class 1259 OID 281242)
-- Name: _hyper_1_9_chunk_idx_uq_val_dt_lut_temp; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE UNIQUE INDEX _hyper_1_9_chunk_idx_uq_val_dt_lut_temp ON _timescaledb_internal._hyper_1_9_chunk USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4751 (class 1259 OID 278789)
-- Name: _hyper_2_14_chunk_idx_meas_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_2_14_chunk_idx_meas_dt_desc_lut_asc ON _timescaledb_internal._hyper_2_14_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4752 (class 1259 OID 278790)
-- Name: _hyper_2_14_chunk_tab_meas_date_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_2_14_chunk_tab_meas_date_time_idx ON _timescaledb_internal._hyper_2_14_chunk USING btree (date_time DESC);


--
-- TOC entry 4755 (class 1259 OID 278798)
-- Name: _hyper_2_15_chunk_idx_meas_dt_desc_lut_asc; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_2_15_chunk_idx_meas_dt_desc_lut_asc ON _timescaledb_internal._hyper_2_15_chunk USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4756 (class 1259 OID 278799)
-- Name: _hyper_2_15_chunk_tab_meas_date_time_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: sauber_manager
--

CREATE INDEX _hyper_2_15_chunk_tab_meas_date_time_idx ON _timescaledb_internal._hyper_2_15_chunk USING btree (date_time DESC);


--
-- TOC entry 4740 (class 1259 OID 270482)
-- Name: fc_nrw_pm10_gm1h24h_2020073004_st_convexhull_idx; Type: INDEX; Schema: nrw_pm10_gm1h24h; Owner: sauber_user
--

CREATE INDEX fc_nrw_pm10_gm1h24h_2020073004_st_convexhull_idx ON nrw_pm10_gm1h24h.fc_nrw_pm10_gm1h24h_2020073004 USING gist (public.st_convexhull(rast));


--
-- TOC entry 4711 (class 1259 OID 255273)
-- Name: nrw_no2_2020010100_st_convexhull_idx; Type: INDEX; Schema: raster_data; Owner: postgres
--

CREATE INDEX nrw_no2_2020010100_st_convexhull_idx ON raster_data.nrw_no2_2020010100 USING gist (public.st_convexhull(rast));


--
-- TOC entry 4701 (class 1259 OID 255104)
-- Name: idx_dt_desc; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc ON station_data.tab_prediction USING btree (date_time DESC);


--
-- TOC entry 4702 (class 1259 OID 255105)
-- Name: idx_dt_desc_lut_asc; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc_lut_asc ON station_data.tab_prediction USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4703 (class 1259 OID 281233)
-- Name: idx_dt_desc_lut_asc_temp; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc_lut_asc_temp ON station_data.tab_prediction USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4704 (class 1259 OID 281227)
-- Name: idx_dt_desc_temp; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc_temp ON station_data.tab_prediction USING btree (date_time DESC);


--
-- TOC entry 4697 (class 1259 OID 255106)
-- Name: idx_meas_dt_desc_lut_asc; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_meas_dt_desc_lut_asc ON station_data.tab_measurement USING btree (date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4705 (class 1259 OID 255107)
-- Name: idx_uq_val_dt_lut; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE UNIQUE INDEX idx_uq_val_dt_lut ON station_data.tab_prediction USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4706 (class 1259 OID 281239)
-- Name: idx_uq_val_dt_lut_temp; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE UNIQUE INDEX idx_uq_val_dt_lut_temp ON station_data.tab_prediction USING btree (val, date_time DESC, fk_component, fk_station, fk_region);


--
-- TOC entry 4698 (class 1259 OID 255140)
-- Name: tab_meas_date_time_idx; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX tab_meas_date_time_idx ON station_data.tab_measurement USING btree (date_time DESC);


--
-- TOC entry 4688 (class 1259 OID 258044)
-- Name: uq_name_component; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE UNIQUE INDEX uq_name_component ON station_data.lut_component USING btree (name_component);


--
-- TOC entry 4691 (class 1259 OID 258043)
-- Name: uq_name_region; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE UNIQUE INDEX uq_name_region ON station_data.lut_region USING btree (name_region);


--
-- TOC entry 4694 (class 1259 OID 258042)
-- Name: uq_name_station; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE UNIQUE INDEX uq_name_station ON station_data.lut_station USING btree (name_station);

ALTER TABLE station_data.lut_station CLUSTER ON uq_name_station;


--
-- TOC entry 4784 (class 2620 OID 255138)
-- Name: tab_prediction ts_insert_blocker; Type: TRIGGER; Schema: station_data; Owner: sauber_manager
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON station_data.tab_prediction FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 4783 (class 2620 OID 255139)
-- Name: tab_measurement ts_insert_blocker; Type: TRIGGER; Schema: station_data; Owner: sauber_manager
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON station_data.tab_measurement FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


--
-- TOC entry 4777 (class 2606 OID 278214)
-- Name: _hyper_1_13_chunk 13_49_fk_lut_component; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk
    ADD CONSTRAINT "13_49_fk_lut_component" FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4778 (class 2606 OID 278219)
-- Name: _hyper_1_13_chunk 13_50_fk_lut_region; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk
    ADD CONSTRAINT "13_50_fk_lut_region" FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4779 (class 2606 OID 278224)
-- Name: _hyper_1_13_chunk 13_51_fk_lut_station; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_13_chunk
    ADD CONSTRAINT "13_51_fk_lut_station" FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4780 (class 2606 OID 279183)
-- Name: _hyper_1_16_chunk 16_55_fk_lut_component; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk
    ADD CONSTRAINT "16_55_fk_lut_component" FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4781 (class 2606 OID 279188)
-- Name: _hyper_1_16_chunk 16_56_fk_lut_region; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk
    ADD CONSTRAINT "16_56_fk_lut_region" FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4782 (class 2606 OID 279193)
-- Name: _hyper_1_16_chunk 16_57_fk_lut_station; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_16_chunk
    ADD CONSTRAINT "16_57_fk_lut_station" FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4768 (class 2606 OID 258004)
-- Name: _hyper_1_2_chunk 2_5_fk_lut_component; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_5_fk_lut_component" FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4769 (class 2606 OID 258009)
-- Name: _hyper_1_2_chunk 2_6_fk_lut_region; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_6_fk_lut_region" FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4770 (class 2606 OID 258014)
-- Name: _hyper_1_2_chunk 2_7_fk_lut_station; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_7_fk_lut_station" FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4771 (class 2606 OID 269946)
-- Name: _hyper_1_8_chunk 8_29_fk_lut_component; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_29_fk_lut_component" FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4772 (class 2606 OID 269951)
-- Name: _hyper_1_8_chunk 8_30_fk_lut_region; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_30_fk_lut_region" FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4773 (class 2606 OID 269956)
-- Name: _hyper_1_8_chunk 8_31_fk_lut_station; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_31_fk_lut_station" FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4774 (class 2606 OID 269971)
-- Name: _hyper_1_9_chunk 9_33_fk_lut_component; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk
    ADD CONSTRAINT "9_33_fk_lut_component" FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4775 (class 2606 OID 269976)
-- Name: _hyper_1_9_chunk 9_34_fk_lut_region; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk
    ADD CONSTRAINT "9_34_fk_lut_region" FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4776 (class 2606 OID 269981)
-- Name: _hyper_1_9_chunk 9_35_fk_lut_station; Type: FK CONSTRAINT; Schema: _timescaledb_internal; Owner: sauber_manager
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_9_chunk
    ADD CONSTRAINT "9_35_fk_lut_station" FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4765 (class 2606 OID 255113)
-- Name: tab_prediction fk_lut_component; Type: FK CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_component FOREIGN KEY (fk_component) REFERENCES station_data.lut_component(idpk_component);


--
-- TOC entry 4766 (class 2606 OID 255123)
-- Name: tab_prediction fk_lut_region; Type: FK CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_region FOREIGN KEY (fk_region) REFERENCES station_data.lut_region(idpk_region);


--
-- TOC entry 4767 (class 2606 OID 255133)
-- Name: tab_prediction fk_lut_station; Type: FK CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT fk_lut_station FOREIGN KEY (fk_station) REFERENCES station_data.lut_station(idpk_station);


--
-- TOC entry 4927 (class 0 OID 0)
-- Dependencies: 4926
-- Name: DATABASE sauber_data; Type: ACL; Schema: -; Owner: sauber_manager
--




--
-- TOC entry 4929 (class 0 OID 0)
-- Dependencies: 28
-- Name: SCHEMA station_data; Type: ACL; Schema: -; Owner: sauber_manager
--




--
-- TOC entry 4931 (class 0 OID 0)
-- Dependencies: 30
-- Name: SCHEMA image_mosaics; Type: ACL; Schema: -; Owner: sauber_manager
--




--
-- TOC entry 4933 (class 0 OID 0)
-- Dependencies: 1662
-- Name: FUNCTION parse_json(); Type: ACL; Schema: station_data; Owner: postgres
--




--
-- TOC entry 4934 (class 0 OID 0)
-- Dependencies: 303
-- Name: TABLE tab_prediction; Type: ACL; Schema: station_data; Owner: sauber_manager
--





--
-- TOC entry 4935 (class 0 OID 0)
-- Dependencies: 309
-- Name: TABLE raster_metadata; Type: ACL; Schema: image_mosaics; Owner: sauber_manager
--




--
-- TOC entry 4937 (class 0 OID 0)
-- Dependencies: 308
-- Name: SEQUENCE raster_metadata_idpk_image_seq; Type: ACL; Schema: image_mosaics; Owner: sauber_manager
--




--
-- TOC entry 4940 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE lut_component; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4941 (class 0 OID 0)
-- Dependencies: 297
-- Name: TABLE lut_station; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4942 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE logtable; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4944 (class 0 OID 0)
-- Dependencies: 292
-- Name: SEQUENCE logtable_idpk_log_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4946 (class 0 OID 0)
-- Dependencies: 294
-- Name: SEQUENCE lut_component_idpk_component_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4947 (class 0 OID 0)
-- Dependencies: 295
-- Name: TABLE lut_region; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4949 (class 0 OID 0)
-- Dependencies: 296
-- Name: SEQUENCE lut_region_idpk_region_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4951 (class 0 OID 0)
-- Dependencies: 298
-- Name: SEQUENCE lut_station_idpk_station_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4952 (class 0 OID 0)
-- Dependencies: 299
-- Name: TABLE raw_input; Type: ACL; Schema: station_data; Owner: sauber_manager
--





--
-- TOC entry 4954 (class 0 OID 0)
-- Dependencies: 300
-- Name: SEQUENCE raw_input_idpk_json_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




--
-- TOC entry 4957 (class 0 OID 0)
-- Dependencies: 304
-- Name: SEQUENCE tab_value_idpk_value_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--




-- Completed on 2020-09-11 17:17:34

--
-- PostgreSQL database dump complete
--

