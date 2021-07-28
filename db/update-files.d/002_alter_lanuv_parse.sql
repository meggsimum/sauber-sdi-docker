\c sauber_data

CREATE OR REPLACE FUNCTION station_data.lanuv_parse(input_ts text)
 RETURNS void 
 LANGUAGE plpgsql
AS $function$
DECLARE 

	i RECORD;
    ts TIMESTAMP;

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
    
    	
	FOR i in (SELECT * FROM station_data.input_lanuv) LOOP
  	
      RAISE NOTICE 'code:%, o3:%, so2:% pm10:% ', i.station_code, i.o3_val, i.so2_val, i.pm10_val;
  	
      INSERT INTO tmp (val, date_time,component,station)
      VALUES	(i.o3_val, ts ,'O3_AM1H', station_name, i.station_code);
     
      INSERT INTO tmp (val, date_time,component,station)
      VALUES	(i.so2_val, ts ,'SO2_AM1H', station_name, i.station_code);
      
      INSERT INTO tmp (val, date_time,component,station)
      VALUES	(i.pm10_val, ts ,'PM10_AM1H', station_name, i.station_code);

      INSERT INTO tmp (val, date_time,component,station)
      VALUES	(i.no2_val, ts ,'NO2_AM1H', station_name, i.station_code);

	END LOOP;
	

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
    
    SELECT tmp.val, tmp.date_time, lut_comp.idpk_component, lut_stat.idpk_station
    FROM station_data.input_lanuv rm 
    JOIN lut_stat ON tmp.station = lut_stat.station_name
    JOIN lut_comp on tmp.component = lut_comp.component_name
    ON CONFLICT (val, date_time, fk_component, fk_station) 
    DO NOTHING;

END;
$function$
;
