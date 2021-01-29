#/bin/bash

PUSH_TO_HUB=0

# assemble date and a salt as image version
DATE=`date +"%Y%m%d"`
SALT="1"
# version a la 20200701_1
DATE_TAG=$DATE"_"$SALT
# the tag for the latest git stage in master branch
MASTER_TAG="master"

echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$MASTER_TAG
echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$DATE_TAG

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

docker build --rm -f "station_layer_creator/Dockerfile" -t sauberprojekt/station_layer_creator:$MASTER_TAG "station_layer_creator"
docker tag sauberprojekt/station_layer_creator:$MASTER_TAG sauberprojekt/station_layer_creator:$DATE_TAG

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauberprojekt/um_ol_demo:$MASTER_TAG "um_ol_demo"
docker tag sauberprojekt/um_ol_demo:$MASTER_TAG sauberprojekt/um_ol_demo:$DATE_TAG

docker build --rm -f "um-js-demo-client/Dockerfile" -t sauberprojekt/um_js_demo:$MASTER_TAG "um-js-demo-client"
docker tag sauberprojekt/um_js_demo:$MASTER_TAG sauberprojekt/um_js_demo:$DATE_TAG

if [ $PUSH_TO_HUB -eq 1 ]
then
  echo "Push images to hub.docker"

  docker push sauberprojekt/postgis_alpine:$MASTER_TAG
  docker push sauberprojekt/postgis_alpine:$DATE_TAG

  docker push sauberprojekt/raster_download:$MASTER_TAG
  docker push sauberprojekt/raster_download:$DATE_TAG

  docker push sauberprojekt/json_download:$MASTER_TAG
  docker push sauberprojekt/json_download:$DATE_TAG

  docker push sauberprojekt/test_messenger:$MASTER_TAG
  docker push sauberprojekt/test_messenger:$DATE_TAG

  docker push sauberprojekt/postgrest:$MASTER_TAG
  docker push sauberprojekt/postgrest:$DATE_TAG

  docker push sauberprojekt/geoserver_raster_publisher:$MASTER_TAG
  docker push sauberprojekt/geoserver_raster_publisher:$DATE_TAG

  docker push sauberprojekt/station_layer_creator:$MASTER_TAG
  docker push sauberprojekt/station_layer_creator:$DATE_TAG

  docker push sauberprojekt/um_ol_demo:$MASTER_TAG
  docker push sauberprojekt/um_ol_demo:$DATE_TAG

  docker push sauberprojekt/um_js_demo:$MASTER_TAG
  docker push sauberprojekt/um_js_demo:$DATE_TAG
fi
