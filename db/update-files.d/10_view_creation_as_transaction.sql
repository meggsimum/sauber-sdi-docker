\c sauber_data

CREATE OR REPLACE FUNCTION station_data.create_data_views(station_code text, component_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  station_code ALIAS FOR $1;
  component_name ALIAS FOR $2;
  error_text TEXT;
BEGIN

  IF station_code IS NULL 
  OR component_name IS NULL THEN
    RAISE INFO 'Error: Empty input variable';
    RETURN 1;
  END IF;

  /*
  Triggers creation of both measurement and prediction views.
  Views created in lowercase, replacing dash for underscore for PostgreSQL-friendly object names.
  
  Input: station code, pollutant name (text, text).
  Return on success: Names of both created views: "station_measurement_polllutant,station_measurement_polllutant"
  Return on failure: 1, Log SQL Error, SQL State
  */

  PERFORM station_data.create_prediction_view(station_code,component_name);
  PERFORM station_data.create_measurement_view(station_code,component_name);
 
  RETURN FORMAT('%1$s_measurement_%2$s, %1$s_prediction_%2$s', replace(lower(station_code),'-','_'), lower(component_name));

  EXCEPTION
  WHEN others THEN
        GET STACKED DIAGNOSTICS error_text = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error:%',SQLERRM;
        RAISE INFO 'SQL State:%', SQLSTATE;
        RETURN 1;

END;
$function$
;

ALTER FUNCTION 
