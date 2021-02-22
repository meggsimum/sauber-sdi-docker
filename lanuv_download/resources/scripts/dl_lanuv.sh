#!/bin/bash

set -e 

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
)

for e in "${secrets[@]}"; do
		file_env "$e"
done

#Ensure mandatory environment vars are set  
envs=(
    APP_PASSWORD
)

for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done

OUTDIR=/lanuv_data
OUTFILE=lanuv_$(TZ=Europe/Berlin date +%Y%m%d%H%M).csv

# Download xml file from server. Exit if curl throws failure (http response!=2xx)
if curl -s --fail "https://www.lanuv.nrw.de/fileadmin/lanuv/luft/immissionen/aktluftqual/eu_luftqualitaet.csv" -o $OUTDIR/$OUTFILE;
then
    echo "Datei $OUTDIR/$OUTFILE heruntergeladen."
else
    echo "Error: Datei konnte nicht herunterladen werden."
        exit 1
fi

#Get timestamp of the file, assign to variable
DATA_TS=\'$(head -1 $OUTDIR/$OUTFILE | awk -F "[;]" '{print $(NF-1)"."$NF}' | awk -F "[.]" '{print $3"-"$2"-"$1,$4""}')\'

#Delete first 2 lines to meet postgres req for csv, replace invalid characters
sed -i -e "1d;2d;" -e "s/\*/-/g" -e "s/<//g" $OUTDIR/$OUTFILE
sleep 1

#Upload data to postgres
PGPASSWORD=$APP_PASSWORD /usr/bin/psql -h db -U app -d sauber_data -c "\copy station_data.input_lanuv FROM $OUTDIR/$OUTFILE CSV DELIMITER ';' NULL '-' ENCODING 'latin-1'; SELECT station_data.lanuv_parse($DATA_TS::TEXT);"

exit