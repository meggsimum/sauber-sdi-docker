#!/bin/bash


if [ -z "${POSTGRESQL_CONF_DIR:-}" ]; then
	POSTGRESQL_CONF_DIR=${PGDATA}
fi

echo "timescaledb.telemetry_level='off'" >> ${POSTGRESQL_CONF_DIR}/postgresql.conf


for DB in postgres template1; do
  # create extension timescaledb in initial databases
  psql -U "${POSTGRES_USER}" -d $DB -q -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
  psql -U "${POSTGRES_USER}" -d $DB -q -c "CREATE EXTENSION IF NOT EXISTS postgis;"
  psql -U "${POSTGRES_USER}" -d $DB -q -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
  psql -U "${POSTGRES_USER}" -d $DB -q -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
done


if [ "${POSTGRES_DB:-postgres}" != 'postgres' ]; then
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS postgis;"
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
  psql -U "${POSTGRES_USER}" "${POSTGRES_DB}" -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"
fi