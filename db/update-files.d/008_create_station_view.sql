\c sauber_data

DROP VIEW IF EXISTS station_data.fv_stations;

CREATE OR REPLACE VIEW station_data.fv_stations (
    idpk,
    station_name,
    station_code,
    eu_id,
    pollutants,
    geom
)
AS 
SELECT 
    s.idpk_station,
    s.station_name,
    s.station_code,
    s.eu_id, 
    array_to_json(array_agg(DISTINCT c.component_name)) as pollutants,
    s.wkb_geometry as geom
FROM station_data.tab_prediction p
JOIN station_data.lut_component c on p.fk_component = c.idpk_component 
JOIN station_data.lut_station s on p.fk_station = s.idpk_station 
GROUP BY s.idpk_station, s.station_name, s.station_code, s.wkb_geometry;

GRANT SELECT ON station_data.fv_stations TO app;
GRANT SELECT ON station_data.fv_stations TO sauber_user;
ALTER TABLE station_data.fv_stations OWNER TO sauber_manager;
GRANT ALL ON TABLE station_data.fv_stations TO sauber_manager;
