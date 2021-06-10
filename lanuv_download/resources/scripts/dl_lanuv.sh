#!/bin/bash

set -e 

# Read docker secrets given below according to paths set in compose file
# Export them as container env vars 
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

#Secrets to be read 
secrets=(
    APP_PASSWORD
)

#Call function
for e in "${secrets[@]}"; do
		file_env "$e"
done

# Environmental vars needed to be set
envs=(
    APP_PASSWORD
)

#Ensure mandatory environment vars are set
for e in "${envs[@]}"; do
	if [ -z ${!e:-} ]; then
		echo "error: $e is not set"
		exit 1
	fi
done

# Set dir and outfile pattern
OUTDIR=/lanuv_data
OUTFILE=lanuv_$(TZ=Europe/Berlin date +%Y%m%d%H%M).csv

# Download xml file from server. Exit if curl throws failure (http response!=2xx)
if curl -s --fail "https://www.lanuv.nrw.de/fileadmin/lanuv/luft/immissionen/aktluftqual/eu_luftqualitaet.csv" -o $OUTDIR/$OUTFILE;
then
    echo "Downloaded $OUTDIR/$OUTFILE."
else
    echo "Error: Could not download file."
        exit 1
fi

# Get timestamp of the file through parsing, assign to variable needed by database function
DATA_TS=\'$(head -1 $OUTDIR/$OUTFILE | awk -F "[;]" '{print $(NF-1)"."$NF}' | awk -F "[.]" '{print $3"-"$2"-"$1,$4""}')\'

#Delete first 2 lines to meet postgres req for csv, replace invalid characters
sed -i -e "1d;2d;" -e "s/\*/-/g" -e "s/<//g" $OUTDIR/$OUTFILE
sleep 1

# Upload data to postgres, call in-db parser
PGPASSWORD=$APP_PASSWORD /usr/bin/psql -h db -U app -d sauber_data -c "\copy station_data.input_lanuv FROM $OUTDIR/$OUTFILE CSV DELIMITER ';' NULL '-' ENCODING 'latin-1';"
PGPASSWORD=$APP_PASSWORD /usr/bin/psql -h db -U app -d sauber_data -c "SELECT station_data.lanuv_parse($DATA_TS::TEXT);"

exit