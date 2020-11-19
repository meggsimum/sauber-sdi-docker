#!/bin/bash

#Set dirs and name parsed file after ingestion time
OUTDIR=/data/temp
OUTFILE=lubw_temp.xml
PARSED_OUTDIR=/data/xml_data
PARSED_OUTFILE=lubw_$(TZ=Europe/Berlin date +%Y%m%d%H%M).xml

# Download xml file from server. Exit if curl throws failure (http response!=2xx) 
if curl --fail -u $LUBW_USER:$LUBW_PASSWORD ftp://$LUBW_SERVER -o $OUTDIR/$OUTFILE; 
then
    echo "Datei $PARSED_OUTFILE heruntergeladen."
else
    echo "Error: Datei konnte nicht herunterladen werden."
	exit 1
fi


# XML is not well formed for direct insert to PG. Need to replace newline with empty string.
tr '\n' ' ' < $OUTDIR/$OUTFILE > $PARSED_OUTDIR/$PARSED_OUTFILE
wait
PGPASSWORD=$APP_PASSWORD psql -h db -U app -d $LUBW_DATABASE -c "\copy station_data.input_lubw FROM $PARSED_OUTDIR/$PARSED_OUTFILE encoding 'LATIN1'; SELECT station_data.parse_lubw();"