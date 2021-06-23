\c sauber_data

CREATE OR REPLACE FUNCTION station_data.create_measurement_view(station_code text, component_name text)
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
	Takes station code and pollutant name as text input.
	On project convention, these are sent in uppercase.
	As  casing should be avoided in PostgreSQL, use lower case input for object names.

	On success, returns name of the created view as text. 

	On failuty, returns 1, SQL state. 
	*/ 

	EXECUTE FORMAT('
			CREATE OR REPLACE VIEW station_data.%1$s_measurement_%2$s
			AS WITH sel AS (
					SELECT DISTINCT ON (tp.date_time)
						tp.date_time,
						tp.val AS wert,
						tp.fk_component,
						tp.fk_station
						FROM station_data.tab_measurement tp
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
			 
			 GRANT SELECT ON station_data.%1$s_measurement_%2$s TO app;
			 
			', replace(lower(station_code),'-','_'), lower(component_name), station_code, component_name);
		
	RETURN FORMAT('%1$s_measurement_%2$s', replace(lower(station_code),'-','_'), lower(component_name));

	EXCEPTION
	WHEN others THEN
		GET STACKED DIAGNOSTICS error_text = PG_EXCEPTION_CONTEXT;
		RAISE INFO 'Error:%',SQLERRM;
		RAISE INFO 'SQL State:%', SQLSTATE;
		RETURN 1;


END;
$function$
;

ALTER FUNCTION station_data.create_measurement_view(text,text) OWNER TO sauber_manager;
GRANT ALL ON FUNCTION station_data.create_measurement_view(text,text) TO sauber_manager;
