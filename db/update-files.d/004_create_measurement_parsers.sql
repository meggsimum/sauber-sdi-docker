\c sauber_data

CREATE OR REPLACE FUNCTION station_data.lanuv_parse (
  input_ts text
)
RETURNS void AS
$body$
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
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;

ALTER FUNCTION station_data.lanuv_parse (input_ts text)
  OWNER TO sauber_manager;
