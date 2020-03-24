#/bin/bash

docker network create sauber-network

docker build --rm -f "db/Dockerfile" -t sauber_postgis_alpine:latest "db"

docker build --rm -f "raster_download/Dockerfile" -t raster_download:latest "raster_download"

docker build --rm -f "lubw_import/Dockerfile" -t lubw_download:latest "lubw_import"

#docker build --rm -f "postgrest/Dockerfile" -t sauber_postgrest:latest "postgrest"
#docker build --rm -f "postgrest/Dockerfile" -t postgrest_here:latest "postgrest"

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauber_um_ol_demo:latest "um_ol_demo"

docker stack deploy -c docker-stack.yml sauber-stack

UM_SERVER_ID=`docker ps | grep um_server | cut -c1-5` # Get container ID of UM-Server

if docker inspect -f '{{.State.Running}}' $UM_SERVER_ID > /dev/null ; then # Wait for UM Server to be up and running (State.Running = true)
    docker exec $UM_SERVER_ID runUMTool.sh CreateChannel -rname=nsp://localhost:9000 -channelname=HeartbeatChannel # Create Heartbeat Channel on UM Server
fi