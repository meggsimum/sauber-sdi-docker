\c sauber_data

/*
Create MATERIALIZED VIEW fv_stations.
DROP VIEW IF exists from previous DB instances, to allow later changes.
Caveat: DROP VIEW IF EXISTS throws error if view is materialized, and vice versa.
Thus: Add helper function to drop either.
Add links to wms calls to fv_stations.
*/

-- Helper function
CREATE OR REPLACE FUNCTION station_data.drop_view(target_schema TEXT, target_view text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$  
BEGIN
    IF EXISTS (SELECT matviewname from pg_matviews where schemaname = target_schema and matviewname = target_view) THEN
        EXECUTE format('DROP MATERIALIZED VIEW %I.%I', target_schema,target_view);
        RAISE NOTICE 'Dropped materialized view %', target_view;
    ELSEIF EXISTS (SELECT viewname from pg_views where schemaname = target_schema and viewname = target_view) THEN
        EXECUTE format('DROP VIEW %I.%I', target_schema,target_view);
        RAISE NOTICE 'Dropped view %', target_view;
    ELSE RAISE NOTICE 'View not found';
    END IF;
END;
$function$
;

-- Call helper function 
SELECT station_data.drop_view('station_data','fv_stations');


-- Create materialized view 
CREATE MATERIALIZED VIEW station_data.fv_stations
AS WITH envelope AS (
         SELECT s.idpk_station AS idpk,
            s.station_name,
            s.station_code,
            st_envelope(st_buffer(s.wkb_geometry, /*buffer width:*/ 100::double precision)) AS env
           FROM station_data.tab_prediction p
             JOIN station_data.lut_station s ON p.fk_station = s.idpk_station
          GROUP BY s.idpk_station, s.station_name, s.station_code, s.wkb_geometry
        ), bbox AS (
         SELECT envelope.idpk,
            envelope.station_code,
            envelope.station_name,
            concat(
            round(st_ymin(envelope.env::box3d)),',', 
            round(st_xmin(envelope.env::box3d)),',',
            round(st_ymax(envelope.env::box3d)),',',
            round(st_xmax(envelope.env::box3d))
            ) AS string
           FROM envelope
        )
SELECT s.idpk_station AS idpk,
    s.station_name,
    s.station_code,
    s.eu_id,
    array_to_json(array_agg(DISTINCT c.component_name)) AS pollutants,
    concat('geoserver/station_data/wms?service=WMS&version=1.3.0&request=GetMap&layers=basemap,fv_stations&bbox=', bbox.string, '&width=250&height=250&srs=EPSG%3A3035&styles=,fv_stations_wmscall&CQL_FILTER=INCLUDE;station_code=', quote_literal(bbox.station_code), '&FORMAT=image/png') AS preview_wms_image,
    s.wkb_geometry AS geom
   FROM station_data.tab_prediction p
     JOIN station_data.lut_component c ON p.fk_component = c.idpk_component
     JOIN station_data.lut_station s ON p.fk_station = s.idpk_station
     JOIN bbox on s.station_code = bbox.station_code
  GROUP BY s.idpk_station, s.station_name, s.station_code, bbox.string, bbox.station_code, s.wkb_geometry;

-- Permissions
ALTER TABLE station_data.fv_stations OWNER TO sauber_manager;
GRANT ALL ON TABLE station_data.fv_stations TO postgres;
GRANT SELECT ON TABLE station_data.fv_stations TO app;
GRANT SELECT ON TABLE station_data.fv_stations TO sauber_user;
