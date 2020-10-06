#!/bin/bash

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

#Get timestamp of file
DATA_TS=\'$(head -1 $OUTDIR/$OUTFILE | awk -F "[;]" '{print $(NF-1)"."$NF}' | awk -F "[.]" '{print $3"-"$2"-"$1,$4""}')\'

echo $DATA_TS

#Delete first 2 lines, replace characters
sed -i -e "1d;2d;" -e "s/\*/-/g" -e "s/<//g" $OUTDIR/$OUTFILE

# host db
PGPASSWORD=$APP_PASSWORD psql -h db -U app -d sauber_data -c "\copy station_data.input_lanuv FROM $OUTDIR/$OUTFILE CSV DELIMITER ';' NULL '-' ENCODING 'latin-1'; SELECT station_data.lanuv_parse($DATA_TS::TEXT);"