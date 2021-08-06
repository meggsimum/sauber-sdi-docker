\c sauber_data

CREATE OR REPLACE FUNCTION station_data.lanuv_parse_no()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  i RECORD;
  station_fk INTEGER;
  counter INTEGER;
  ts TIMESTAMP := date_trunc('minute', now());
  logentry_payload JSONB;

 BEGIN

  --DROP TABLE IF EXISTS import_cols;

 /*
  Get foreign key of nitrogen monoxide (NO) pollutant in current DB instance
  Get all column names from import table > Get all columns containing NO
  Build corresponding station code from col name 
 */
  CREATE TEMP TABLE IF NOT EXISTS import_cols AS 
  WITH pollutant AS 
  (  
  SELECT idpk_component AS pollutant_fk
  FROM station_data.lut_component
  WHERE component_name LIKE 'NO_AM1H'
  ),
  cols_no AS 
  (
  WITH cols AS 
  (
    SELECT *
    FROM information_schema.columns
    WHERE table_schema = 'station_data'
    AND table_name   = 'input_lanuv_no'
  )
  SELECT column_name FROM cols
  WHERE column_name LIKE '%_no_1h%'
  )
  SELECT 
    c.column_name,
    upper(LEFT(c.column_name, strpos(c.column_name, '_') - 1)) AS station_code,
    p.pollutant_fk
  FROM cols_no c
  CROSS JOIN pollutant p;


 /* 
    Loop over above table, discard empty vals
    Get foreign key of stations via station code
    Station foreign key NULL = Station not in DB instance yet > Discard
    Loop over all NO cols in import table, build timestamp, insert into permanent table with correct station, pollutant FK 
 */

  FOR i IN 
  (
    SELECT column_name, station_code, pollutant_fk 
    FROM import_cols 
    WHERE column_name IS NOT NULL 
    AND station_code IS NOT NULL
  ) LOOP 

  SELECT idpk_station 
  INTO station_fk
  FROM station_data.lut_station l
  WHERE station_code LIKE i.station_code;

  IF 
    station_fk IS NULL THEN CONTINUE; 
  END IF;

  --RAISE NOTICE 'stat_id: %, colname: %, code: %, poll: %', station_fk, i.column_name, i.station_code, i.pollutant_fk;

  EXECUTE FORMAT('
  INSERT INTO station_data.tab_measurement (val, date_time, fk_component, fk_station)
    SELECT 
      %I::double precision,
      date_trunc(''hour'',to_timestamp(concat(la.datum || '' '' || la.zeit),''DD.MM.YYYY HH24:MI'') + interval ''1 minute'') as zeit,
      %s::int,
      %s::int
    FROM station_data.input_lanuv_no la
    WHERE %I IS NOT NULL 
    ORDER BY zeit ASC
  ON CONFLICT (fk_station, date_time, fk_component)
  DO NOTHING;
  ', i.column_name, i.pollutant_fk, station_fk, i.column_name);

  END LOOP;

  SELECT COUNT(*) FROM import_cols into counter;
  logentry_payload = '{"source":"lanuv_no","timestamp":"'||ts||'", "n_vals":"'||counter||'"}';
  EXECUTE FORMAT('SELECT station_data.createlogentry(%L)', logentry_payload);


  RAISE NOTICE 'Inserted % LANUV nitrogen monoxide values', counter;
  TRUNCATE TABLE station_data.input_lanuv_no;

END;
$function$
;
