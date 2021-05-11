\c sauber_data 
--
---- Create component view function
--
CREATE OR REPLACE FUNCTION station_data.create_component_view (
  component_name text
)
RETURNS text AS
$body$
DECLARE
  component_name ALIAS FOR $1;
  error_text TEXT;
BEGIN
  IF component_name IS NULL THEN
    RAISE INFO 'Error: Empty input variable';
 	RETURN 1;
  END IF;
      
  EXECUTE FORMAT('
	CREATE OR REPLACE VIEW station_data.agg_prediction_%1$s
	AS SELECT DISTINCT ON (tp.date_time) tp.date_time,
	    tp.val AS wert,
	    tp.fk_component,
	    tp.fk_station,
	    s_1.station_code,
	    s_1.wkb_geometry
	   FROM station_data.tab_prediction tp
	     JOIN station_data.lut_component co_1 ON tp.fk_component = co_1.idpk_component
	     JOIN station_data.lut_station s_1 ON tp.fk_station = s_1.idpk_station
	  WHERE co_1.component_name = %2$L::text
	  ORDER BY tp.date_time DESC;           
      GRANT SELECT ON station_data.agg_prediction_%1$s TO app;
	', replace(lower(component_name),'-','_'), component_name);
		
  RETURN FORMAT('agg_prediction_%1$s', replace(lower(component_name),'-','_'));
  EXCEPTION
  WHEN others THEN
        GET STACKED DIAGNOSTICS error_text = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error:%',SQLERRM;
        RAISE INFO 'SQL State:%', SQLSTATE;
 		RETURN 1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;
ALTER FUNCTION station_data.create_component_view (component_name text)
  OWNER TO sauber_manager;

--
---- Create prediction view function
--

CREATE OR REPLACE FUNCTION station_data.create_prediction_view(station_code text, component_name text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
      
  EXECUTE FORMAT('
			CREATE OR REPLACE VIEW station_data.%1$s_prediction_%2$s
			AS WITH sel AS (
			         SELECT DISTINCT ON (tp.date_time)
                     tp.date_time,
			            tp.val AS wert,
			            tp.fk_component,
			            tp.fk_station
			           FROM station_data.tab_prediction tp
			             JOIN station_data.lut_component co_1 ON tp.fk_component = co_1.idpk_component
			             JOIN station_data.lut_station s_1 ON tp.fk_station = s_1.idpk_station
			          WHERE s_1.station_code = %3$L AND co_1.component_name = %4$L
			          ORDER BY tp.date_time DESC
			        )
			 SELECT row_number() OVER () AS idpk,
			    sel.fk_component AS component_id,
			    co.component_name,
			    sel.fk_station AS station_id,
			    s.station_name,
			    max(sel.date_time) AS max_datetime,
			    min(sel.date_time) AS min_datetime,
			    json_agg(json_build_object(''datetime'', sel.date_time, ''val'', sel.wert) ORDER BY sel.date_time DESC)::text AS series,
			    s.wkb_geometry AS geom
			   FROM sel
			     JOIN station_data.lut_component co ON sel.fk_component = co.idpk_component
			     JOIN station_data.lut_station s ON sel.fk_station = s.idpk_station
			  GROUP BY s.idpk_station, sel.fk_component, sel.fk_station, co.component_name, s.station_name, s.wkb_geometry;
              
              GRANT SELECT ON station_data.%1$s_prediction_%2$s TO app;
              
			', replace(lower(station_code),'-','_'), lower(component_name), station_code, component_name);
		
  RETURN FORMAT('%1$s_prediction_%2$s', replace(lower(station_code),'-','_'), lower(component_name));

  EXCEPTION
  WHEN others THEN
        GET STACKED DIAGNOSTICS error_text = PG_EXCEPTION_CONTEXT;
        RAISE INFO 'Error:%',SQLERRM;
        RAISE INFO 'SQL State:%', SQLSTATE;
 		RETURN 1;

	 

END;
$_$;

ALTER FUNCTION station_data.create_prediction_view(station_code text, component_name text) OWNER TO sauber_manager;
