\c sauber_data

/*
Create view returning relative wms URLs including bbox and CQL filter on relevant station 
*/

CREATE OR REPLACE VIEW station_data.fv_wms_calls
AS WITH envelope AS (
         SELECT s.idpk_station AS idpk,
            s.station_name,
            s.station_code,
            st_envelope(st_buffer(s.wkb_geometry, 100::double precision)) AS env
           FROM station_data.tab_prediction p
             JOIN station_data.lut_station s ON p.fk_station = s.idpk_station
          GROUP BY s.idpk_station, s.station_name, s.station_code, s.wkb_geometry
        ), bbox AS (
         SELECT envelope.idpk,
            envelope.station_code,
            envelope.station_name,
            concat(round(st_xmin(envelope.env::box3d)), ',', round(st_ymin(envelope.env::box3d)), ',', round(st_xmax(envelope.env::box3d)), ',', round(st_ymax(envelope.env::box3d))) AS string
           FROM envelope
        )
 SELECT row_number() OVER () AS obj_id,
    bbox.idpk AS station_id,
    bbox.station_code,
    bbox.station_name,
    concat('geoserver/station_data/wms?service=WMS&version=1.1.0&request=GetMap&layers=basemap,fv_stations&bbox=', bbox.string, '&width=250&height=250&srs=EPSG%3A3035&styles=,fv_stations_wmscall&CQL_FILTER=INCLUDE;station_code=', quote_literal(bbox.station_code), '&FORMAT=image/png') AS wms_call
   FROM bbox
  ORDER BY bbox.idpk;

-- Permissions

ALTER TABLE station_data.fv_wms_calls OWNER TO postgres;
GRANT ALL ON TABLE station_data.fv_wms_calls TO postgres;
GRANT SELECT ON TABLE station_data.fv_wms_calls TO app;
GRANT SELECT ON TABLE station_data.fv_wms_calls TO sauber_user;
GRANT SELECT ON TABLE station_data.fv_wms_calls TO sauber_manager;
