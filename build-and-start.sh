#/bin/bash

docker network create sauber-network

docker build --rm -f "db/Dockerfile" -t sauber_postgis_alpine:latest "db"

docker build --rm -f "raster_download/Dockerfile" -t raster_download:latest "raster_download"

docker build --rm -f "lubw_import/Dockerfile" -t lubw_download:latest "lubw_import"

#docker build --rm -f "postgrest/Dockerfile" -t sauber_postgrest:latest "postgrest"
#docker build --rm -f "postgrest/Dockerfile" -t postgrest_here:latest "postgrest"

docker build --rm -f "um_ol_demo/Webmap.dockerfile" -t sauber_um_ol_demo:latest "um_ol_demo"

docker stack deploy -c docker-stack.yml sauber-stack
