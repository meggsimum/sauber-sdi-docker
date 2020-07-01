#/bin/bash

PUSH_TO_HUB=0

# assemble date and a salt as image version
DATE=`date +"%Y%m%d"`
SALT="1"
# version a la 20200701_1
IMG_VERSION=$DATE"_"$SALT

echo "USING THE FOLLOWING VERSION FOR IMAGE BUILD "$IMG_VERSION

docker build --rm -f "db/Dockerfile" -t sauberprojekt/postgis_alpine:$IMG_VERSION "db"

docker build --rm -f "raster_download/Dockerfile" -t sauberprojekt/raster_download:$IMG_VERSION "raster_download"

docker build --rm -f "postgrest/Dockerfile" -t sauberprojekt/postgrest:$IMG_VERSION "postgrest"

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauberprojekt/um_ol_demo:$IMG_VERSION "um_ol_demo"

docker build --rm -f "um-js-demo-client/Dockerfile" -t sauberprojekt/um_js_demo:$IMG_VERSION "um-js-demo-client"

if [ $PUSH_TO_HUB -eq 1 ]
then
  echo "Push images to hub.docker"

  docker push sauberprojekt/postgis_alpine:$IMG_VERSION

  docker push sauberprojekt/raster_download:$IMG_VERSION

  docker push sauberprojekt/postgrest:$IMG_VERSION

  docker push sauberprojekt/um_ol_demo:$IMG_VERSION

  docker push sauberprojekt/um_js_demo:$IMG_VERSION
fi
