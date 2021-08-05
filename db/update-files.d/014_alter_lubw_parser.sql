\c sauber_data

/*
Changes: Check that input coordinates not null 
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
          UPDATE SET last_updated = now();

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
 		UPDATE SET last_updated = now()
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
;
