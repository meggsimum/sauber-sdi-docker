SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE DATABASE here WITH TEMPLATE = template1;

\c here;

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

ALTER DATABASE lubw_messstellen SET timescaledb.restoring='on';

CREATE SCHEMA here_traffic;
CREATE SCHEMA temp_import;

CREATE TABLE IF NOT EXISTS here_traffic.traffic_all_60min (
    id_pk bigint NOT NULL,
    link_id integer,
    dir_travel character(1),
    datum_zeit timestamp without time zone,
    weekday_n smallint,
    epoch_60 smallint,
    laenge_m smallint,
    freeflow_kmh smallint,
    speedlimit_kmh smallint,
    count_n smallint,
    mean_kmh double precision,
    stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint,
    gapfill character(1),
    region_code integer
);
ALTER TABLE here_traffic.traffic_all_60min OWNER TO sauber_user;


CREATE TABLE IF NOT EXISTS temp_import.fcl_streets_g3 (
    gid integer NOT NULL,
    link_id bigint,
    st_name character varying(120),
    feat_id bigint,
    st_langcd character varying(3),
    num_stnmes integer,
    st_nm_pref character varying(6),
    st_typ_bef character varying(50),
    st_nm_base character varying(70),
    st_nm_suff character varying(6),
    st_typ_aft character varying(50),
    st_typ_att character varying(1),
    addr_type character varying(1),
    l_refaddr character varying(10),
    l_nrefaddr character varying(10),
    l_addrsch character varying(1),
    l_addrform character varying(2),
    r_refaddr character varying(10),
    r_nrefaddr character varying(10),
    r_addrsch character varying(1),
    r_addrform character varying(2),
    ref_in_id bigint,
    nref_in_id bigint,
    n_shapepnt bigint,
    func_class character varying(1),
    speed_cat character varying(1),
    fr_spd_lim bigint,
    to_spd_lim bigint,
    to_lanes integer,
    from_lanes integer,
    enh_geom character varying(1),
    lane_cat character varying(1),
    divider character varying(1),
    dir_travel character varying(1),
    l_area_id bigint,
    r_area_id bigint,
    l_postcode character varying(11),
    r_postcode character varying(11),
    l_numzones integer,
    r_numzones integer,
    num_ad_rng integer,
    ar_auto character varying(1),
    ar_bus character varying(1),
    ar_taxis character varying(1),
    ar_carpool character varying(1),
    ar_pedest character varying(1),
    ar_trucks character varying(1),
    ar_traff character varying(1),
    ar_deliv character varying(1),
    ar_emerveh character varying(1),
    ar_motor character varying(1),
    paved character varying(1),
    private character varying(1),
    frontage character varying(1),
    bridge character varying(1),
    tunnel character varying(1),
    ramp character varying(1),
    tollway character varying(1),
    poiaccess character varying(1),
    contracc character varying(1),
    roundabout character varying(1),
    interinter character varying(1),
    undeftraff character varying(1),
    ferry_type character varying(1),
    multidigit character varying(1),
    maxattr character varying(1),
    spectrfig character varying(1),
    indescrib character varying(1),
    manoeuvre character varying(1),
    dividerleg character varying(1),
    inprocdata character varying(1),
    full_geom character varying(1),
    urban character varying(1),
    route_type character varying(1),
    dironsign character varying(1),
    explicatbl character varying(1),
    nameonrdsn character varying(1),
    postalname character varying(1),
    stalename character varying(1),
    vanityname character varying(1),
    junctionnm character varying(1),
    exitname character varying(1),
    scenic_rt character varying(1),
    scenic_nm character varying(1),
    fourwhldr character varying(1),
    coverind character varying(2),
    plot_road character varying(1),
    reversible character varying(1),
    expr_lane character varying(1),
    carpoolrd character varying(1),
    phys_lanes integer,
    ver_trans character varying(1),
    pub_access character varying(1),
    low_mblty character varying(1),
    priorityrd character varying(1),
    spd_lm_src character varying(2),
    expand_inc character varying(1),
    trans_area character varying(1),
    wkb_geometry public.geometry(MultiLineString,25832)
);
ALTER TABLE temp_import.fcl_streets_g3 OWNER TO sauber_user;

CREATE SEQUENCE temp_import.fcl_streets_g3_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE temp_import.fcl_streets_g3_gid_seq OWNER TO sauber_user;

ALTER SEQUENCE temp_import.fcl_streets_g3_gid_seq OWNED BY temp_import.fcl_streets_g3.gid;
CREATE TABLE IF NOT EXISTS temp_import.fcl_streets_g6 (
    gid integer NOT NULL,
    link_id bigint,
    st_name character varying(120),
    feat_id bigint,
    st_langcd character varying(3),
    num_stnmes integer,
    st_nm_pref character varying(6),
    st_typ_bef character varying(50),
    st_nm_base character varying(70),
    st_nm_suff character varying(6),
    st_typ_aft character varying(50),
    st_typ_att character varying(1),
    addr_type character varying(1),
    l_refaddr character varying(10),
    l_nrefaddr character varying(10),
    l_addrsch character varying(1),
    l_addrform character varying(2),
    r_refaddr character varying(10),
    r_nrefaddr character varying(10),
    r_addrsch character varying(1),
    r_addrform character varying(2),
    ref_in_id bigint,
    nref_in_id bigint,
    n_shapepnt bigint,
    func_class character varying(1),
    speed_cat character varying(1),
    fr_spd_lim bigint,
    to_spd_lim bigint,
    to_lanes integer,
    from_lanes integer,
    enh_geom character varying(1),
    lane_cat character varying(1),
    divider character varying(1),
    dir_travel character varying(1),
    l_area_id bigint,
    r_area_id bigint,
    l_postcode character varying(11),
    r_postcode character varying(11),
    l_numzones integer,
    r_numzones integer,
    num_ad_rng integer,
    ar_auto character varying(1),
    ar_bus character varying(1),
    ar_taxis character varying(1),
    ar_carpool character varying(1),
    ar_pedest character varying(1),
    ar_trucks character varying(1),
    ar_traff character varying(1),
    ar_deliv character varying(1),
    ar_emerveh character varying(1),
    ar_motor character varying(1),
    paved character varying(1),
    private character varying(1),
    frontage character varying(1),
    bridge character varying(1),
    tunnel character varying(1),
    ramp character varying(1),
    tollway character varying(1),
    poiaccess character varying(1),
    contracc character varying(1),
    roundabout character varying(1),
    interinter character varying(1),
    undeftraff character varying(1),
    ferry_type character varying(1),
    multidigit character varying(1),
    maxattr character varying(1),
    spectrfig character varying(1),
    indescrib character varying(1),
    manoeuvre character varying(1),
    dividerleg character varying(1),
    inprocdata character varying(1),
    full_geom character varying(1),
    urban character varying(1),
    route_type character varying(1),
    dironsign character varying(1),
    explicatbl character varying(1),
    nameonrdsn character varying(1),
    postalname character varying(1),
    stalename character varying(1),
    vanityname character varying(1),
    junctionnm character varying(1),
    exitname character varying(1),
    scenic_rt character varying(1),
    scenic_nm character varying(1),
    fourwhldr character varying(1),
    coverind character varying(2),
    plot_road character varying(1),
    reversible character varying(1),
    expr_lane character varying(1),
    carpoolrd character varying(1),
    phys_lanes integer,
    ver_trans character varying(1),
    pub_access character varying(1),
    low_mblty character varying(1),
    priorityrd character varying(1),
    spd_lm_src character varying(2),
    expand_inc character varying(1),
    trans_area character varying(1),
    wkb_geometry public.geometry(MultiLineString,25832)
);
ALTER TABLE temp_import.fcl_streets_g6 OWNER TO sauber_user;

CREATE SEQUENCE temp_import.fcl_streets_g6_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE temp_import.fcl_streets_g6_gid_seq OWNER TO sauber_user;

ALTER SEQUENCE temp_import.fcl_streets_g6_gid_seq OWNED BY temp_import.fcl_streets_g6.gid;
CREATE TABLE IF NOT EXISTS temp_import.fcl_streets_g7 (
    gid integer NOT NULL,
    link_id bigint,
    st_name character varying(120),
    feat_id bigint,
    st_langcd character varying(3),
    num_stnmes integer,
    st_nm_pref character varying(6),
    st_typ_bef character varying(50),
    st_nm_base character varying(70),
    st_nm_suff character varying(6),
    st_typ_aft character varying(50),
    st_typ_att character varying(1),
    addr_type character varying(1),
    l_refaddr character varying(10),
    l_nrefaddr character varying(10),
    l_addrsch character varying(1),
    l_addrform character varying(2),
    r_refaddr character varying(10),
    r_nrefaddr character varying(10),
    r_addrsch character varying(1),
    r_addrform character varying(2),
    ref_in_id bigint,
    nref_in_id bigint,
    n_shapepnt bigint,
    func_class character varying(1),
    speed_cat character varying(1),
    fr_spd_lim bigint,
    to_spd_lim bigint,
    to_lanes integer,
    from_lanes integer,
    enh_geom character varying(1),
    lane_cat character varying(1),
    divider character varying(1),
    dir_travel character varying(1),
    l_area_id bigint,
    r_area_id bigint,
    l_postcode character varying(11),
    r_postcode character varying(11),
    l_numzones integer,
    r_numzones integer,
    num_ad_rng integer,
    ar_auto character varying(1),
    ar_bus character varying(1),
    ar_taxis character varying(1),
    ar_carpool character varying(1),
    ar_pedest character varying(1),
    ar_trucks character varying(1),
    ar_traff character varying(1),
    ar_deliv character varying(1),
    ar_emerveh character varying(1),
    ar_motor character varying(1),
    paved character varying(1),
    private character varying(1),
    frontage character varying(1),
    bridge character varying(1),
    tunnel character varying(1),
    ramp character varying(1),
    tollway character varying(1),
    poiaccess character varying(1),
    contracc character varying(1),
    roundabout character varying(1),
    interinter character varying(1),
    undeftraff character varying(1),
    ferry_type character varying(1),
    multidigit character varying(1),
    maxattr character varying(1),
    spectrfig character varying(1),
    indescrib character varying(1),
    manoeuvre character varying(1),
    dividerleg character varying(1),
    inprocdata character varying(1),
    full_geom character varying(1),
    urban character varying(1),
    route_type character varying(1),
    dironsign character varying(1),
    explicatbl character varying(1),
    nameonrdsn character varying(1),
    postalname character varying(1),
    stalename character varying(1),
    vanityname character varying(1),
    junctionnm character varying(1),
    exitname character varying(1),
    scenic_rt character varying(1),
    scenic_nm character varying(1),
    fourwhldr character varying(1),
    coverind character varying(2),
    plot_road character varying(1),
    reversible character varying(1),
    expr_lane character varying(1),
    carpoolrd character varying(1),
    phys_lanes integer,
    ver_trans character varying(1),
    pub_access character varying(1),
    low_mblty character varying(1),
    priorityrd character varying(1),
    spd_lm_src character varying(2),
    expand_inc character varying(1),
    trans_area character varying(1),
    wkb_geometry public.geometry(MultiLineString,25832)
);
ALTER TABLE temp_import.fcl_streets_g7 OWNER TO sauber_user;

CREATE SEQUENCE temp_import.fcl_streets_g7_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE temp_import.fcl_streets_g7_gid_seq OWNER TO sauber_user;

ALTER SEQUENCE temp_import.fcl_streets_g7_gid_seq OWNED BY temp_import.fcl_streets_g7.gid;
CREATE TABLE IF NOT EXISTS temp_import.traffic_import (
    link_id character(11) NOT NULL,
    datum_zeit timestamp without time zone,
    epoch_60 smallint,
    laenge_m integer,
    freeflow_kmh double precision,
    speedlimit_kmh character varying(3),
    count_n smallint,
    mean_kmh double precision,
    stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint
);
ALTER TABLE temp_import.traffic_import OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.traffic_all_60min (
    id_pk bigint NOT NULL,
    link_id integer,
    dir_travel character(1),
    datum_zeit timestamp without time zone,
    weekday_n smallint,
    epoch_60 smallint,
    laenge_m smallint,
    freeflow_kmh smallint,
    speedlimit_kmh smallint,
    count_n smallint,
    mean_kmh double precision,
    stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint,
    gapfill character(1),
    region_code integer
);
ALTER TABLE here_traffic.traffic_all_60min OWNER TO sauber_user;

CREATE SEQUENCE here_traffic.traffic_all_60min_id_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE here_traffic.traffic_all_60min_id_pk_seq OWNER TO sauber_user;


CREATE TABLE here_traffic.traffic_all_60min_q1_v_01 (
    id_pk integer,
    link_id integer,
    dir_travel character(1),
    datum_zeit timestamp without time zone NOT NULL,
    epoch_60 smallint,
    laenge_m smallint,
    freeflow_kmh smallint,
    speedlimit_kmh smallint,
    count_n smallint,
    mean_kmh double precision,
    stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint,
    gapfill character(1)
);


ALTER TABLE here_traffic.traffic_all_60min_q1_v_01 OWNER TO sauber_user;


CREATE TABLE here_traffic.traffic_all_60min_q1 (
    id_pk integer,
    link_id integer,
    dir_travel character(1),
    datum_zeit timestamp without time zone NOT NULL,
    weekday_n smallint,
    epoch_60 smallint,
    laenge_m smallint,
    freeflow_kmh smallint,
    speedlimit_kmh smallint,
    count_n smallint,
    mean_kmh double precision,
    stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint,
    gapfill character(1)
);


ALTER TABLE here_traffic.traffic_all_60min_q1 OWNER TO sauber_user;


CREATE INDEX traffic_all_60min_q1_datum_zeit_idx ON here_traffic.traffic_all_60min_q1_v_01 USING btree (datum_zeit DESC);


CREATE INDEX traffic_all_60min_q1_datum_zeit_idx1 ON here_traffic.traffic_all_60min_q1 USING btree (datum_zeit DESC);


CREATE INDEX traffic_all_60min_q1_idx ON here_traffic.traffic_all_60min_q1 USING btree (dir_travel);


CREATE INDEX traffic_all_60min_q1_idx1 ON here_traffic.traffic_all_60min_q1 USING btree (weekday_n);


CREATE INDEX traffic_all_60min_q1_idx2 ON here_traffic.traffic_all_60min_q1 USING btree (weekday_n);


CREATE INDEX traffic_all_60min_q1_link_id_datum_zeit_idx ON here_traffic.traffic_all_60min_q1_v_01 USING btree (link_id, datum_zeit DESC);


CREATE INDEX traffic_all_60min_q1_link_id_datum_zeit_idx1 ON here_traffic.traffic_all_60min_q1 USING btree (link_id, datum_zeit DESC);


CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON here_traffic.traffic_all_60min_q1_v_01 FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();


CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON here_traffic.traffic_all_60min_q1 FOR EACH ROW EXECUTE PROCEDURE _timescaledb_internal.insert_blocker();






ALTER SEQUENCE here_traffic.traffic_all_60min_id_pk_seq OWNED BY here_traffic.traffic_all_60min.id_pk;
CREATE FUNCTION here_traffic.create_mv_day_week(epoch_n integer, lower_wd integer, upper_wd integer) RETURNS void
    LANGUAGE plpgsql STRICT
    AS $_$
declare epoch ALIAS for $1;
declare wd_lower ALIAS for $2;
declare wd_upper ALIAS for $3;
declare epochstr text;
declare wd_lower_str text;
declare wd_upper_str text;
declare index1name text;
declare index2name text;
declare index3name text;

declare viewname text;
declare name_suffix text;
BEGIN
epochstr  = lpad(epoch::text,2,'0');
wd_lower_str = wd_lower::text;
wd_upper_str = wd_upper::text;
name_suffix = epochstr || '_' || wd_lower_str || '_' || wd_upper_str  ;

index1name = 'mv_traffic_workdays_pk_idx_' || name_suffix;
index2name = 'mv_traffic_workdays_link_idx_'  || name_suffix;
index3name = 'mv_traffic_workdays_tf_didx_'  || name_suffix;

viewname =   'here_traffic.mv_traffic_'   || name_suffix;

RAISE NOTICE  'Creating : %', viewname;

EXECUTE 
'
create MATERIALIZED VIEW ' || viewname ||' as
WITH at_epoch AS(
  SELECT t.link_id,
         t.dir_travel, 
         
         t.freeflow_kmh,
         t.mean_kmh,
         t.min_kmh,
         t.max_kmh,
         t.count_n
  FROM here_traffic.traffic_all_60min_q1 t
  
       join here_traffic.fcl_streets s on t.link_id=s.link_id 
  
  WHERE t.epoch_60 =  ' || epoch || ' AND
        weekday_n  between ' || wd_lower || ' AND ' || wd_upper || ' 
        AND t.gapfill = ''N''::bpchar AND
        t.confidence > 5
        )
    SELECT row_number() OVER()::integer AS id,
           at_epoch.link_id,
           at_epoch.dir_travel,
           max(at_epoch.freeflow_kmh) AS freeflow_kmh,
           max(at_epoch.min_kmh) AS max_vonmin,
           min(at_epoch.min_kmh) AS min_vonmin,
           max(at_epoch.max_kmh) AS max_vonmax,
           min(at_epoch.max_kmh) AS min_vonmax,
           avg(at_epoch.mean_kmh) AS mean_mean
    FROM at_epoch
    GROUP BY at_epoch.link_id,
             at_epoch.dir_travel
  ' 
  ; 

RAISE NOTICE  'Created : %', viewname;
RAISE NOTICE  'Creating Index: %', index1name;
EXECUTE   ' CREATE UNIQUE INDEX ' || index1name || ' ON ' || viewname || '    USING btree (id)';
RAISE NOTICE  'Creating Index: %', index2name;
EXECUTE   ' CREATE  INDEX ' || index2name || ' ON ' || viewname || '    USING btree (link_id)';
RAISE NOTICE  'Creating Index: %', index3name;
EXECUTE   ' CREATE  INDEX ' || index3name || ' ON ' || viewname || '    USING btree (dir_travel)';
  RETURN;
END;
$_$;
ALTER FUNCTION here_traffic.create_mv_day_week(epoch_n integer, lower_wd integer, upper_wd integer) OWNER TO sauber_user;
CREATE FUNCTION here_traffic.insert_traffic() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

INSERT INTO here_traffic.lut_traffic_links (
    link_id  ,
  	laenge_m  ,
    freeflow_kmh ,
    speedlimit_kmh
    )
SELECT
	LEFT(i.link_id,(length(link_id)-1))::INTEGER,
 	laenge_m::SMALLINT AS laenge_m,
    freeflow_kmh::SMALLINT AS freeflow_kmh,
    NULLIF(speedlimit_kmh,'')::SMALLINT AS speedlimit_kmh
    FROM temp_import.traffic_import i
ON CONFLICT (link_id) DO NOTHING;
WITH lut AS (SELECT idpk_traffic_links FROM lut_traffic_links)
INSERT INTO here_traffic.car_60minuten
(
  fk_link,
  dir_travel,
  datum_zeit,
  weekday_n,
  count_n,
  mean_kmh,
  stats_stddev,
  min_kmh,
  max_kmh,
  confidence,
  id_region
)
SELECT
  lut.idpk_traffic_links,
  i.datum_zeit,
  EXTRACT(isodow FROM i.datum_zeit) AS weekday,
  i.count_n,
  i.mean_kmh,
  i.stddev::DOUBLE PRECISION AS stats_stddev,
  i.min_kmh,
  i.max_kmh,
  i.confidence,
  1 AS id_region

  FROM temp_import.traffic_import i
  JOIN lut ON i WHERE LEFT(i.link_id,(length(link_id)-1))::INTEGER = lut.link_id   ;
TRUNCATE TABLE temp_import.traffic_import;
END;
$$;
ALTER FUNCTION here_traffic.insert_traffic() OWNER TO sauber_user;

CREATE FUNCTION public.easter_day(p_year_in integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_k integer;
 v_m integer;
 v_s integer;
 v_a integer;
 v_d integer;
 v_r integer;
 v_og integer;
 v_sz integer;
 v_oe integer;
 v_os integer;
 v_day integer;
 v_month integer;
BEGIN
 v_k := floor(p_year_in / 100);
 v_m := 15 + floor((3 * v_k + 3) / 4) - floor((8 * v_k + 13) / 25);
 v_s := 2 - floor((3 * v_k + 3) / 4);
 --v_a := mod(p_year_in, 19);
 v_a := p_year_in % 19;
 --v_d := mod((19 * v_a + v_m), 30);
 v_d := (19 * v_a + v_m) % 30;
 v_r := floor(v_d / 29) + (floor(v_d / 28) - floor(v_d / 29)) * floor(v_a / 11);
 v_og := 21 + v_d - v_r;
-- v_sz := 7 - mod((p_year_in + floor(p_year_in / 4) + v_s), 7);
 v_sz := 7 - (p_year_in + floor(p_year_in / 4) + v_s)::INTEGER % 7;
-- v_oe := 7 - mod(v_og - v_sz, 7);
 v_oe := 7 - (v_og - v_sz) % 7;
 v_os := v_og + v_oe;
 if (v_os <= 31) then
  v_day := v_os;
  v_month := 3;
 else
  v_day := v_os - 31;
  v_month := 4;
 end if;
 return to_date(v_day || '.' || v_month || '.' || p_year_in, 'DD.MM.YYYY');

--EXCEPTION
--WHEN exception_name THEN
--  statements;
END;
$$;
ALTER FUNCTION public.easter_day(p_year_in integer) OWNER TO sauber_user;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE IF NOT EXISTS here_traffic.car_60minuten (
    id_pk bigint NOT NULL,
    fk_link integer NOT NULL,
    dir_travel character(1),
    datum_zeit timestamp without time zone NOT NULL,
    weekday_n smallint,
    laenge_m smallint,
    count_n smallint,
    mean_kmh double precision,
    stats_stddev double precision,
    min_kmh smallint,
    max_kmh smallint,
    confidence smallint,
    id_region smallint NOT NULL
);
ALTER TABLE here_traffic.car_60minuten OWNER TO postgres;

CREATE SEQUENCE here_traffic.car_60minuten_id_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE here_traffic.car_60minuten_id_pk_seq OWNER TO postgres;
ALTER SEQUENCE here_traffic.car_60minuten_id_pk_seq OWNED BY here_traffic.car_60minuten.id_pk;

CREATE TABLE IF NOT EXISTS here_traffic.fcl_streets (
    link_id integer NOT NULL,
    feat_id integer,
    func_class smallint,
    route_type character(1),
    phys_lanes smallint,
    st_name character varying(120),
    ref_in_id integer,
    nref_in_id integer,
    n_shapepnt smallint,
    speed_cat smallint,
    fr_spd_lim smallint,
    to_spd_lim smallint,
    to_lanes smallint,
    from_lanes smallint,
    lane_cat smallint,
    divider character(1),
    dir_travel character(1),
    ar_auto boolean,
    ar_bus boolean,
    ar_taxis boolean,
    ar_carpool boolean,
    ar_pedest boolean,
    ar_trucks boolean,
    ar_deliv boolean,
    ar_emerveh boolean,
    asar_motor boolean,
    ar_traff boolean,
    private boolean,
    bridge boolean,
    tunnel boolean,
    ramp boolean,
    roundabout boolean,
    paved boolean,
    interinter boolean,
    manoeuvre boolean,
    urban boolean,
    fourwhldr boolean,
    ver_trans boolean,
    pub_access boolean,
    spd_lm_src smallint,
    wkb_geometry public.geometry(MultiLineString,25832),
    CONSTRAINT traveldirection CHECK ((dir_travel = ANY (ARRAY['F'::bpchar, 'T'::bpchar, 'B'::bpchar])))
);
ALTER TABLE here_traffic.fcl_streets OWNER TO sauber_user;
CREATE TABLE IF NOT EXISTS here_traffic.fcl_traffic_weekend_from (
    id bigint NOT NULL,
    link_id integer,
    func_class smallint,
    dir_travel character(1),
    spd_lim smallint,
    length_m double precision,
    wkb_geometry public.geometry(MultiLineString,3857),
    t00 integer,
    t01 integer,
    t02 integer,
    t03 integer,
    t04 integer,
    t05 integer,
    t06 integer,
    t07 integer,
    t08 integer,
    t09 integer,
    t10 integer,
    t11 integer,
    t12 integer,
    t13 integer,
    t14 integer,
    t15 integer,
    t16 integer,
    t17 integer,
    t18 integer,
    t19 integer,
    t20 integer,
    t21 integer,
    t22 integer,
    t23 integer
);
ALTER TABLE here_traffic.fcl_traffic_weekend_from OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.fcl_traffic_weekend_to (
    id bigint NOT NULL,
    link_id integer,
    func_class smallint,
    dir_travel character(1),
    spd_lim smallint,
    length_m double precision,
    wkb_geometry public.geometry(MultiLineString,3857),
    t00 integer,
    t01 integer,
    t02 integer,
    t03 integer,
    t04 integer,
    t05 integer,
    t06 integer,
    t07 integer,
    t08 integer,
    t09 integer,
    t10 integer,
    t11 integer,
    t12 integer,
    t13 integer,
    t14 integer,
    t15 integer,
    t16 integer,
    t17 integer,
    t18 integer,
    t19 integer,
    t20 integer,
    t21 integer,
    t22 integer,
    t23 integer
);
ALTER TABLE here_traffic.fcl_traffic_weekend_to OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.fcl_traffic_workday_from (
    id bigint NOT NULL,
    link_id integer,
    func_class smallint,
    dir_travel character(1),
    spd_lim smallint,
    length_m double precision,
    wkb_geometry public.geometry(MultiLineString,3857),
    t00 integer,
    t01 integer,
    t02 integer,
    t03 integer,
    t04 integer,
    t05 integer,
    t06 integer,
    t07 integer,
    t08 integer,
    t09 integer,
    t10 integer,
    t11 integer,
    t12 integer,
    t13 integer,
    t14 integer,
    t15 integer,
    t16 integer,
    t17 integer,
    t18 integer,
    t19 integer,
    t20 integer,
    t21 integer,
    t22 integer,
    t23 integer
);
ALTER TABLE here_traffic.fcl_traffic_workday_from OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.fcl_traffic_workday_to (
    id bigint NOT NULL,
    link_id integer,
    func_class smallint,
    dir_travel character(1),
    spd_lim smallint,
    length_m double precision,
    wkb_geometry public.geometry(MultiLineString,3857),
    t00 integer,
    t01 integer,
    t02 integer,
    t03 integer,
    t04 integer,
    t05 integer,
    t06 integer,
    t07 integer,
    t08 integer,
    t09 integer,
    t10 integer,
    t11 integer,
    t12 integer,
    t13 integer,
    t14 integer,
    t15 integer,
    t16 integer,
    t17 integer,
    t18 integer,
    t19 integer,
    t20 integer,
    t21 integer,
    t22 integer,
    t23 integer
);
ALTER TABLE here_traffic.fcl_traffic_workday_to OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.lut_region (
    id_region integer NOT NULL,
    name_region character varying NOT NULL
);
ALTER TABLE here_traffic.lut_region OWNER TO sauber_user;

CREATE TABLE IF NOT EXISTS here_traffic.lut_traffic_links (
    idpk_traffic_links integer NOT NULL,
    link_id integer NOT NULL,
    laenge_m smallint NOT NULL,
    freeflow_kmh smallint,
    speedlimit_kmh smallint
);
ALTER TABLE here_traffic.lut_traffic_links OWNER TO postgres;

CREATE SEQUENCE here_traffic.lut_traffic_links_idpk_traffic_links_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE here_traffic.lut_traffic_links_idpk_traffic_links_seq OWNER TO postgres;

ALTER SEQUENCE here_traffic.lut_traffic_links_idpk_traffic_links_seq OWNED BY here_traffic.lut_traffic_links.idpk_traffic_links;
CREATE MATERIALIZED VIEW here_traffic.mv_traffic_00_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 0) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_00_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_00_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 0) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_00_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_01_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 1) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_01_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_01_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 1) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_01_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_02_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 2) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_02_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_02_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 2) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_02_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_03_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 3) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_03_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_03_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 3) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_03_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_04_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 4) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_04_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_04_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 4) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_04_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_05_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 5) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_05_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_05_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 5) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_05_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_06_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 6) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_06_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_06_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 6) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_06_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_07_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 7) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_07_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_07_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 7) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_07_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_08_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 8) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_08_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_08_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 8) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_08_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_09_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 9) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_09_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_09_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 9) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_09_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_10_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 10) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_10_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_10_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 10) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_10_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_11_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 11) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_11_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_11_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 11) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_11_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_12_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 12) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_12_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_12_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 12) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_12_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_13_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 13) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_13_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_13_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 13) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_13_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_14_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 14) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_14_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_14_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 14) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_14_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_15_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 15) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_15_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_15_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 15) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_15_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_16_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 16) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_16_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_16_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 16) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_16_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_17_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 17) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_17_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_17_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 17) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_17_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_18_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 18) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_18_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_18_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 18) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_18_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_19_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 19) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_19_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_19_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 19) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_19_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_20_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 20) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_20_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_20_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 20) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_20_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_21_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 21) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_21_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_21_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 21) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_21_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_22_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 22) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_22_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_22_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 22) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_22_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_23_1_5 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 23) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_23_1_5 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_23_6_7 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 23) AND ((t.weekday_n >= 6) AND (t.weekday_n <= 7)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_23_6_7 OWNER TO sauber_user;

CREATE MATERIALIZED VIEW here_traffic.mv_traffic_workdays_60 AS
 WITH at_epoch AS (
         SELECT t.link_id,
            t.dir_travel,
            t.freeflow_kmh,
            t.mean_kmh,
            t.min_kmh,
            t.max_kmh,
            t.count_n,
            date_part('dow'::text, t.datum_zeit) AS date_part
           FROM (here_traffic.traffic_all_60min_q1 t
             JOIN here_traffic.fcl_streets s ON ((t.link_id = s.link_id)))
          WHERE ((t.epoch_60 = 0) AND ((t.weekday_n >= 1) AND (t.weekday_n <= 5)) AND (t.gapfill = 'N'::bpchar) AND (t.confidence > 5))
        )
 SELECT (row_number() OVER ())::integer AS id,
    at_epoch.link_id,
    at_epoch.dir_travel,
    max(at_epoch.freeflow_kmh) AS freeflow_kmh,
    max(at_epoch.min_kmh) AS max_vonmin,
    min(at_epoch.min_kmh) AS min_vonmin,
    max(at_epoch.max_kmh) AS max_vonmax,
    min(at_epoch.max_kmh) AS min_vonmax,
    avg(at_epoch.mean_kmh) AS mean_mean
   FROM at_epoch
  GROUP BY at_epoch.link_id, at_epoch.dir_travel
  WITH NO DATA;
ALTER TABLE here_traffic.mv_traffic_workdays_60 OWNER TO sauber_user;
ALTER TABLE ONLY here_traffic.car_60minuten ALTER COLUMN id_pk SET DEFAULT nextval('here_traffic.car_60minuten_id_pk_seq'::regclass);

ALTER TABLE ONLY here_traffic.lut_traffic_links ALTER COLUMN idpk_traffic_links SET DEFAULT nextval('here_traffic.lut_traffic_links_idpk_traffic_links_seq'::regclass);

ALTER TABLE ONLY here_traffic.traffic_all_60min ALTER COLUMN id_pk SET DEFAULT nextval('here_traffic.traffic_all_60min_id_pk_seq'::regclass);

ALTER TABLE ONLY temp_import.fcl_streets_g3 ALTER COLUMN gid SET DEFAULT nextval('temp_import.fcl_streets_g3_gid_seq'::regclass);

ALTER TABLE ONLY temp_import.fcl_streets_g6 ALTER COLUMN gid SET DEFAULT nextval('temp_import.fcl_streets_g6_gid_seq'::regclass);

ALTER TABLE ONLY temp_import.fcl_streets_g7 ALTER COLUMN gid SET DEFAULT nextval('temp_import.fcl_streets_g7_gid_seq'::regclass);

ALTER TABLE ONLY here_traffic.car_60minuten
    ADD CONSTRAINT car_60minuten_pkey PRIMARY KEY (datum_zeit, id_region, id_pk);

ALTER TABLE ONLY here_traffic.fcl_streets
    ADD CONSTRAINT fcl_streets_pkey PRIMARY KEY (link_id);

ALTER TABLE ONLY here_traffic.fcl_traffic_weekend_from
    ADD CONSTRAINT fcl_traffic_weekend_from_pkey PRIMARY KEY (id);

ALTER TABLE ONLY here_traffic.fcl_traffic_weekend_to
    ADD CONSTRAINT fcl_traffic_weekend_to_pkey PRIMARY KEY (id);

ALTER TABLE ONLY here_traffic.fcl_traffic_workday_from
    ADD CONSTRAINT fcl_traffic_workday_from_pkey PRIMARY KEY (id);

ALTER TABLE ONLY here_traffic.fcl_traffic_workday_to
    ADD CONSTRAINT fcl_traffic_workday_to_pkey PRIMARY KEY (id);

ALTER TABLE ONLY here_traffic.lut_region
    ADD CONSTRAINT lut_region_name_region_key UNIQUE (name_region);

ALTER TABLE ONLY here_traffic.lut_region
    ADD CONSTRAINT lut_region_pkey PRIMARY KEY (id_region);

ALTER TABLE ONLY here_traffic.lut_traffic_links
    ADD CONSTRAINT lut_traffic_links_pkey PRIMARY KEY (idpk_traffic_links);

ALTER TABLE ONLY here_traffic.traffic_all_60min
    ADD CONSTRAINT traffic_all_60min_pkey PRIMARY KEY (id_pk);

ALTER TABLE ONLY temp_import.fcl_streets_g3
    ADD CONSTRAINT fcl_streets_g3_pkey PRIMARY KEY (gid);

ALTER TABLE ONLY temp_import.fcl_streets_g6
    ADD CONSTRAINT fcl_streets_g6_pkey PRIMARY KEY (gid);

ALTER TABLE ONLY temp_import.fcl_streets_g7
    ADD CONSTRAINT fcl_streets_g7_pkey PRIMARY KEY (gid);
CREATE INDEX car_60minuten_datum_zeit_idx ON here_traffic.car_60minuten USING btree (datum_zeit DESC);

CREATE INDEX car_60minuten_id_region_datum_zeit_idx ON here_traffic.car_60minuten USING btree (id_region, datum_zeit DESC);

CREATE INDEX fcl_streets_idx4 ON here_traffic.fcl_streets USING gist (wkb_geometry);

CREATE INDEX fcl_streets_idx_bridge ON here_traffic.fcl_streets USING btree (bridge);

CREATE INDEX fcl_streets_idx_dirtrvl ON here_traffic.fcl_streets USING btree (dir_travel);

CREATE INDEX fcl_streets_idx_fclass ON here_traffic.fcl_streets USING btree (func_class);

CREATE INDEX fcl_streets_idx_featid ON here_traffic.fcl_streets USING btree (feat_id);

CREATE INDEX fcl_streets_idx_flanes ON here_traffic.fcl_streets USING btree (from_lanes);

CREATE INDEX fcl_streets_idx_fspdlmt ON here_traffic.fcl_streets USING btree (fr_spd_lim);

CREATE INDEX fcl_streets_idx_lanecat ON here_traffic.fcl_streets USING btree (lane_cat);

CREATE INDEX fcl_streets_idx_nref ON here_traffic.fcl_streets USING btree (nref_in_id);

CREATE INDEX fcl_streets_idx_ref ON here_traffic.fcl_streets USING btree (ref_in_id);

CREATE INDEX fcl_streets_idx_routetype ON here_traffic.fcl_streets USING btree (route_type);

CREATE INDEX fcl_streets_idx_spdcat ON here_traffic.fcl_streets USING btree (speed_cat);

CREATE INDEX fcl_streets_idx_tlanes ON here_traffic.fcl_streets USING btree (to_lanes);

CREATE INDEX fcl_streets_idx_tspdlmt ON here_traffic.fcl_streets USING btree (to_spd_lim);

CREATE INDEX fcl_streets_idx_tunnel ON here_traffic.fcl_streets USING btree (tunnel);

CREATE INDEX fcl_streets_idx_urban ON here_traffic.fcl_streets USING btree (urban);

CREATE INDEX fcl_traffic_weekend_from_geoidx ON here_traffic.fcl_traffic_weekend_from USING gist (wkb_geometry);

CREATE UNIQUE INDEX fcl_traffic_weekend_from_link_idx ON here_traffic.fcl_traffic_weekend_from USING btree (link_id);

CREATE INDEX fcl_traffic_weekend_from_rd_class_idx ON here_traffic.fcl_traffic_weekend_from USING btree (func_class);

CREATE INDEX fcl_traffic_weekend_to_geoidx ON here_traffic.fcl_traffic_weekend_to USING gist (wkb_geometry);

CREATE UNIQUE INDEX fcl_traffic_weekend_to_link_idx ON here_traffic.fcl_traffic_weekend_to USING btree (link_id);

CREATE INDEX fcl_traffic_weekend_to_rd_class_idx ON here_traffic.fcl_traffic_weekend_to USING btree (func_class);

CREATE INDEX fcl_traffic_workday_from_geoidx ON here_traffic.fcl_traffic_workday_from USING gist (wkb_geometry);

CREATE UNIQUE INDEX fcl_traffic_workday_from_link_idx ON here_traffic.fcl_traffic_workday_from USING btree (link_id);

CREATE INDEX fcl_traffic_workday_from_rd_class_idx ON here_traffic.fcl_traffic_workday_from USING btree (func_class);

CREATE INDEX fcl_traffic_workday_to_geoidx ON here_traffic.fcl_traffic_workday_to USING gist (wkb_geometry);

CREATE UNIQUE INDEX fcl_traffic_workday_to_link_idx ON here_traffic.fcl_traffic_workday_to USING btree (link_id);

CREATE INDEX fcl_traffic_workday_to_rd_class_idx ON here_traffic.fcl_traffic_workday_to USING btree (func_class);

CREATE INDEX mv_traffic_workdays_link_idx_00_1_5 ON here_traffic.mv_traffic_00_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_00_6_7 ON here_traffic.mv_traffic_00_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_01_1_5 ON here_traffic.mv_traffic_01_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_01_6_7 ON here_traffic.mv_traffic_01_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_02_1_5 ON here_traffic.mv_traffic_02_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_02_6_7 ON here_traffic.mv_traffic_02_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_03_1_5 ON here_traffic.mv_traffic_03_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_03_6_7 ON here_traffic.mv_traffic_03_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_04_1_5 ON here_traffic.mv_traffic_04_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_04_6_7 ON here_traffic.mv_traffic_04_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_05_1_5 ON here_traffic.mv_traffic_05_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_05_6_7 ON here_traffic.mv_traffic_05_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_06_1_5 ON here_traffic.mv_traffic_06_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_06_6_7 ON here_traffic.mv_traffic_06_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_07_1_5 ON here_traffic.mv_traffic_07_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_07_6_7 ON here_traffic.mv_traffic_07_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_08_1_5 ON here_traffic.mv_traffic_08_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_08_6_7 ON here_traffic.mv_traffic_08_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_09_1_5 ON here_traffic.mv_traffic_09_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_09_6_7 ON here_traffic.mv_traffic_09_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_10_1_5 ON here_traffic.mv_traffic_10_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_10_6_7 ON here_traffic.mv_traffic_10_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_11_1_5 ON here_traffic.mv_traffic_11_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_11_6_7 ON here_traffic.mv_traffic_11_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_12_1_5 ON here_traffic.mv_traffic_12_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_12_6_7 ON here_traffic.mv_traffic_12_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_13_1_5 ON here_traffic.mv_traffic_13_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_13_6_7 ON here_traffic.mv_traffic_13_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_14_1_5 ON here_traffic.mv_traffic_14_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_14_6_7 ON here_traffic.mv_traffic_14_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_15_1_5 ON here_traffic.mv_traffic_15_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_15_6_7 ON here_traffic.mv_traffic_15_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_16_1_5 ON here_traffic.mv_traffic_16_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_16_6_7 ON here_traffic.mv_traffic_16_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_17_1_5 ON here_traffic.mv_traffic_17_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_17_6_7 ON here_traffic.mv_traffic_17_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_18_1_5 ON here_traffic.mv_traffic_18_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_18_6_7 ON here_traffic.mv_traffic_18_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_19_1_5 ON here_traffic.mv_traffic_19_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_19_6_7 ON here_traffic.mv_traffic_19_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_20_1_5 ON here_traffic.mv_traffic_20_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_20_6_7 ON here_traffic.mv_traffic_20_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_21_1_5 ON here_traffic.mv_traffic_21_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_21_6_7 ON here_traffic.mv_traffic_21_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_22_1_5 ON here_traffic.mv_traffic_22_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_22_6_7 ON here_traffic.mv_traffic_22_6_7 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_23_1_5 ON here_traffic.mv_traffic_23_1_5 USING btree (link_id);

CREATE INDEX mv_traffic_workdays_link_idx_23_6_7 ON here_traffic.mv_traffic_23_6_7 USING btree (link_id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_00_1_5 ON here_traffic.mv_traffic_00_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_00_6_7 ON here_traffic.mv_traffic_00_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_01_1_5 ON here_traffic.mv_traffic_01_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_01_6_7 ON here_traffic.mv_traffic_01_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_02_1_5 ON here_traffic.mv_traffic_02_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_02_6_7 ON here_traffic.mv_traffic_02_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_03_1_5 ON here_traffic.mv_traffic_03_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_03_6_7 ON here_traffic.mv_traffic_03_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_04_1_5 ON here_traffic.mv_traffic_04_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_04_6_7 ON here_traffic.mv_traffic_04_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_05_1_5 ON here_traffic.mv_traffic_05_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_05_6_7 ON here_traffic.mv_traffic_05_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_06_1_5 ON here_traffic.mv_traffic_06_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_06_6_7 ON here_traffic.mv_traffic_06_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_07_1_5 ON here_traffic.mv_traffic_07_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_07_6_7 ON here_traffic.mv_traffic_07_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_08_1_5 ON here_traffic.mv_traffic_08_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_08_6_7 ON here_traffic.mv_traffic_08_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_09_1_5 ON here_traffic.mv_traffic_09_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_09_6_7 ON here_traffic.mv_traffic_09_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_10_1_5 ON here_traffic.mv_traffic_10_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_10_6_7 ON here_traffic.mv_traffic_10_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_11_1_5 ON here_traffic.mv_traffic_11_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_11_6_7 ON here_traffic.mv_traffic_11_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_12_1_5 ON here_traffic.mv_traffic_12_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_12_6_7 ON here_traffic.mv_traffic_12_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_13_1_5 ON here_traffic.mv_traffic_13_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_13_6_7 ON here_traffic.mv_traffic_13_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_14_1_5 ON here_traffic.mv_traffic_14_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_14_6_7 ON here_traffic.mv_traffic_14_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_15_1_5 ON here_traffic.mv_traffic_15_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_15_6_7 ON here_traffic.mv_traffic_15_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_16_1_5 ON here_traffic.mv_traffic_16_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_16_6_7 ON here_traffic.mv_traffic_16_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_17_1_5 ON here_traffic.mv_traffic_17_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_17_6_7 ON here_traffic.mv_traffic_17_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_18_1_5 ON here_traffic.mv_traffic_18_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_18_6_7 ON here_traffic.mv_traffic_18_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_19_1_5 ON here_traffic.mv_traffic_19_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_19_6_7 ON here_traffic.mv_traffic_19_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_20_1_5 ON here_traffic.mv_traffic_20_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_20_6_7 ON here_traffic.mv_traffic_20_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_21_1_5 ON here_traffic.mv_traffic_21_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_21_6_7 ON here_traffic.mv_traffic_21_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_22_1_5 ON here_traffic.mv_traffic_22_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_22_6_7 ON here_traffic.mv_traffic_22_6_7 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_23_1_5 ON here_traffic.mv_traffic_23_1_5 USING btree (id);

CREATE UNIQUE INDEX mv_traffic_workdays_pk_idx_23_6_7 ON here_traffic.mv_traffic_23_6_7 USING btree (id);

CREATE INDEX mv_traffic_workdays_tf_didx_00_1_5 ON here_traffic.mv_traffic_00_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_00_6_7 ON here_traffic.mv_traffic_00_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_01_1_5 ON here_traffic.mv_traffic_01_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_01_6_7 ON here_traffic.mv_traffic_01_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_02_1_5 ON here_traffic.mv_traffic_02_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_02_6_7 ON here_traffic.mv_traffic_02_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_03_1_5 ON here_traffic.mv_traffic_03_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_03_6_7 ON here_traffic.mv_traffic_03_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_04_1_5 ON here_traffic.mv_traffic_04_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_04_6_7 ON here_traffic.mv_traffic_04_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_05_1_5 ON here_traffic.mv_traffic_05_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_05_6_7 ON here_traffic.mv_traffic_05_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_06_1_5 ON here_traffic.mv_traffic_06_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_06_6_7 ON here_traffic.mv_traffic_06_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_07_1_5 ON here_traffic.mv_traffic_07_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_07_6_7 ON here_traffic.mv_traffic_07_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_08_1_5 ON here_traffic.mv_traffic_08_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_08_6_7 ON here_traffic.mv_traffic_08_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_09_1_5 ON here_traffic.mv_traffic_09_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_09_6_7 ON here_traffic.mv_traffic_09_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_10_1_5 ON here_traffic.mv_traffic_10_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_10_6_7 ON here_traffic.mv_traffic_10_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_11_1_5 ON here_traffic.mv_traffic_11_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_11_6_7 ON here_traffic.mv_traffic_11_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_12_1_5 ON here_traffic.mv_traffic_12_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_12_6_7 ON here_traffic.mv_traffic_12_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_13_1_5 ON here_traffic.mv_traffic_13_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_13_6_7 ON here_traffic.mv_traffic_13_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_14_1_5 ON here_traffic.mv_traffic_14_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_14_6_7 ON here_traffic.mv_traffic_14_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_15_1_5 ON here_traffic.mv_traffic_15_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_15_6_7 ON here_traffic.mv_traffic_15_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_16_1_5 ON here_traffic.mv_traffic_16_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_16_6_7 ON here_traffic.mv_traffic_16_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_17_1_5 ON here_traffic.mv_traffic_17_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_17_6_7 ON here_traffic.mv_traffic_17_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_18_1_5 ON here_traffic.mv_traffic_18_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_18_6_7 ON here_traffic.mv_traffic_18_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_19_1_5 ON here_traffic.mv_traffic_19_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_19_6_7 ON here_traffic.mv_traffic_19_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_20_1_5 ON here_traffic.mv_traffic_20_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_20_6_7 ON here_traffic.mv_traffic_20_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_21_1_5 ON here_traffic.mv_traffic_21_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_21_6_7 ON here_traffic.mv_traffic_21_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_22_1_5 ON here_traffic.mv_traffic_22_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_22_6_7 ON here_traffic.mv_traffic_22_6_7 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_23_1_5 ON here_traffic.mv_traffic_23_1_5 USING btree (dir_travel);

CREATE INDEX mv_traffic_workdays_tf_didx_23_6_7 ON here_traffic.mv_traffic_23_6_7 USING btree (dir_travel);

CREATE INDEX traffic_all_60min_idx ON here_traffic.traffic_all_60min USING btree (region_code);

CREATE INDEX fcl_streets_g3_wkb_geometry_idx ON temp_import.fcl_streets_g3 USING gist (wkb_geometry);
CREATE INDEX fcl_streets_g6_wkb_geometry_idx ON temp_import.fcl_streets_g6 USING gist (wkb_geometry);
CREATE INDEX fcl_streets_g7_wkb_geometry_idx ON temp_import.fcl_streets_g7 USING gist (wkb_geometry);
CREATE INDEX traffic_import_idx ON temp_import.traffic_import USING btree (link_id);
CREATE INDEX traffic_import_idx1 ON temp_import.traffic_import USING btree (epoch_60);
CREATE INDEX traffic_import_idx2 ON temp_import.traffic_import USING btree (datum_zeit);
GRANT ALL ON FUNCTION here_traffic.insert_traffic() TO sauber_manager;
GRANT SELECT,INSERT,TRUNCATE ON TABLE here_traffic.car_60minuten TO sauber_user;
GRANT SELECT,INSERT,TRUNCATE ON TABLE here_traffic.car_60minuten TO sauber_manager;
GRANT SELECT,USAGE ON SEQUENCE here_traffic.car_60minuten_id_pk_seq TO sauber_user;
GRANT SELECT,USAGE ON SEQUENCE here_traffic.car_60minuten_id_pk_seq TO sauber_manager;

ALTER SCHEMA temp_import OWNER TO sauber_user;
ALTER SCHEMA here_traffic OWNER TO sauber_user;
ALTER DATABASE here OWNER TO sauber_user;


GRANT SELECT, INSERT, TRUNCATE
  ON here_traffic.car_60minuten TO sauber_manager;

GRANT SELECT, USAGE
  ON here_traffic.car_60minuten_id_pk_seq TO sauber_manager;

GRANT EXECUTE
  ON FUNCTION here_traffic.insert_traffic() TO sauber_manager;

GRANT SELECT, INSERT, TRUNCATE
  ON here_traffic.car_60minuten TO sauber_user;

GRANT SELECT, USAGE
  ON here_traffic.car_60minuten_id_pk_seq TO sauber_user;

GRANT EXECUTE
  ON FUNCTION here_traffic.insert_traffic() TO sauber_user;



SELECT create_hypertable('here_traffic.car_60minuten', 'datum_zeit');

ALTER DATABASE here SET timescaledb.restoring='off';
\c postgres;