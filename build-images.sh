#/bin/bash

PUSH_TO_HUB=0

if [ $1 = "PUSH_TO_HUB" ]
then
  PUSH_TO_HUB=1
fi

echo "PUSH_TO_HUB="$PUSH_TO_HUB

# assemble date and a salt as image version
DATE=`date +"%Y%m%d"`
SALT="1"
# version a la 20200701_1
DATE_TAG=$DATE"_"$SALT
# tag for the docker images (default "master" for latest stage in master branch)
TAG="${TAG:-master}"

echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$TAG
echo "USING THE FOLLOWING TAG FOR IMAGE BUILD "$DATE_TAG

docker build --rm -f "db/Dockerfile" -t sauberprojekt/db:$TAG "db"
docker tag sauberprojekt/db:$TAG sauberprojekt/db:$DATE_TAG

docker build --rm -f "raster_download/Dockerfile" -t sauberprojekt/raster_download:$TAG "raster_download"
docker tag sauberprojekt/raster_download:$TAG sauberprojekt/raster_download:$DATE_TAG

docker build --rm -f "json_download/Dockerfile" -t sauberprojekt/json_download:$TAG "json_download"
docker tag sauberprojekt/json_download:$TAG sauberprojekt/json_download:$DATE_TAG

docker build --rm -f "lanuv_download/Dockerfile" -t sauberprojekt/lanuv_download:$TAG "lanuv_download"
docker tag sauberprojekt/lanuv_download:$TAG sauberprojekt/lanuv_download:$DATE_TAG

docker build --rm -f "lubw_download/Dockerfile" -t sauberprojekt/lubw_download:$TAG "lubw_download"
docker tag sauberprojekt/lubw_download:$TAG sauberprojekt/lubw_download:$DATE_TAG

docker build --rm -f "test_messenger/Dockerfile" -t sauberprojekt/test_messenger:$TAG "test_messenger"
docker tag sauberprojekt/test_messenger:$TAG sauberprojekt/test_messenger:$DATE_TAG

docker build --rm -f "postgrest/Dockerfile" -t sauberprojekt/postgrest:$TAG "postgrest"
docker tag sauberprojekt/postgrest:$TAG sauberprojekt/postgrest:$DATE_TAG

docker build --rm -f "geoserver_publisher/Dockerfile" -t sauberprojekt/geoserver_raster_publisher:$TAG "geoserver_publisher"
docker tag sauberprojekt/geoserver_raster_publisher:$TAG sauberprojekt/geoserver_raster_publisher:$DATE_TAG

docker build --rm -f "station_layer_creator/Dockerfile" -t sauberprojekt/station_layer_creator:$TAG "station_layer_creator"
docker tag sauberprojekt/station_layer_creator:$TAG sauberprojekt/station_layer_creator:$DATE_TAG

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauberprojekt/um_ol_demo:$TAG "um_ol_demo"
docker tag sauberprojekt/um_ol_demo:$TAG sauberprojekt/um_ol_demo:$DATE_TAG

docker build --rm -f "um-js-demo-client/Dockerfile" -t sauberprojekt/um_js_demo:$TAG "um-js-demo-client"
docker tag sauberprojekt/um_js_demo:$TAG sauberprojekt/um_js_demo:$DATE_TAG

docker build --rm -f "geoserver_init/Dockerfile" -t sauberprojekt/geoserver_init:$TAG "geoserver_init"
docker tag sauberprojekt/geoserver_init:$TAG sauberprojekt/geoserver_init:$DATE_TAG

docker build --rm -f "db_webhooks/Dockerfile" -t sauberprojekt/db_webhooks:$TAG "db_webhooks"
docker tag sauberprojekt/db_webhooks:$TAG sauberprojekt/db_webhooks:$DATE_TAG


if [ $PUSH_TO_HUB -eq 1 ]
then
  echo "Push images to hub.docker"

  docker push sauberprojekt/db:$TAG
  docker push sauberprojekt/db:$DATE_TAG

  docker push sauberprojekt/raster_download:$TAG
  docker push sauberprojekt/raster_download:$DATE_TAG

  docker push sauberprojekt/json_download:$TAG
  docker push sauberprojekt/json_download:$DATE_TAG

  docker push sauberprojekt/lanuv_download:$TAG
  docker push sauberprojekt/lanuv_download:$DATE_TAG

  docker push sauberprojekt/lubw_download:$TAG
  docker push sauberprojekt/lubw_download:$DATE_TAG

  docker push sauberprojekt/test_messenger:$TAG
  docker push sauberprojekt/test_messenger:$DATE_TAG

  docker push sauberprojekt/postgrest:$TAG
  docker push sauberprojekt/postgrest:$DATE_TAG

  docker push sauberprojekt/geoserver_raster_publisher:$TAG
  docker push sauberprojekt/geoserver_raster_publisher:$DATE_TAG

  docker push sauberprojekt/station_layer_creator:$TAG
  docker push sauberprojekt/station_layer_creator:$DATE_TAG

  docker push sauberprojekt/um_ol_demo:$TAG
  docker push sauberprojekt/um_ol_demo:$DATE_TAG

  docker push sauberprojekt/um_js_demo:$TAG
  docker push sauberprojekt/um_js_demo:$DATE_TAG

  docker push sauberprojekt/geoserver_init:$TAG
  docker push sauberprojekt/geoserver_init:$DATE_TAG

  docker push sauberprojekt/db_webhooks:$TAG
  docker push sauberprojekt/db_webhooks:$DATE_TAG
fi
