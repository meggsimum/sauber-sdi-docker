--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

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

CREATE DATABASE sauber_data;
\c sauber_data

--
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data';

--
-- Name: image_mosaics; Type: SCHEMA; Schema: -; Owner: sauber_manager
--

CREATE SCHEMA image_mosaics;


ALTER SCHEMA image_mosaics OWNER TO sauber_manager;

--
-- Name: station_data; Type: SCHEMA; Schema: -; Owner: sauber_manager
--

CREATE SCHEMA station_data;


ALTER SCHEMA station_data OWNER TO sauber_manager;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgis_raster; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;


--
-- Name: EXTENSION postgis_raster; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_raster IS 'PostGIS raster types and functions';


--
-- Name: createlogentry(jsonb); Type: FUNCTION; Schema: station_data; Owner: sauber_manager
--

CREATE FUNCTION station_data.createlogentry(pload jsonb DEFAULT '{"none": "none"}'::jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $_$

  DECLARE

    json_payload ALIAS for $1 ;

  BEGIN

   EXECUTE FORMAT (
          'insert into station_data.logtable (log_entry) VALUES (%L)', json_payload
           );
  END;

$_$;


ALTER FUNCTION station_data.createlogentry(pload jsonb) OWNER TO sauber_manager;

--
-- Name: lanuv_parse(text); Type: FUNCTION; Schema: station_data; Owner: sauber_manager
--

CREATE OR REPLACE FUNCTION station_data.lanuv_parse(input_ts text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE 

  i RECORD;
    ts TIMESTAMP;
   
    logentry_payload JSONB;
    counter INT;

BEGIN

  ts := input_ts::timestamp;

  CREATE TEMP TABLE tmp (
      val double precision, 
      date_time timestamp, 
      component text, 
      station text 
      )
    ON COMMIT DROP ;

  -- INSERT station data 
   INSERT INTO 
     station_data.lut_station
     (
      station_name,
      station_code, 
      last_updated
     )
   SELECT 
      station_name,
      station_code,
      now()
   FROM station_data.input_lanuv rm
   ON CONFLICT (station_code) DO NOTHING;
   
   UPDATE station_data.lut_station
   SET last_updated = now()
   FROM station_data.input_lanuv inp
   WHERE lut_station.station_name = inp.station_name;
   
      
  FOR i in (SELECT * FROM station_data.input_lanuv) LOOP
    
      --RAISE NOTICE 'code:%, o3:%, so2:% pm10:% ', i.station_code, i.o3_val, i.so2_val, i.pm10_val;
    
    INSERT INTO tmp (val, date_time,component,station)
    SELECT i.o3_val::double precision, ts ,'O3_AM1H', i.station_code
    WHERE i.o3_val IS NOT NULL;
     
    INSERT INTO tmp (val, date_time,component,station)
    SELECT   i.so2_val::double precision, ts ,'SO2_AM1H', i.station_code
    WHERE i.so2_val IS NOT NULL;
      
    INSERT INTO tmp (val, date_time,component,station)
    SELECT   i.pm10_val::double precision, ts ,'PM10_GM1H24H', i.station_code
    WHERE i.pm10_val IS NOT NULL;
    
    INSERT INTO tmp (val, date_time,component,station)
    SELECT i.no2_val::double precision, ts ,'NO2_AM1H', i.station_code
    WHERE i.no2_val IS NOT NULL;

  END LOOP;
  
    SELECT COUNT(val) FROM tmp INTO counter;
 
  WITH 
      lut_stat AS
      (SELECT * FROM  station_data.lut_station)
      ,
      lut_comp AS
      (SELECT * FROM  station_data.lut_component)

  INSERT INTO 
      station_data.tab_measurement 
    (
      val,
      date_time,
      fk_component,
      fk_station
    )
    
    SELECT 
      tmp.val, 
      tmp.date_time, 
      lut_comp.idpk_component, 
      lut_stat.idpk_station
    
    FROM tmp
    JOIN lut_stat ON tmp.station = lut_stat.station_code
    JOIN lut_comp on tmp.component = lut_comp.component_name
    ON CONFLICT (date_time, fk_component, fk_station) 
    DO NOTHING;
   
   TRUNCATE TABLE station_data.input_lanuv;

   logentry_payload = '{"source":"lanuv","timestamp":"'||ts||'", "n_vals":"'||counter||'"}';
   EXECUTE FORMAT('SELECT station_data.createlogentry(%L)',logentry_payload);
   RAISE NOTICE 'Finished parsing % values (incl. NULL) from LANUV at %.', counter, now();

END;
$function$
;



ALTER FUNCTION station_data.lanuv_parse(input_ts text) OWNER TO sauber_manager;

--
-- Name: lubw_parse(); Type: FUNCTION; Schema: station_data; Owner: sauber_manager
--

CREATE OR REPLACE FUNCTION station_data.lubw_parse()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    myxml XML;
        
    messstelle TEXT;
    ms_name TEXT;
    ms_kurzname TEXT;
    ms_eu TEXT;
    ms_nuts TEXT;
    ms_hw INTEGER;
    ms_rw INTEGER;
    ms_abrufzeit TEXT;
    
    datentyp TEXT;
    ad_name TEXT;
    
    k_name TEXT;
    k_kurzname TEXT;
    k_kompkenn INTEGER;
    k_nachweisgrenze TEXT;
    k_einheit TEXT;
   
  mess_tag TEXT;    
    time_stamp TIMESTAMP;
    curr_hour TIME := '23:59:59';
    
    wert NUMERIC;    
    i XML;
    zaehler INTEGER;
    logentry_payload JSONB;

BEGIN
  
    CREATE TEMP TABLE output_tmp (
        ms_eu TEXT,
        ad_name TEXT,
        ko_name TEXT,
        zeit TIMESTAMP,
        werte numeric
    )
    ON COMMIT DROP;

    SELECT xml FROM station_data.input_lubw INTO myxml;

  FOREACH messstelle IN ARRAY xpath('//Messstelle/@Name', myxml) LOOP
    FOREACH i IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']', myxml) LOOP
    
            ms_name := messstelle;  
            ms_kurzname := (xpath('.//@KurzName', i))[1];           
            ms_eu := (xpath('.//@EUKenn', i))[1];
            ms_nuts := (xpath('.//@NUTS', i))[1];
            ms_rw := (xpath('.//@RW', i))[1];
            ms_hw := (xpath('.//@HW', i))[1];
      ms_abrufzeit := (xpath('.//@AbrufZeiger', i))[1];

            INSERT INTO station_data.lut_station (station_code, station_name, eu_id, nuts_id, last_updated, wkb_geometry)
                VALUES ( ms_kurzname, ms_name, ms_eu, ms_nuts, now(),
                        st_transform(st_setsrid(st_makepoint(ms_rw, ms_hw),31467), 3035)::public.geometry(POINT,3035)
                       ) 
                ON CONFLICT DO NOTHING;


            FOREACH datentyp IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp/@AD-Name', myxml) LOOP
                FOREACH i IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']', myxml) LOOP
                    
                    ad_name := datentyp;
                    k_name := (xpath('.//Komponente/@Name', i))[1];      
                    k_kurzname := (xpath('.//Komponente/@KurzName', i))[1];
                    k_kompkenn := (xpath('.//Komponente/@KompKenn', i))[1];
                    k_nachweisgrenze := (xpath('.//Komponente/@NachweisGrenze', i))[1];
                    k_einheit := (xpath('.//Komponente/@Einheit', i))[1];
                    mess_tag := (xpath('.//DatenReihe/@ZeitPunkt', i))[1];

                    INSERT INTO station_data.lut_component (component_name, component_name_short, unit, threshold, lubw_code)
                        VALUES (ad_name, k_kurzname, k_einheit, k_nachweisgrenze,k_kompkenn)
                        ON CONFLICT DO NOTHING;


                    FOREACH wert IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']/Komponente/DatenReihe/Wert//text()', myxml) LOOP
                            
                        curr_hour := curr_hour + interval '1 hour';
                        time_stamp := (mess_tag||' '||curr_hour)::TIMESTAMP;
            

                        INSERT INTO output_tmp (ms_eu, ad_name, ko_name, zeit, werte)
                          SELECT ms_eu, ad_name, k_name, time_stamp,wert
                            WHERE wert <> -999
                            ON CONFLICT DO NOTHING;
                        
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
  

    WITH 
    lut_stat AS
    (SELECT * from station_data.lut_station)
    ,
    lut_co AS
    (SELECT * from station_data.lut_component)

    INSERT INTO station_data.tab_measurement 
      (
      fk_station, 
      fk_component, 
      date_time,  
      val
      )

    SELECT 
      lut_stat.idpk_station, 
      lut_co.idpk_component, 
      output_tmp.zeit, 
      output_tmp.werte
    
    FROM output_tmp
    JOIN lut_stat ON output_tmp.ms_eu = lut_stat.eu_id
    JOIN lut_co on output_tmp.ad_name = lut_co.component_name
    ON CONFLICT DO NOTHING;
   
   UPDATE station_data.lut_station
   SET last_updated = now()
   FROM output_tmp tmp
   WHERE lut_station.eu_id = tmp.ms_eu;

  SELECT COUNT(werte) INTO zaehler FROM output_tmp;
    logentry_payload = '{"source":"lubw","timestamp":"'||ms_abrufzeit||'", "n_vals":"'||zaehler||'"}';
    EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',logentry_payload);
    
    TRUNCATE TABLE station_data.input_lubw;
   
    RAISE NOTICE 'Finished parsing % values (incl. NULL) from LUBW at %.', zaehler, now();

END;
$function$
;


ALTER FUNCTION station_data.lubw_parse() OWNER TO sauber_manager;

--
-- Name: prediction_parse(); Type: FUNCTION; Schema: station_data; Owner: sauber_manager
--

CREATE OR REPLACE FUNCTION station_data.prediction_parse()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
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

  component_id TEXT;
  component_id_short TEXT;
  unit_id TEXT;
  region_id TEXT;
  station_id TEXT;
  coordinates GEOMETRY;
  interval_len INT;
  creation_time TIMESTAMP;
  prediction_end_time TIMESTAMP;
  prediction_start_time TIMESTAMP;

  time_to_prediction SMALLINT;

  logentry_payload JSONB;
  counter INTEGER;
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
    FROM  station_data.input_prediction 
    ORDER BY idpk_json DESC 
    LIMIT 1 
  INTO payload;
  
  SELECT json_message 
    FROM  station_data.input_prediction 
    ORDER BY idpk_json DESC 
    LIMIT 1 
  INTO message;
  
  -- read all msg params  
  
  message_timestamp := to_timestamp((message->'timestamp')::bigint);
  category_name := message->'category';
  message_payload := message->'payload';
  
  component_id := message_payload->>'type';
  component_id_short := split_part(message_payload->>'type','_',1);
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
      pred_val := j->>component_id;
      time_to_prediction := extract(EPOCH FROM pred_dt - prediction_start_time)/3600; 
      --RAISE NOTICE E'pred val: %\n pred dt: %\n pred start time: %\n time delta: %\n', pred_val, pred_dt, prediction_start_time, time_to_prediction; 
    
     INSERT INTO tmp_json_vals 
      (
        tmp_dt,tmp_val,
        tmp_station, 
        tmp_geom, 
        tmp_region,
        tmp_component, 
        tmp_timetopred
      ) 
      VALUES 
       (
         pred_dt, 
         pred_val, 
         station_id,
         coordinates, 
         region_id, 
         component_id, 
         time_to_prediction
       );
     END LOOP;

  SELECT COUNT(tmp_val) FROM tmp_json_vals INTO counter;
  
-- INSERT station data 
  INSERT INTO 
    station_data.lut_station
  (
    station_code,
    address,
    wkb_geometry,
    last_updated 
  )
  VALUES (
    station_id,
    'Einsteinufer 37 10587 Berlin'::TEXT, --replace when available
    coordinates,
    now()
  ) ON CONFLICT (station_code) DO NOTHING;

  UPDATE 
    station_data.lut_station
  SET wkb_geometry = coordinates 
  WHERE wkb_geometry IS NULL;
  
  -- INSERT component metadata 
  INSERT INTO 
    station_data.lut_component
  (
    component_name,
    component_name_short,
    unit,
    lubw_threshold
  )
  VALUES 
  (
    component_id,
    component_id_short,
  unit_id,
    'dummy_threshold'::TEXT -- replace when available
  )
  ON CONFLICT (component_name)DO NOTHING;

-- INSERT values 
  WITH 
    lut_stat AS
    (SELECT * FROM  station_data.lut_station)
    ,
    lut_comp AS
    (SELECT * FROM  station_data.lut_component)

  INSERT INTO station_data.tab_prediction
  (
  val,
    date_time,
    fk_component,
    fk_station,
    offset_hrs
  )
  
  SELECT 
    
    tmp_json_vals.tmp_val, 
    tmp_json_vals.tmp_dt, 
    lut_comp.idpk_component, 
    lut_stat.idpk_station, 
    tmp_json_vals.tmp_timetopred
  
  FROM tmp_json_vals
  JOIN lut_stat ON tmp_json_vals.tmp_station = lut_stat.station_name
  JOIN lut_comp on tmp_json_vals.tmp_component = lut_comp.component_name
  WHERE tmp_json_vals.tmp_dt >= prediction_start_time
  ON CONFLICT (val, date_time, fk_component, fk_station) DO NOTHING;

  logentry_payload = '{"source":"hhi","data_timestamp":"'||message_timestamp||'", "n_vals":"'||counter||'"}';
  EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',logentry_payload);
  RETURN FORMAT('Inserted %L values from HHI into predictions table.', counter);

END;
$function$
;



ALTER FUNCTION station_data.prediction_parse() OWNER TO sauber_manager;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: nrw_demo; Type: TABLE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE TABLE image_mosaics.nrw_demo (
    fid integer NOT NULL,
    the_geom public.geometry(Polygon,25832),
    location character varying(255),
    ts timestamp without time zone
);


ALTER TABLE image_mosaics.nrw_demo OWNER TO sauber_manager;

--
-- Name: nrw_demo_fid_seq; Type: SEQUENCE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE SEQUENCE image_mosaics.nrw_demo_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_mosaics.nrw_demo_fid_seq OWNER TO sauber_manager;

--
-- Name: nrw_demo_fid_seq; Type: SEQUENCE OWNED BY; Schema: image_mosaics; Owner: sauber_manager
--

ALTER SEQUENCE image_mosaics.nrw_demo_fid_seq OWNED BY image_mosaics.nrw_demo.fid;


--
-- Name: nrw_pm10_gm1h24h; Type: TABLE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE TABLE image_mosaics.nrw_pm10_gm1h24h (
    fid integer NOT NULL,
    the_geom public.geometry(Polygon,25832),
    location character varying(255),
    ts timestamp without time zone
);


ALTER TABLE image_mosaics.nrw_pm10_gm1h24h OWNER TO sauber_manager;

--
-- Name: nrw_pm10_gm1h24h_fid_seq; Type: SEQUENCE; Schema: image_mosaics; Owner: sauber_manager
--

CREATE SEQUENCE image_mosaics.nrw_pm10_gm1h24h_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE image_mosaics.nrw_pm10_gm1h24h_fid_seq OWNER TO sauber_manager;

--
-- Name: nrw_pm10_gm1h24h_fid_seq; Type: SEQUENCE OWNED BY; Schema: image_mosaics; Owner: sauber_manager
--

ALTER SEQUENCE image_mosaics.nrw_pm10_gm1h24h_fid_seq OWNED BY image_mosaics.nrw_pm10_gm1h24h.fid;


--
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
-- Name: raster_metadata_idpk_image_seq; Type: SEQUENCE OWNED BY; Schema: image_mosaics; Owner: sauber_manager
--

ALTER SEQUENCE image_mosaics.raster_metadata_idpk_image_seq OWNED BY image_mosaics.raster_metadata.idpk_image;


--
-- Name: lut_component; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.lut_component (
    idpk_component integer NOT NULL,
    component_name text NOT NULL,
    component_name_short text,
    unit text,
    threshold text,
    lubw_code integer
);


ALTER TABLE station_data.lut_component OWNER TO sauber_manager;

--
-- Name: lut_station; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.lut_station (
    idpk_station integer NOT NULL,
    station_code text NOT NULL,
    station_name text,
    eu_id text,
    nuts_id text,
    region smallint,
    address text,
    last_updated timestamp without time zone,
    wkb_geometry public.geometry(Point,3035)
);


ALTER TABLE station_data.lut_station OWNER TO sauber_manager;

--
-- Name: tab_prediction; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.tab_prediction (
    idpk_value bigint NOT NULL,
    val double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL,
    offset_hrs smallint NOT NULL
);


ALTER TABLE station_data.tab_prediction OWNER TO sauber_manager;

--
-- Name: fv_wfs; Type: VIEW; Schema: station_data; Owner: sauber_manager
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
    co.component_name,
    sel.fk_station AS station_id,
    s.station_name,
    max(sel.date_time) AS max_datetime,
    min(sel.date_time) AS min_datetime,
    (json_agg(json_build_object('datetime', sel.date_time, 'val', sel.wert) ORDER BY sel.date_time DESC))::text AS series,
    s.wkb_geometry AS geom
   FROM ((sel
     JOIN station_data.lut_component co ON ((sel.fk_component = co.idpk_component)))
     JOIN station_data.lut_station s ON ((sel.fk_station = s.idpk_station)))
  GROUP BY s.idpk_station, sel.fk_component, sel.fk_station, co.component_name, s.station_name, s.wkb_geometry;


ALTER TABLE station_data.fv_wfs OWNER TO sauber_manager;

--
-- Name: gt_pk_metadata; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.gt_pk_metadata (
    table_schema character varying(32) NOT NULL,
    table_name character varying(32) NOT NULL,
    pk_column character varying(32) NOT NULL,
    pk_column_idx integer,
    pk_policy character varying(32),
    pk_sequence character varying(64)
);


ALTER TABLE station_data.gt_pk_metadata OWNER TO sauber_manager;

--
-- Name: input_lanuv; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.input_lanuv (
    station_name text,
    station_code text,
    o3_val text,
    so2_val text,
    no2_val text,
    pm10_val text,
    other text
);


ALTER TABLE station_data.input_lanuv OWNER TO sauber_manager;

--
-- Name: input_lubw; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.input_lubw (
    xml xml
);


ALTER TABLE station_data.input_lubw OWNER TO sauber_manager;

--
-- Name: input_prediction; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.input_prediction (
    idpk_json integer NOT NULL,
    json_payload jsonb NOT NULL,
    json_message jsonb NOT NULL
);


ALTER TABLE station_data.input_prediction OWNER TO sauber_manager;

--
-- Name: logtable; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.logtable (
    idpk_log integer NOT NULL,
    log_ts timestamp without time zone DEFAULT now() NOT NULL,
    log_entry jsonb NOT NULL
);


ALTER TABLE station_data.logtable OWNER TO sauber_manager;

--
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
-- Name: logtable_idpk_log_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.logtable_idpk_log_seq OWNED BY station_data.logtable.idpk_log;


--
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
-- Name: lut_component_idpk_component_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.lut_component_idpk_component_seq OWNED BY station_data.lut_component.idpk_component;


--
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
-- Name: lut_station_idpk_station_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.lut_station_idpk_station_seq OWNED BY station_data.lut_station.idpk_station;


--
-- Name: tab_measurement; Type: TABLE; Schema: station_data; Owner: sauber_manager
--

CREATE TABLE station_data.tab_measurement (
    idpk_measurement bigint NOT NULL,
    val double precision NOT NULL,
    date_time timestamp without time zone NOT NULL,
    fk_component integer NOT NULL,
    fk_station integer NOT NULL
);


ALTER TABLE station_data.tab_measurement OWNER TO sauber_manager;

--
-- Name: pm10_latest_measurement; Type: VIEW; Schema: station_data; Owner: sauber_manager
--

CREATE OR REPLACE VIEW station_data.pm10_latest_measurement AS
SELECT
  x.* 
  FROM
  (
  SELECT
    ROW_NUMBER() OVER () AS idpk, 
    ROW_NUMBER() OVER(PARTITION BY s.station_name ORDER BY tab.date_time DESC) AS num_vals, 
    s.station_name, tab.date_time, 
    round(tab.val::NUMERIC, 1) AS val,
    c.unit, 
    c.component_name_short,
    s.wkb_geometry
  FROM
    station_data.tab_measurement tab
  JOIN station_data.lut_component c ON tab.fk_component = c.idpk_component
  JOIN station_data.lut_station s ON tab.fk_station = s.idpk_station
  WHERE c.component_name_short = 'PM10'::TEXT AND s.wkb_geometry IS NOT NULL 
  ) x
WHERE
  x.num_vals <= 24
ORDER BY
  x.station_name ASC,
  x.date_time DESC;

ALTER TABLE station_data.pm10_latest_measurement OWNER TO sauber_manager;

--
-- Name: prediction_input_idpk_json_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.prediction_input_idpk_json_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.prediction_input_idpk_json_seq OWNER TO sauber_manager;

--
-- Name: prediction_input_idpk_json_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.prediction_input_idpk_json_seq OWNED BY station_data.input_prediction.idpk_json;


--
-- Name: tab_measurement_idpk_prediction_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.tab_measurement_idpk_prediction_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.tab_measurement_idpk_prediction_seq OWNER TO sauber_manager;

--
-- Name: tab_measurement_idpk_prediction_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.tab_measurement_idpk_prediction_seq OWNED BY station_data.tab_measurement.idpk_measurement;


--
-- Name: tab_prediction_idpk_value_seq; Type: SEQUENCE; Schema: station_data; Owner: sauber_manager
--

CREATE SEQUENCE station_data.tab_prediction_idpk_value_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE station_data.tab_prediction_idpk_value_seq OWNER TO sauber_manager;

--
-- Name: tab_prediction_idpk_value_seq; Type: SEQUENCE OWNED BY; Schema: station_data; Owner: sauber_manager
--

ALTER SEQUENCE station_data.tab_prediction_idpk_value_seq OWNED BY station_data.tab_prediction.idpk_value;


--
-- Name: nrw_demo fid; Type: DEFAULT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.nrw_demo ALTER COLUMN fid SET DEFAULT nextval('image_mosaics.nrw_demo_fid_seq'::regclass);


--
-- Name: nrw_pm10_gm1h24h fid; Type: DEFAULT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.nrw_pm10_gm1h24h ALTER COLUMN fid SET DEFAULT nextval('image_mosaics.nrw_pm10_gm1h24h_fid_seq'::regclass);


--
-- Name: raster_metadata idpk_image; Type: DEFAULT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.raster_metadata ALTER COLUMN idpk_image SET DEFAULT nextval('image_mosaics.raster_metadata_idpk_image_seq'::regclass);


--
-- Name: input_prediction idpk_json; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.input_prediction ALTER COLUMN idpk_json SET DEFAULT nextval('station_data.prediction_input_idpk_json_seq'::regclass);


--
-- Name: logtable idpk_log; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.logtable ALTER COLUMN idpk_log SET DEFAULT nextval('station_data.logtable_idpk_log_seq'::regclass);


--
-- Name: lut_component idpk_component; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_component ALTER COLUMN idpk_component SET DEFAULT nextval('station_data.lut_component_idpk_component_seq'::regclass);


--
-- Name: lut_station idpk_station; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_station ALTER COLUMN idpk_station SET DEFAULT nextval('station_data.lut_station_idpk_station_seq'::regclass);


--
-- Name: tab_measurement idpk_measurement; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_measurement ALTER COLUMN idpk_measurement SET DEFAULT nextval('station_data.tab_measurement_idpk_prediction_seq'::regclass);


--
-- Name: tab_prediction idpk_value; Type: DEFAULT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction ALTER COLUMN idpk_value SET DEFAULT nextval('station_data.tab_prediction_idpk_value_seq'::regclass);


--
-- Name: nrw_demo nrw_demo_pkey; Type: CONSTRAINT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.nrw_demo
    ADD CONSTRAINT nrw_demo_pkey PRIMARY KEY (fid);


--
-- Name: nrw_pm10_gm1h24h nrw_pm10_gm1h24h_pkey; Type: CONSTRAINT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.nrw_pm10_gm1h24h
    ADD CONSTRAINT nrw_pm10_gm1h24h_pkey PRIMARY KEY (fid);


--
-- Name: raster_metadata raster_metadata_pkey; Type: CONSTRAINT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.raster_metadata
    ADD CONSTRAINT raster_metadata_pkey PRIMARY KEY (idpk_image);


--
-- Name: raster_metadata raster_metadata_uq_path; Type: CONSTRAINT; Schema: image_mosaics; Owner: sauber_manager
--

ALTER TABLE ONLY image_mosaics.raster_metadata
    ADD CONSTRAINT raster_metadata_uq_path UNIQUE (image_path);


--
-- Name: gt_pk_metadata gt_pk_metadata_pkey; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.gt_pk_metadata
    ADD CONSTRAINT gt_pk_metadata_pkey PRIMARY KEY (table_schema, table_name, pk_column);


--
-- Name: logtable logtable_pkey; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.logtable
    ADD CONSTRAINT logtable_pkey PRIMARY KEY (idpk_log);


--
-- Name: lut_component lut_component_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_component
    ADD CONSTRAINT lut_component_pk PRIMARY KEY (idpk_component);


--
-- Name: lut_component lut_component_uq_name; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_component
    ADD CONSTRAINT lut_component_uq_name UNIQUE (component_name);


--
-- Name: lut_station lut_station_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_station
    ADD CONSTRAINT lut_station_pk PRIMARY KEY (idpk_station);


--
-- Name: lut_station lut_station_uq_code; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.lut_station
    ADD CONSTRAINT lut_station_uq_code UNIQUE (station_code);


--
-- Name: input_prediction raw_input_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.input_prediction
    ADD CONSTRAINT raw_input_pk PRIMARY KEY (idpk_json);


--
-- Name: tab_measurement tab_meas_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_measurement
    ADD CONSTRAINT tab_meas_pk PRIMARY KEY (idpk_measurement, date_time);


--
-- Name: tab_measurement tab_measurement_un; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_measurement
    ADD CONSTRAINT tab_measurement_un UNIQUE (fk_station, date_time, fk_component);


--
-- Name: tab_prediction tab_prediction_pk; Type: CONSTRAINT; Schema: station_data; Owner: sauber_manager
--

ALTER TABLE ONLY station_data.tab_prediction
    ADD CONSTRAINT tab_prediction_pk PRIMARY KEY (idpk_value, date_time);


--
-- Name: spatial_nrw_demo_the_geom; Type: INDEX; Schema: image_mosaics; Owner: sauber_manager
--

CREATE INDEX spatial_nrw_demo_the_geom ON image_mosaics.nrw_demo USING gist (the_geom);


--
-- Name: spatial_nrw_pm10_gm1h24h_the_geom; Type: INDEX; Schema: image_mosaics; Owner: sauber_manager
--

CREATE INDEX spatial_nrw_pm10_gm1h24h_the_geom ON image_mosaics.nrw_pm10_gm1h24h USING gist (the_geom);


--
-- Name: idx_dt_desc; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc ON station_data.tab_prediction USING btree (date_time DESC);


--
-- Name: idx_dt_desc_temp; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX idx_dt_desc_temp ON station_data.tab_prediction USING btree (date_time DESC);


--
-- Name: tab_meas_date_time_idx; Type: INDEX; Schema: station_data; Owner: sauber_manager
--

CREATE INDEX tab_meas_date_time_idx ON station_data.tab_measurement USING btree (date_time DESC);


--
-- Name: SCHEMA image_mosaics; Type: ACL; Schema: -; Owner: sauber_manager
--

GRANT USAGE ON SCHEMA image_mosaics TO sauber_user;
GRANT USAGE ON SCHEMA image_mosaics TO app;
GRANT USAGE ON SCHEMA image_mosaics TO anon;


--
-- Name: SCHEMA station_data; Type: ACL; Schema: -; Owner: sauber_manager
--

GRANT USAGE ON SCHEMA station_data TO app;
GRANT USAGE ON SCHEMA station_data TO sauber_user;

--
-- Name: FUNCTION createlogentry(pload jsonb); Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT EXECUTE ON FUNCTION station_data.createlogentry(pload jsonb) TO app;


--
-- Name: FUNCTION lanuv_parse(input_ts text); Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT EXECUTE ON FUNCTION station_data.lanuv_parse(input_ts text) TO app;


--
-- Name: FUNCTION lubw_parse(); Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT EXECUTE ON FUNCTION station_data.lubw_parse() TO app;


--
-- Name: FUNCTION prediction_parse(); Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT EXECUTE ON FUNCTION station_data.prediction_parse() TO app;


--
-- Name: TABLE raster_metadata; Type: ACL; Schema: image_mosaics; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE image_mosaics.raster_metadata TO app;
GRANT SELECT,UPDATE ON TABLE image_mosaics.raster_metadata TO anon;
GRANT SELECT ON TABLE image_mosaics.raster_metadata TO sauber_user;


--
-- Name: SEQUENCE raster_metadata_idpk_image_seq; Type: ACL; Schema: image_mosaics; Owner: sauber_manager
--

GRANT SELECT,USAGE ON SEQUENCE image_mosaics.raster_metadata_idpk_image_seq TO sauber_user;
GRANT SELECT,USAGE ON SEQUENCE image_mosaics.raster_metadata_idpk_image_seq TO anon;
GRANT SELECT,USAGE ON SEQUENCE image_mosaics.raster_metadata_idpk_image_seq TO app;


--
-- Name: TABLE lut_component; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE station_data.lut_component TO app;
GRANT SELECT ON TABLE station_data.lut_component TO sauber_user;


--
-- Name: TABLE lut_station; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE station_data.lut_station TO app;
GRANT SELECT ON TABLE station_data.lut_station TO sauber_user;

--
-- Name: TABLE tab_prediction; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT, UPDATE ON TABLE station_data.tab_prediction TO app;
GRANT SELECT ON TABLE station_data.tab_prediction TO sauber_user;

--
-- Name: TABLE input_lanuv; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON TABLE station_data.input_lanuv TO app;
GRANT SELECT ON TABLE station_data.input_lanuv TO sauber_user;

--
-- Name: TABLE input_lubw; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON TABLE station_data.input_lubw TO app;

--
-- Name: TABLE input_prediction; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON TABLE station_data.input_prediction TO app;

--
-- Name: TABLE logtable; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE station_data.logtable TO app;
GRANT SELECT ON TABLE station_data.logtable TO sauber_user;


--
-- Name: SEQUENCE logtable_idpk_log_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.logtable_idpk_log_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.logtable_idpk_log_seq TO sauber_user;


--
-- Name: SEQUENCE lut_component_idpk_component_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.lut_component_idpk_component_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.lut_component_idpk_component_seq TO sauber_user;


--
-- Name: SEQUENCE lut_station_idpk_station_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.lut_station_idpk_station_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.lut_station_idpk_station_seq TO sauber_user;


--
-- Name: TABLE tab_measurement; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE station_data.tab_measurement TO app;
GRANT SELECT ON TABLE station_data.tab_measurement TO sauber_user;


--
-- Name: SEQUENCE prediction_input_idpk_json_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.prediction_input_idpk_json_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.prediction_input_idpk_json_seq TO sauber_user;


--
-- Name: SEQUENCE tab_measurement_idpk_prediction_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.tab_measurement_idpk_prediction_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.tab_measurement_idpk_prediction_seq TO sauber_user;


--
-- Name: SEQUENCE tab_prediction_idpk_value_seq; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT ALL ON SEQUENCE station_data.tab_prediction_idpk_value_seq TO app;
GRANT USAGE,SELECT ON SEQUENCE station_data.tab_prediction_idpk_value_seq TO sauber_user;


--
-- Name: VIEW fv_wfs; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT,INSERT,UPDATE ON TABLE station_data.lut_station TO app;
GRANT SELECT ON TABLE station_data.lut_station TO sauber_user;

--
-- Name: VIEW fv_wfs; Type: ACL; Schema: station_data; Owner: sauber_manager
--

GRANT SELECT ON TABLE station_data.fv_wfs TO sauber_user;

SELECT create_hypertable('station_data.tab_prediction','date_time');
SELECT create_hypertable('station_data.tab_measurement','date_time'); 

ALTER DATABASE sauber_data OWNER TO sauber_manager;

--
-- sauber_managerQL database dump complete
--

