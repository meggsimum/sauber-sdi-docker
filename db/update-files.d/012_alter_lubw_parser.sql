\c sauber_data
/*
Parse downloaded measurement XML file from LUBW API
*/

CREATE OR REPLACE FUNCTION station_data.lubw_parse()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    myxml XML;
        
    messstelle TEXT;
    ms_name TEXT;
    ms_kurzname TEXT;
    ms_eu TEXT;
    ms_nuts TEXT;
    ms_hw INTEGER;
    ms_rw INTEGER;
    ms_abrufzeit TEXT;
    
    datentyp TEXT;
    ad_name TEXT;
    
    k_name TEXT;
    k_kurzname TEXT;
    k_kompkenn INTEGER;
    k_nachweisgrenze TEXT;
    k_einheit TEXT;
   
    mess_tag TEXT;    
    time_stamp TIMESTAMP;
    curr_hour TIME := '00:00:00';
    
    wert NUMERIC;    
    i XML;
    zaehler INTEGER;
    logentry_payload JSONB;

BEGIN
  
    CREATE TEMP TABLE output_tmp (
        ms_eu TEXT,
        ad_name TEXT,
        ko_name TEXT,
        zeit TIMESTAMP,
        werte numeric
    )
    ON COMMIT DROP;

    -- Get input xml data
    SELECT xml FROM station_data.input_lubw INTO myxml;


  /* Start parsing through xml file via xpath
  Structure: 
  Messstelle - Metainfo for Station
  DatenTyp + Komponente: Metainfo for component lookup table
  DatenReihe: Actual measurement data  
  */
  FOREACH messstelle IN ARRAY xpath('//Messstelle/@Name', myxml) LOOP
    FOREACH i IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']', myxml) LOOP
    
            ms_name := messstelle;  
            ms_kurzname := (xpath('.//@KurzName', i))[1];           
            ms_eu := (xpath('.//@EUKenn', i))[1];
            ms_nuts := (xpath('.//@NUTS', i))[1];
            ms_rw := (xpath('.//@RW', i))[1];
            ms_hw := (xpath('.//@HW', i))[1];
            ms_abrufzeit := (xpath('.//@AbrufZeiger', i))[1];

            -- Build station info, coordinates from DHDN (EPSG 41367) and insert into lookup table
            INSERT INTO station_data.lut_station (station_code, station_name, eu_id, nuts_id, region, last_updated, wkb_geometry)
                VALUES ( ms_kurzname, ms_name, ms_eu, ms_nuts, 'BW', now(),
                        st_transform(st_setsrid(st_makepoint(ms_rw, ms_hw),31467), 3035)::public.geometry(POINT,3035)
                       ) 
                ON CONFLICT DO NOTHING;


            FOREACH datentyp IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp/@AD-Name', myxml) LOOP
                FOREACH i IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']', myxml) LOOP
                    
                    ad_name := datentyp;
                    k_name := (xpath('.//Komponente/@Name', i))[1];      
                    k_kurzname := (xpath('.//Komponente/@KurzName', i))[1];
                    k_kompkenn := (xpath('.//Komponente/@KompKenn', i))[1];
                    k_nachweisgrenze := (xpath('.//Komponente/@NachweisGrenze', i))[1];
                    k_einheit := (xpath('.//Komponente/@Einheit', i))[1];
                    mess_tag := (xpath('.//DatenReihe/@ZeitPunkt', i))[1];

                    -- Build component metainfo from Komponente key and insert into lookup table
                    INSERT INTO station_data.lut_component (component_name, component_name_short, unit, threshold, lubw_code)
                        VALUES (ad_name, k_kurzname, k_einheit, k_nachweisgrenze,k_kompkenn)
                        ON CONFLICT DO NOTHING;


                    FOREACH wert IN ARRAY xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']/Komponente/DatenReihe/Wert//text()', myxml) LOOP
                            
                        /* 
                        Extract time series data
                        Instead of directly extracting timestamp (issue: 24:00 hour mark), use iterator curr_hour to count up
                        */ 
                        curr_hour := curr_hour + interval '1 hour';
                        time_stamp := (mess_tag||' '||curr_hour)::TIMESTAMP;

                        -- Insert data into temporary table, omit NULL values (-999 in xml) 
                        INSERT INTO output_tmp (ms_eu, ad_name, ko_name, zeit, werte)
                          SELECT ms_eu, ad_name, k_name, time_stamp,wert
                          WHERE wert <> -999
                          ON CONFLICT DO NOTHING;
                        
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
  
  -- Get relevant lookup table foreign keys and insert time series data into table
  WITH 
  lut_stat AS
  (SELECT * from station_data.lut_station)
  ,
  lut_co AS
  (SELECT * from station_data.lut_component)

  INSERT INTO station_data.tab_measurement 
    (
    fk_station, 
    fk_component, 
    date_time,  
    val
    )

  SELECT 
    lut_stat.idpk_station, 
    lut_co.idpk_component, 
    output_tmp.zeit, 
    output_tmp.werte
  
  FROM output_tmp
    JOIN lut_stat ON output_tmp.ms_eu = lut_stat.eu_id
    JOIN lut_co on output_tmp.ad_name = lut_co.component_name
    ON CONFLICT DO NOTHING;
  
  -- Update latest station update
  UPDATE station_data.lut_station
    SET last_updated = now()
    FROM output_tmp tmp
    WHERE lut_station.eu_id = tmp.ms_eu;

  -- Create logtable entry
  SELECT COUNT(werte) INTO zaehler FROM output_tmp;
  logentry_payload = '{"source":"lubw","timestamp":"'||ms_abrufzeit||'", "n_vals":"'||zaehler||'"}';
  EXECUTE FORMAT ('SELECT station_data.createlogentry(%L)',logentry_payload);
  
  TRUNCATE TABLE station_data.input_lubw;
  
  RAISE NOTICE 'Finished parsing % values (incl. NULL) from LUBW at %.', zaehler, now();

END;
$function$
;

GRANT EXECUTE ON FUNCTION station_data.lubw_parse() TO app;
ALTER FUNCTION station_data.lubw_parse() OWNER TO sauber_manager;
