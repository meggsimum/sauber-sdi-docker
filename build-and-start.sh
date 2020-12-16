#/bin/bash

# build Docker images or not
DOCKER_BUILD=1

if [ $1 = "SKIPBUILD" ]
then
  DOCKER_BUILD=0
fi

# assemble date and a salt as image version
DATE=`date +"%Y%m%d"`
SALT="1"
# version a la 20200701_1
DATE_TAG=$DATE"_"$SALT
# the tag for the latest git stage in master branch
MASTER_TAG="master"

echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$MASTER_TAG
echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$DATE_TAG

docker network create sauber-network

if [ $DOCKER_BUILD -eq 1 ]
then

  echo "Building Docker Images ..."

  docker build --rm -f "db/Dockerfile" -t sauberprojekt/postgis_alpine:$MASTER_TAG "db"
  docker tag sauberprojekt/postgis_alpine:$MASTER_TAG sauberprojekt/postgis_alpine:$DATE_TAG

  docker build --rm -f "raster_download/Dockerfile" -t sauberprojekt/raster_download:$MASTER_TAG "raster_download"
  docker tag sauberprojekt/raster_download:$MASTER_TAG sauberprojekt/raster_download:$DATE_TAG

  docker build --rm -f "json_download/Dockerfile" -t sauberprojekt/json_download:$MASTER_TAG "json_download"
  docker tag sauberprojekt/json_download:$MASTER_TAG sauberprojekt/json_download:$DATE_TAG

  docker build --rm -f "test_messenger/Dockerfile" -t sauberprojekt/test_messenger:$MASTER_TAG "test_messenger"
  docker tag sauberprojekt/test_messenger:$MASTER_TAG sauberprojekt/test_messenger:$DATE_TAG

  docker build --rm -f "postgrest/Dockerfile" -t sauberprojekt/postgrest:$MASTER_TAG "postgrest"
  docker tag sauberprojekt/postgrest:$MASTER_TAG sauberprojekt/postgrest:$DATE_TAG

  docker build --rm -f "geoserver_publisher/Dockerfile" -t sauberprojekt/geoserver_raster_publisher:$MASTER_TAG "geoserver_publisher"
  docker tag sauberprojekt/geoserver_raster_publisher:$MASTER_TAG sauberprojekt/geoserver_raster_publisher:$DATE_TAG

  docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauberprojekt/um_ol_demo:$MASTER_TAG "um_ol_demo"
  docker tag sauberprojekt/um_ol_demo:$MASTER_TAG sauberprojekt/um_ol_demo:$DATE_TAG

  docker build --rm -f "um-js-demo-client/Dockerfile" -t sauberprojekt/um_js_demo:$MASTER_TAG "um-js-demo-client"
  docker tag sauberprojekt/um_js_demo:$MASTER_TAG sauberprojekt/um_js_demo:$DATE_TAG

  echo "... DONE Building Docker Images"

fi

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
