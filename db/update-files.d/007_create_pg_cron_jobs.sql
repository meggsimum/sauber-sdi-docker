\c sauber_data

CREATE EXTENSION IF NOT EXISTS pg_cron;


/*
Check a if a specific query exists in pg_cron, else create it.
Prevents jobs stack up on every deployment w/o adding a unique 
constraint on table cron.job (with unkown results).

To add queries, alter cols 1 and 2 (cron schedule and query).
*/

-- Refresh station_data.fv_station_metadata at 11:00am every day
INSERT INTO cron.job (schedule,command,nodename,nodeport,"database",username,active,jobname)
    SELECT  '0 11 * * *','REFRESH MATERIALIZED VIEW station_data.fv_station_metadata','localhost',5432,'sauber_data','postgres',true,'refresh station metaview' 
    WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE command LIKE 'REFRESH MATERIALIZED VIEW station_data.fv_station_metadata');

-- Refresh station_data.fv_stations every day at midnight
INSERT INTO cron.job (schedule,command,nodename,nodeport,"database",username,active,jobname)
    SELECT  '0 0 * * *','REFRESH MATERIALIZED VIEW station_data.fv_stations','localhost',5432,'sauber_data','postgres',true,'refresh stations view' 
    WHERE NOT EXISTS (SELECT 1 FROM cron.job WHERE command LIKE 'REFRESH MATERIALIZED VIEW station_data.fv_stations');
