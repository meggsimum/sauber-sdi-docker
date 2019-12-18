#!/bin/bash
set -euo pipefail

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Read docker secrets. 
secrets=(
	PGRST_USER
	PGRST_PASSWORD
	PGRST_JWT_SECRET
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

# Ensure mandatory connection related environment vars are set and build up the postgres connection string.
envs=(
	PGRST_DB_SERVER
	PGRST_DB_PORT
	PGRST_DB_NAME
	PGRST_DB_SCHEMA
	PGRST_DB_ANON_ROLE
	PGRST_JWT_SECRET
)

for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done


export PGRST_DB_URI=postgres://${PGRST_USER}:${PGRST_PASSWORD}@${PGRST_DB_SERVER}:${PGRST_DB_PORT}/${PGRST_DB_NAME}
echo ${PGRST_DB_URI}
#echo ${PGRST_JWT_SECRET}

# Start
exec postgrest /etc/postgrest.conf
