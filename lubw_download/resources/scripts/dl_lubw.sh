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
	#echo "$var,$val"
	export "$var"="$val"
	unset "$fileVar" 
}


#Read docker secrets. 
secrets=(
    APP_PASSWORD
    LUBW_USER
    LUBW_PASSWORD
    LUBW_SERVER
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

#Ensure mandatory environment vars are set  
envs=(
    APP_PASSWORD
	LUBW_USER
	LUBW_PASSWORD
    LUBW_SERVER
)

for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done

#Set dirs and name parsed file after ingestion time
OUTDIR=/data/temp
OUTFILE=lubw_temp.xml
PARSED_OUTDIR=/data/xml_data
PARSED_OUTFILE=lubw_$(TZ=Europe/Berlin date +%Y%m%d%H%M).xml

# Download xml file from server. Exit if curl throws failure (http response!=2xx) 

if curl --fail -u $LUBW_USER:$LUBW_PASSWORD ftp://$LUBW_SERVER/Aktuelledaten.xml -o $OUTDIR/$OUTFILE; 
then
    echo "Datei $PARSED_OUTFILE heruntergeladen."
else
    echo "Error: Datei konnte nicht herunterladen werden."
	exit 1
fi


# XML is not well formed for direct insert to PG. Need to replace newline with empty string.
tr '\n' ' ' < $OUTDIR/$OUTFILE > $PARSED_OUTDIR/$PARSED_OUTFILE
wait

PGPASSWORD=$APP_PASSWORD /usr/bin/psql -h db -p 5432 -U app -d sauber_data -c "\copy station_data.input_lubw FROM $PARSED_OUTDIR/$PARSED_OUTFILE encoding 'LATIN1'; SELECT station_data.lubw_parse();"

exit