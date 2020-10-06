#/bin/bash

# assemble date and a salt as image version
DATE=`date +"%Y%m%d"`
SALT="1"
# version a la 20200701_1
IMG_VERSION=$DATE"_"$SALT

echo "USING THE FOLLOWING VERSION FOR IMAGE BUILD "$IMG_VERSION

docker network create sauber-network

docker build --rm -f "db/Dockerfile" -t sauberprojekt/postgis_alpine:$IMG_VERSION "db"

docker build --rm -f "raster_download/Dockerfile" -t sauberprojekt/raster_download:$IMG_VERSION "raster_download"

docker build --rm -f "json_download/Dockerfile" -t sauberprojekt/json_download:$IMG_VERSION "json_download"

docker build --rm -f "test_messenger/Dockerfile" -t sauberprojekt/test_messenger:$IMG_VERSION "test_messenger"

docker build --rm -f "postgrest/Dockerfile" -t sauberprojekt/postgrest:$IMG_VERSION "postgrest"

docker build --rm -f "geoserver_publisher/Dockerfile" -t sauberprojekt/geoserver_raster_publisher:$IMG_VERSION "geoserver_publisher"

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauberprojekt/um_ol_demo:$IMG_VERSION "um_ol_demo"

docker build --rm -f "um-js-demo-client/Dockerfile" -t sauberprojekt/um_js_demo:$IMG_VERSION "um-js-demo-client"

docker stack deploy -c docker-stack.yml sauber-stack

CHANNELS=("HeartbeatChannel raster_data station_data") ## Add additional channels to be created

until [ ! -z "$UM_SERVER_ID" ]; do
    UM_SERVER_ID=$(docker ps | grep um_server | cut -c1-5) ## Get all running containers. Search for UM Server container name. Get UM-Server ID by first 5 digits of response.
    sleep 5;
    ((cnt++)) && ((cnt==6)) && \
    echo 'Error: Universal Messaging Server Container not found.' && \
    exit # Exit if UM Server not found in given amount of tries
    echo 'Searching for UM Container. Attempt' $cnt;
done;

for channel in $CHANNELS; do
    echo 'Creating channel' $channel
    until [[ $(docker exec $UM_SERVER_ID runUMTool.sh ListChannels -rname=nsp://localhost:9000 | grep "$channel") ]]; do # Until channel exists on UM Server:
           docker exec $UM_SERVER_ID runUMTool.sh CreateChannel -rname=nsp://localhost:9000 -channelname="$channel" # Create channel on UM Server
    sleep 1
    done;
done