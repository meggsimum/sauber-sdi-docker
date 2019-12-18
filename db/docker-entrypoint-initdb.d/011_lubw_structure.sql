SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;


CREATE DATABASE lubw_messstellen WITH TEMPLATE = template1;
ALTER DATABASE lubw_messstellen OWNER TO sauber_manager;

\c lubw_messstellen

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

ALTER DATABASE lubw_messstellen SET timescaledb.restoring='on';


CREATE SCHEMA daten;
ALTER SCHEMA daten OWNER TO sauber_manager;


CREATE TABLE IF NOT EXISTS daten.tab_werte (
    fk_messstelle integer NOT NULL,
    fk_datentyp integer NOT NULL,
    fk_komponenten integer NOT NULL,
    time_stamp timestamp without time zone NOT NULL,
    messwert double precision NOT NULL,
    idpk_werte integer NOT NULL
);

ALTER TABLE daten.tab_werte OWNER TO sauber_manager;


CREATE SEQUENCE daten.tab_werte_idpk_werte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE daten.tab_werte_idpk_werte_seq OWNER TO sauber_manager;

ALTER SEQUENCE daten.tab_werte_idpk_werte_seq OWNED BY daten.tab_werte.idpk_werte;


CREATE TABLE IF NOT EXISTS daten.logtable (
    idpk_log integer NOT NULL,
    log_ts timestamp(6) without time zone DEFAULT now() NOT NULL,
    log_entry jsonb NOT NULL
);
ALTER TABLE ONLY daten.logtable ALTER COLUMN log_ts SET STATISTICS 0;
ALTER TABLE ONLY daten.logtable ALTER COLUMN log_entry SET STATISTICS 0;
ALTER TABLE daten.logtable OWNER TO sauber_manager;


CREATE SEQUENCE daten.logtable_idpk_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE daten.logtable_idpk_log_seq OWNER TO sauber_manager;
ALTER SEQUENCE daten.logtable_idpk_log_seq OWNED BY daten.logtable.idpk_log;

CREATE TABLE IF NOT EXISTS daten.lut_datentyp (
    idpk_datentyp integer NOT NULL,
    ad_name character varying NOT NULL
);
ALTER TABLE daten.lut_datentyp OWNER TO sauber_manager;

CREATE SEQUENCE daten.lut_datentyp_idpk_datentyp_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE daten.lut_datentyp_idpk_datentyp_seq OWNER TO sauber_manager;
ALTER SEQUENCE daten.lut_datentyp_idpk_datentyp_seq OWNED BY daten.lut_datentyp.idpk_datentyp;


CREATE TABLE IF NOT EXISTS daten.lut_komponente (
    idpk_komponente integer NOT NULL,
    name_komponente character varying NOT NULL,
    kurzname character varying NOT NULL,
    kennung integer NOT NULL,
    nachweisgrenze text,
    einheit character varying
);
ALTER TABLE ONLY daten.lut_komponente ALTER COLUMN kurzname SET STATISTICS 0;
ALTER TABLE ONLY daten.lut_komponente ALTER COLUMN nachweisgrenze SET STATISTICS 0;
ALTER TABLE ONLY daten.lut_komponente ALTER COLUMN einheit SET STATISTICS 0;
ALTER TABLE daten.lut_komponente OWNER TO sauber_manager;

CREATE SEQUENCE daten.lut_komponente_idpk_komponente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE daten.lut_komponente_idpk_komponente_seq OWNER TO sauber_manager;
ALTER SEQUENCE daten.lut_komponente_idpk_komponente_seq OWNED BY daten.lut_komponente.idpk_komponente;


CREATE FUNCTION daten.extractfromxml() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
    hour TIME := '23:59:59';
    
    wert numeric;    
  	i xml;
    zaehler integer;
    logentry_payload jsonb;

BEGIN
	
    CREATE TEMP TABLE output_tmp (
        ms_eu TEXT,
        ad_name TEXT,
        ko_name TEXT,
        zeit TIMESTAMP,
        werte numeric
    )
    ON COMMIT DROP;

    SELECT xml FROM daten.input_xml INTO myxml ;
    --ORDER BY idpk_xml DESC 
	--LIMIT 1;

	FOREACH messstelle in array xpath('//Messstelle/@Name', myxml) LOOP
    FOREACH i in array xpath('.//Messstelle[@Name='''||messstelle||''']', myxml) LOOP
    
            ms_name := messstelle;  
            ms_kurzname := (xpath('.//@KurzName', i))[1];           
            ms_eu := (xpath('.//@EUKenn', i))[1];
            ms_nuts := (xpath('.//@NUTS', i))[1];
            ms_rw := (xpath('.//@RW', i))[1];
            ms_hw := (xpath('.//@HW', i))[1];
			ms_abrufzeit := (xpath('.//@AbrufZeiger', i))[1];

            INSERT INTO daten.fcp_messstellen (name_ms, name_kurz, eu_kenn, nuts, rw, hw , wkb_geometry)
                VALUES (ms_name, ms_kurzname, ms_eu, ms_nuts, ms_rw, ms_hw,
                        st_transform(st_setsrid(st_makepoint(ms_rw, ms_hw),31467), 4326)::public.geometry(POINT,4326)
                       ) 
                ON CONFLICT DO NOTHING;


            FOREACH datentyp in array xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp/@AD-Name', myxml) LOOP
                FOREACH i in array xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']', myxml) LOOP
                    
                    ad_name := datentyp;
                    k_name := (xpath('.//Komponente/@Name', i))[1];      
                    k_kurzname := (xpath('.//Komponente/@KurzName', i))[1];
                    k_kompkenn := (xpath('.//Komponente/@KompKenn', i))[1];
                    k_nachweisgrenze := (xpath('.//Komponente/@NachweisGrenze', i))[1];
                    k_einheit := (xpath('.//Komponente/@Einheit', i))[1];
                    mess_tag := (xpath('.//DatenReihe/@ZeitPunkt', i))[1];

                    INSERT INTO daten.lut_datentyp (ad_name)
                        VALUES (ad_name)
                        ON CONFLICT DO NOTHING;

                    INSERT INTO daten.lut_komponente (name_komponente, kurzname, kennung, nachweisgrenze, einheit)
                        VALUES (k_name, k_kurzname, k_kompkenn,k_nachweisgrenze,k_einheit)
                        ON CONFLICT DO NOTHING;


                    FOREACH wert in array xpath('.//Messstelle[@Name='''||messstelle||''']/DatenTyp[@AD-Name='''||datentyp||''']/Komponente/DatenReihe/Wert//text()', myxml) LOOP
                            
                        hour := hour + interval '1 hour';
                        time_stamp := (mess_tag||' '||hour)::TIMESTAMP;
						

                        INSERT INTO output_tmp (ms_eu, ad_name, ko_name, zeit, werte)
                        	SELECT ms_eu, ad_name, k_name, time_stamp,wert
                            WHERE wert <> -999
                            ON CONFLICT DO NOTHING;
                        
                    END LOOP;
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;


    WITH 
    lut_ms AS
    (SELECT * from daten.fcp_messstellen)
    ,
    lut_dt AS
    (SELECT * from daten.lut_datentyp)
    ,
    lut_ko AS
    (SELECT * from daten.lut_komponente)

    INSERT INTO daten.tab_werte (fk_messstelle, fk_datentyp, fk_komponenten, time_stamp, messwert)

    SELECT
    lut_ms.idpk_messstelle, lut_dt.idpk_datentyp, lut_ko.idpk_komponente,
    output_tmp.zeit, output_tmp.werte
    
    FROM output_tmp
    JOIN lut_ms ON output_tmp.ms_eu = lut_ms.eu_kenn
    JOIN lut_dt on output_tmp.ad_name = lut_dt.ad_name
    JOIN lut_ko on output_tmp.ko_name =  lut_ko.name_komponente
    ON CONFLICT DO NOTHING;

	SELECT COUNT(werte) INTO zaehler FROM output_tmp;
    logentry_payload = '{"Abrufzeit":"'||ms_abrufzeit||'. In Datei: '||zaehler||' gueltige Werte"}';
    EXECUTE FORMAT ('SELECT daten.createlogentry(%L)',logentry_payload);


    TRUNCATE TABLE daten.input_xml;

END;
$$;


ALTER FUNCTION daten.extractfromxml() OWNER TO sauber_manager;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE IF NOT EXISTS daten.fcp_messstellen (
    idpk_messstelle integer NOT NULL,
    name_ms character varying NOT NULL,
    name_kurz character varying(8) NOT NULL,
    eu_kenn character varying NOT NULL,
    nuts character varying(7) NOT NULL,
    rw integer NOT NULL,
    hw integer NOT NULL,
    wkb_geometry public.geometry(Point,4326)
);


ALTER TABLE daten.fcp_messstellen OWNER TO sauber_manager;

CREATE SEQUENCE daten.fcp_messstellen_idpk_messstelle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE daten.fcp_messstellen_idpk_messstelle_seq OWNER TO sauber_manager;
ALTER SEQUENCE daten.fcp_messstellen_idpk_messstelle_seq OWNED BY daten.fcp_messstellen.idpk_messstelle;

CREATE VIEW daten.fvp_no2_lastweek AS
SELECT
    NULL::integer AS idpk_messstelle,
    NULL::double precision AS kw,
    NULL::double precision AS max,
    NULL::double precision AS min,
    NULL::double precision AS avg,
    NULL::public.geometry(Point,4326) AS wkb_geometry;
ALTER TABLE daten.fvp_no2_lastweek OWNER TO postgres;

CREATE TABLE IF NOT EXISTS daten.input_xml (
    xml xml
);
ALTER TABLE daten.input_xml OWNER TO sauber_manager;



CREATE FUNCTION daten.createlogentry(pload jsonb DEFAULT '{"none": "none"}'::jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    json_payload ALIAS for $1 ;
  BEGIN
   EXECUTE FORMAT (
          '
          insert into daten.logtable (log_entry) VALUES (%L)
          ', json_payload
           );

  END;
$_$;
ALTER FUNCTION daten.createlogentry(pload jsonb) OWNER TO sauber_manager;



CREATE VIEW daten.view_no2 AS
 SELECT DISTINCT ON (g.idpk_messstelle) g.idpk_messstelle,
    g.name_ms AS name_messstelle,
    g.name_kurz AS kurzname,
    g.eu_kenn AS eu_kennung,
    werte.messwert,
    werte.time_stamp AS messzeit,
    lk.name_komponente AS komponentenname,
    lt.ad_name AS datentyp,
    lk.nachweisgrenze,
    lk.einheit,
    g.wkb_geometry
   FROM (((daten.lut_datentyp lt
     JOIN daten.tab_werte werte ON ((lt.idpk_datentyp = werte.fk_datentyp)))
     JOIN daten.lut_komponente lk ON ((werte.fk_komponenten = lk.idpk_komponente)))
     JOIN daten.fcp_messstellen g ON ((werte.fk_messstelle = g.idpk_messstelle)))
  WHERE ((lt.ad_name)::text = 'NO2 1h-MW gerundet'::text)
  ORDER BY g.idpk_messstelle, werte.time_stamp DESC;


ALTER TABLE daten.view_no2 OWNER TO sauber_user;

CREATE VIEW daten.view_pm10 AS
 SELECT DISTINCT ON (ms.name_ms) ms.name_ms AS name_messstelle,
    ms.name_kurz AS kurzname,
    ms.eu_kenn AS eu_kennung,
    tw.messwert,
    tw.time_stamp AS messzeit,
    ko.name_komponente AS komponentenname,
    dt.ad_name AS datentyp,
    ko.nachweisgrenze,
    ko.einheit,
    ms.wkb_geometry
   FROM (((daten.lut_datentyp dt
     JOIN daten.tab_werte tw ON ((dt.idpk_datentyp = tw.fk_datentyp)))
     JOIN daten.lut_komponente ko ON ((tw.fk_komponenten = ko.idpk_komponente)))
     JOIN daten.fcp_messstellen ms ON ((tw.fk_messstelle = ms.idpk_messstelle)))
  WHERE ((dt.ad_name)::text = 'PM10k 24h-MW gleitend gerundet'::text)
  ORDER BY ms.name_ms, tw.time_stamp DESC;


ALTER TABLE daten.view_pm10 OWNER TO sauber_user;

CREATE VIEW daten.view_so2 AS
 SELECT DISTINCT ON (fcp_messstellen.name_ms) fcp_messstellen.name_ms AS name_messstelle,
    fcp_messstellen.name_kurz AS kurzname,
    fcp_messstellen.eu_kenn AS eu_kennung,
    tab_werte.messwert,
    tab_werte.time_stamp AS messzeit,
    lut_komponente.name_komponente AS komponentenname,
    lut_datentyp.ad_name AS datentyp,
    lut_komponente.nachweisgrenze,
    lut_komponente.einheit,
    fcp_messstellen.wkb_geometry
   FROM (((daten.lut_datentyp
     JOIN daten.tab_werte ON ((lut_datentyp.idpk_datentyp = tab_werte.fk_datentyp)))
     JOIN daten.lut_komponente ON ((tab_werte.fk_komponenten = lut_komponente.idpk_komponente)))
     JOIN daten.fcp_messstellen ON ((tab_werte.fk_messstelle = fcp_messstellen.idpk_messstelle)))
  WHERE ((lut_datentyp.ad_name)::text = 'SO2 1h-MW gerundet'::text)
  ORDER BY fcp_messstellen.name_ms, tab_werte.time_stamp DESC;


ALTER TABLE daten.view_so2 OWNER TO sauber_user;

ALTER TABLE ONLY daten.fcp_messstellen ALTER COLUMN idpk_messstelle SET DEFAULT nextval('daten.fcp_messstellen_idpk_messstelle_seq'::regclass);

ALTER TABLE ONLY daten.logtable ALTER COLUMN idpk_log SET DEFAULT nextval('daten.logtable_idpk_log_seq'::regclass);

ALTER TABLE ONLY daten.lut_datentyp ALTER COLUMN idpk_datentyp SET DEFAULT nextval('daten.lut_datentyp_idpk_datentyp_seq'::regclass);

ALTER TABLE ONLY daten.lut_komponente ALTER COLUMN idpk_komponente SET DEFAULT nextval('daten.lut_komponente_idpk_komponente_seq'::regclass);

ALTER TABLE ONLY daten.tab_werte ALTER COLUMN idpk_werte SET DEFAULT nextval('daten.tab_werte_idpk_werte_seq'::regclass);

ALTER TABLE ONLY daten.fcp_messstellen
    ADD CONSTRAINT fcp_messstellen_eu_kenn_key UNIQUE (eu_kenn);

ALTER TABLE ONLY daten.fcp_messstellen
    ADD CONSTRAINT fcp_messstellen_name_kurz_key UNIQUE (name_kurz);

ALTER TABLE ONLY daten.fcp_messstellen
    ADD CONSTRAINT fcp_messstellen_pkey PRIMARY KEY (idpk_messstelle);

ALTER TABLE ONLY daten.logtable
    ADD CONSTRAINT logtable_pkey PRIMARY KEY (idpk_log);

ALTER TABLE ONLY daten.lut_datentyp
    ADD CONSTRAINT lut_datentyp_ad_name_key UNIQUE (ad_name);

ALTER TABLE ONLY daten.lut_datentyp
    ADD CONSTRAINT lut_datentyp_pkey PRIMARY KEY (idpk_datentyp);

ALTER TABLE ONLY daten.lut_komponente
    ADD CONSTRAINT lut_komponente_kennung_key UNIQUE (kennung);

ALTER TABLE ONLY daten.lut_komponente
    ADD CONSTRAINT lut_komponente_kurzname_key UNIQUE (kurzname);

ALTER TABLE ONLY daten.lut_komponente
    ADD CONSTRAINT lut_komponente_name_komponente_key UNIQUE (name_komponente);

ALTER TABLE ONLY daten.lut_komponente
    ADD CONSTRAINT lut_komponente_pkey PRIMARY KEY (idpk_komponente);

CREATE UNIQUE INDEX time_stamp_unique_messwerte ON daten.tab_werte USING btree (messwert, time_stamp, fk_komponenten, fk_datentyp, fk_messstelle);

CREATE OR REPLACE VIEW daten.fvp_no2_lastweek AS
 WITH vals AS (
         SELECT v.fk_messstelle,
            date_part('week'::text, v.time_stamp) AS kw,
            v.messwert
           FROM daten.tab_werte v
          WHERE ((date_part('year'::text, v.time_stamp) = date_part('year'::text, CURRENT_DATE)) AND (date_part('week'::text, v.time_stamp) = (date_part('week'::text, CURRENT_DATE) - (1)::double precision)) AND (v.fk_datentyp = 1) AND (v.fk_komponenten = 1))
        )
 SELECT g.idpk_messstelle,
    vals.kw,
    max(vals.messwert) AS max,
    min(vals.messwert) AS min,
    avg(vals.messwert) AS avg,
    g.wkb_geometry
   FROM (daten.fcp_messstellen g
     JOIN vals ON ((g.idpk_messstelle = vals.fk_messstelle)))
  GROUP BY g.idpk_messstelle, vals.kw;

ALTER TABLE ONLY daten.tab_werte
    ADD CONSTRAINT fk_datentyp FOREIGN KEY (fk_datentyp) REFERENCES daten.lut_datentyp(idpk_datentyp);

ALTER TABLE ONLY daten.tab_werte
    ADD CONSTRAINT fk_komponenten FOREIGN KEY (fk_komponenten) REFERENCES daten.lut_komponente(idpk_komponente);

ALTER TABLE ONLY daten.tab_werte
    ADD CONSTRAINT fk_messstelle FOREIGN KEY (fk_messstelle) REFERENCES daten.fcp_messstellen(idpk_messstelle);


ALTER TABLE ONLY daten.tab_werte 
    ADD CONSTRAINT werte_hypertable_key PRIMARY KEY (idpk_werte,time_stamp);

SELECT create_hypertable('daten.tab_werte', 'time_stamp');

ALTER DATABASE lubw_messstellen SET timescaledb.restoring='off';
\c postgres;