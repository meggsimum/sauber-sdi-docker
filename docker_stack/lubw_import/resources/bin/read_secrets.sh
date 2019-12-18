#!/bin/bash

set -e 

# Load envs

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
#	echo "$var,$val"
	export "$var"="$val"
	unset "$fileVar" 
}

secrets=(
	SAUBER_MANAGER_PASSWORD
    FTP_USER
    FTP_PASSWORD
    FTP_SERVER
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

crond -f