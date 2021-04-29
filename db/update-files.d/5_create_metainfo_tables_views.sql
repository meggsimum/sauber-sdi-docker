CREATE TABLE station_data.tab_station_metainfo
(
    idpk_station_metainfo SERIAL,
    station_code TEXT, 
    profile_url TEXT,
    image_url TEXT,
    description TEXT,
    external_resource TEXT
);

ALTER TABLE station_data.tab_station_metainfo OWNER TO sauber_manager;
ALTER TABLE station_data.tab_component_metainfo ADD CONSTRAINT tab_component_metainfo_pk PRIMARY KEY (idpk_component_metainfo);
ALTER TABLE station_data.tab_component_metainfo ADD CONSTRAINT tab_component_metainfo_uq UNIQUE (component_id);
GRANT SELECT,INSERT ON station_data.tab_station_metainfo TO app;


CREATE TABLE station_data.tab_component_metainfo
(
    idpk_component_metainfo SERIAL,
    component_id TEXT,
    component_name_german TEXT,
    component_name_english TEXT,
    component_aggregation_german TEXT,
    component_aggregation_english TEXT
);

ALTER TABLE station_data.tab_component_metainfo OWNER TO sauber_manager;
ALTER TABLE station_data.tab_station_metainfo ADD CONSTRAINT tab_station_metainfo_pk PRIMARY KEY (idpk_station_metainfo);
ALTER TABLE station_data.tab_station_metainfo ADD CONSTRAINT tab_station_metainfo_un UNIQUE (station_code);
GRANT SELECT,INSERT ON station_data.tab_component_metainfo TO app;


CREATE OR REPLACE VIEW station_data.fv_station_metadata
AS WITH sel AS (
         SELECT tp_1.fk_component AS comp,
            tp_1.fk_station AS stat,
            json_agg(json_build_object('datetime', tp_1.date_time, 'val', tp_1.val) ORDER BY tp_1.date_time DESC)::text AS series
           FROM station_data.tab_prediction tp_1
             JOIN station_data.lut_component co_1 ON tp_1.fk_component = co_1.idpk_component
             JOIN station_data.lut_station s_1 ON tp_1.fk_station = s_1.idpk_station
          WHERE tp_1.date_time >= (now() - '24:00:00'::interval) AND tp_1.date_time <= now()
          GROUP BY tp_1.fk_component, tp_1.fk_station
        )
 SELECT row_number() OVER () AS idpk,
    s.station_name,
    s.station_code,
    s.idpk_station AS station_id,
    co.component_name,
    co.idpk_component AS component_id,
    cm.component_name_german,
    cm.component_aggregation_german,
    cm.component_name_english,
    cm.component_aggregation_english,
    max(
        CASE
            WHEN s.region ~~ 'NRW'::text THEN concat('https://www.lanuv.nrw.de/luqs/messorte/steckbrief.php?ort=', s.station_code)
            WHEN s.region ~~ 'Stuttgart'::text THEN sm.profile_url
            ELSE 'N.N.'::text
        END) AS profile_url,
    max(
        CASE
            WHEN s.region ~~ 'NRW'::text THEN concat('https://www.lanuv.nrw.de/luqs/messorte/bilder/', s.station_code, '.jpg')
            WHEN s.region ~~ 'Stuttgart'::text THEN sm.image_url
            ELSE 'N.N.'::text
        END) AS image_url,
    sel.series,
    s.wkb_geometry
   FROM station_data.tab_prediction tp
     JOIN station_data.lut_component co ON tp.fk_component = co.idpk_component
     JOIN station_data.tab_component_metainfo cm ON co.component_name = cm.component_id
     JOIN station_data.lut_station s ON tp.fk_station = s.idpk_station
     JOIN station_data.tab_station_metainfo sm ON s.station_code = sm.station_code
     LEFT JOIN sel ON tp.fk_station = sel.stat AND tp.fk_component = sel.comp
  GROUP BY s.station_name, s.station_code, s.idpk_station, co.component_name, co.idpk_component, cm.component_name_german, cm.component_aggregation_german, cm.component_name_english, cm.component_aggregation_english, sel.series, s.wkb_geometry
  ORDER BY s.station_code;

GRANT SELECT ON TABLE station_data.fv_station_metadata TO app;
GRANT SELECT ON TABLE station_data.fv_station_metadata TO sauber_manager;
GRANT SELECT ON TABLE station_data.fv_station_metadata TO sauber_user;
