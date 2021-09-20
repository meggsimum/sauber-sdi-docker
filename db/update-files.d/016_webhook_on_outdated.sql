\c sauber_data

/* 
Add new columns for last prediction, measurement update 
*/


ALTER TABLE station_data.lut_station ADD COLUMN IF NOT EXISTS measurement_last_updated timestamp NULL;
ALTER TABLE station_data.lut_station ADD COLUMN IF NOT EXISTS prediction_last_updated timestamp NULL;
ALTER TABLE station_data.lut_station DROP COLUMN IF EXISTS last_updated;

/*
 Prediction parser 
 Update column prediction_last_updated
*/

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
  coordinates_text TEXT;
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

  -- Create tmp tables to hold parsed values
  CREATE TEMP TABLE tmp_json_vals (
    tmp_dt TIMESTAMP,
    tmp_val DOUBLE PRECISION,
    tmp_station TEXT,
    tmp_geom GEOMETRY,
    tmp_region TEXT,
    tmp_component TEXT,
    tmp_timetopred SMALLINT
  ) ON COMMIT DROP;

  -- Get last raw JSON FROM  input table
  -- This function gets called only after successful JSON insert
  --> Last JSON should be latest input
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


  RAISE NOTICE '%', message;

  -- Read message parameters

  message_timestamp := to_timestamp((message->'timestamp')::bigint);
  category_name := message->'category';
  message_payload := message->'payload';

  component_id := message_payload->>'type';
  component_id_short := split_part(message_payload->>'type','_',1);
  unit_id := message_payload->>'unit';
  region_id := message_payload->>'region';
  interval_len := message_payload->'interval';
  station_id := message_payload->>'stationId';
  coordinates_text := message_payload->>'coordinates';	 
  creation_time := to_timestamp((message_payload->'creationTime')::bigint);
  prediction_end_time := to_timestamp((message_payload->'predictionEndTime')::bigint);
  prediction_start_time := to_timestamp((message_payload->'predictionStartTime')::bigint);
  prediction := payload->'prediction';

  -- Check if coords are empty
  -- If empty -> Assign coordinates null
	 IF (coordinates_text = '') IS TRUE THEN 
	   coordinates := NULL;
	 ELSE 
	   coordinates := coordinates_text::GEOMETRY;
	 END IF; 
 
  -- Loop over data
  -- Assign json values to variables
  FOR j IN
  SELECT * FROM jsonb_array_elements(prediction)
  LOOP
    pred_dt := to_timestamp((j->>'DateTime')::bigint);
    pred_val := j->>component_id;
    time_to_prediction := extract(EPOCH FROM pred_dt - prediction_start_time)/3600;

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

  -- Check if station coordinates are inside area of interest (here: Germany)
  -- If yes: Insert given coordinates, or update missing coordinates for that station.
  -- If not: Set given coordinates NULL, raise notice. This inserts the default NULL value, effectively prevents Update missing coordinates with wrong ones (UPDATE SET NULL = NULL).
  IF (SELECT ST_CONTAINS(st_makeenvelope(4031295,2684101,4672253,3551343,3035),coordinates)) IS NOT TRUE THEN
      RAISE NOTICE E'Station coordinates not in area of interest.\nCheck coordinates.\nDefaulting to NULL';
      coordinates := NULL;
  END IF;

  INSERT INTO
      station_data.lut_station
  (
      station_code,
      address,
      region,
      wkb_geometry,
      last_updated
  )
  VALUES (
      station_id,
      'Einsteinufer 37 10587 Berlin'::TEXT, -- Dummy, replace when available,
      region_id,
      coordinates,
      now()
  ) ON CONFLICT (station_code)
      DO
          UPDATE SET prediction_last_updated = now();

    -- Update coordinates if stations coords are empty so far
    UPDATE
      station_data.lut_station
    SET wkb_geometry = coordinates
    WHERE wkb_geometry IS NULL;

-- INSERT station data
-- IF EXISTS update time of last update
  INSERT INTO
    station_data.lut_station
  (
    station_code,
    address,
    region,
    wkb_geometry,
    last_updated
  )
  VALUES (
    station_id,
    'Einsteinufer 37 10587 Berlin'::TEXT, -- Replace when available
    region_id,
    coordinates,
    now()
  ) ON CONFLICT (station_code)
 	DO
 		UPDATE SET prediction_last_updated = now()
 	;

-- Update coordinates if stations coords are empty so far
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
    threshold
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
  JOIN lut_stat ON tmp_json_vals.tmp_station = lut_stat.station_code
  JOIN lut_comp on tmp_json_vals.tmp_component = lut_comp.component_name
  WHERE tmp_json_vals.tmp_dt >= prediction_start_time
  AND tmp_json_vals.tmp_val IS NOT NULL
  ON CONFLICT (val, date_time, fk_component, fk_station, offset_hrs) DO NOTHING;

  logentry_payload = '{"source":"hhi","data_timestamp":"'||message_timestamp||'", "n_vals":"'||counter||'"}';
  EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',logentry_payload);
  RETURN FORMAT('Inserted %L values from HHI into predictions table.', counter);

END;
$function$
;

/* 
LUBW parse
Update measurement_last_updated
*/

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
    curr_hour TIME := '00:00:00';
    
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

    -- Get input xml data
    SELECT xml FROM station_data.input_lubw INTO myxml;


  /* Start parsing through xml file via xpath
  Structure: 
  Messstelle - Metainfo for Station
  DatenTyp + Komponente: Metainfo for component lookup table
  DatenReihe: Actual measurement data  
  */
  FOREACH messstelle IN ARRAY xpath('//Messstelle/@Name', myxml) LOOP
    FOREACH i IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']', myxml) LOOP
    
            ms_name := messstelle;  
            ms_kurzname := (xpath('.//@KurzName', i))[1];           
            ms_eu := (xpath('.//@EUKenn', i))[1];
            ms_nuts := (xpath('.//@NUTS', i))[1];
            ms_rw := (xpath('.//@RW', i))[1];
            ms_hw := (xpath('.//@HW', i))[1];
            ms_abrufzeit := (xpath('.//@AbrufZeiger', i))[1];

            -- Build station info, coordinates from DHDN (EPSG 41367) and insert into lookup table
            INSERT INTO station_data.lut_station (station_code, station_name, eu_id, nuts_id, region, last_updated, wkb_geometry)
                VALUES ( ms_kurzname, ms_name, ms_eu, ms_nuts, 'BW', now(),
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

                    -- Build component metainfo from Komponente key and insert into lookup table
                    INSERT INTO station_data.lut_component (component_name, component_name_short, unit, threshold, lubw_code)
                        VALUES (ad_name, k_kurzname, k_einheit, k_nachweisgrenze,k_kompkenn)
                        ON CONFLICT DO NOTHING;


                    FOREACH wert IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']/Komponente/DatenReihe/Wert//text()', myxml) LOOP
                            
                        /* 
                        Extract time series data
                        Instead of directly extracting timestamp (issue: 24:00 hour mark), use iterator curr_hour to count up
                        */ 
                        curr_hour := curr_hour + interval '1 hour';
                        time_stamp := (mess_tag||' '||curr_hour)::TIMESTAMP;

                        -- Insert data into temporary table, omit NULL values (-999 in xml) 
                        INSERT INTO output_tmp (ms_eu, ad_name, ko_name, zeit, werte)
                          SELECT ms_eu, ad_name, k_name, time_stamp,wert
                          WHERE wert <> -999
                          ON CONFLICT DO NOTHING;
                        
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
  
  -- Get relevant lookup table foreign keys and insert time series data into table
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
  
  -- Update latest station update
  UPDATE station_data.lut_station
    SET measurement_last_updated = now()
    FROM output_tmp tmp
    WHERE lut_station.eu_id = tmp.ms_eu;

  -- Create logtable entry
  SELECT COUNT(werte) INTO zaehler FROM output_tmp;
  logentry_payload = '{"source":"lubw","timestamp":"'||ms_abrufzeit||'", "n_vals":"'||zaehler||'"}';
  EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',logentry_payload);
  
  TRUNCATE TABLE station_data.input_lubw;
  
  RAISE NOTICE 'Finished parsing % values (incl. NULL) from LUBW at %.', zaehler, now();

END;
$function$
;


/*
LANUV parse
Update measurement_last_updated
*/

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
   SET measurement_last_updated = now()
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


/*
* Create new alert function
*/

CREATE OR REPLACE FUNCTION station_data.check_station_last_updated()
 RETURNS void
 LANGUAGE plpgsql
AS $function$

	BEGIN

		/*
		 * Static JSON msg
		 */
		RAISE NOTICE 'Checking station data updates';
		IF 
			EXISTS ( 
				SELECT *  
				FROM station_data.lut_station ls 
				WHERE measurement_last_updated < now() - '1 day'::interval
		) THEN PERFORM  pg_notify('slack_alarms','{"text": "SAUBER stations: Outdated measurement values!"}');
	
		END IF; 

		IF 
			EXISTS ( 
				SELECT *  
				FROM station_data.lut_station ls 
				WHERE prediction_last_updated < now() - '1 day'::interval
		) THEN PERFORM  pg_notify('slack_alarms','{"text": "SAUBER stations: Outdated prediction values!"}');
		END IF; 

	END;
$function$
;

-- Permissions

ALTER FUNCTION station_data.check_station_last_updated() OWNER TO sauber_manager;
GRANT ALL ON FUNCTION station_data.check_station_last_updated() TO postgres;

-- Add to PG Cron. Update db and nodename.

INSERT INTO cron.job (schedule,command,nodename,nodeport,"database",username,active,jobname) VALUES
	 ('0 12 * * * ','SELECT station_data.check_station_last_updated()','',5432,'sauber_data','postgres',true,'check if station data is outdated ')
   ON CONFLICT DO NOTHING;

UPDATE cron.job SET nodename = '';
UPDATE cron.job SET "database" = 'sauber_data';
