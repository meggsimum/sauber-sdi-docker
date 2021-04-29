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

  /bin/sh ./build-images.sh

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
