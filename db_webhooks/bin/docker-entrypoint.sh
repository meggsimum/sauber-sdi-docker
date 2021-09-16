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
	APP_PASSWORD
	SLACK_CHANNEL_URL
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

# Ensure mandatory connection related environment vars are set and build up the postgres connection string.
envs=(
	APP_PASSWORD
	SLACK_CHANNEL_URL
)

for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done

# Inject password and slack channel URL from env var into config.yaml

sed -i -e "s/APP_PASSWORD/${APP_PASSWORD}/g" -e "s#SLACK_CHANNEL#${SLACK_CHANNEL_URL}#g" config.yaml # Use § for separator for no.2 command to avoid dealing with / in URL 

# Start
exec pg-notify-webhook 2>&1
