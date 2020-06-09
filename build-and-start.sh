#/bin/bash

docker network create sauber-network

docker build --rm -f "db/Dockerfile" -t sauber_postgis_alpine:latest "db"

docker build --rm -f "raster_download/Dockerfile" -t raster_download:latest "raster_download"

#docker build --rm -f "postgrest/Dockerfile" -t sauber_postgrest:latest "postgrest"
#docker build --rm -f "postgrest/Dockerfile" -t postgrest_here:latest "postgrest"

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauber_um_ol_demo:latest "um_ol_demo"

docker build --rm -f "um-js-demo-client/Dockerfile" -t sauber_um_js_demo:latest "um-js-demo-client"

docker stack deploy -c docker-stack.yml sauber-stack

CHANNELS=("HeartbeatChannel geotiff-demo") ## Add additional channels to be created

until [ ! -z "$UM_SERVER_ID" ]; do
    UM_SERVER_ID=`docker ps | grep um_server | cut -c1-5` ## Get all running containers. Search for UM Server container name. Get UM-Server ID by first 5 digits of response. 
    sleep 5;
    ((cnt++)) && ((cnt==6)) && \
    echo 'Error: Universal Messaging Server Container not found.' && \
    exit # Exit if UM Server not found in given amount of tries 
    echo 'Searching for UM Container. Attempt' $cnt;
done;

for channel in $CHANNELS; do
    echo 'Creating channel' $channel
    until [ `docker exec $UM_SERVER_ID runUMTool.sh ListChannels -rname=nsp://localhost:9000 | grep $channel` ]; do # Until channel exists on UM Server: 
           docker exec $UM_SERVER_ID runUMTool.sh CreateChannel -rname=nsp://localhost:9000 -channelname=$channel # Create channel on UM Server
    sleep 1
    done;
done