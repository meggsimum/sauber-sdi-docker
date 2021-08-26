#/bin/bash

# This resets the volume of the local SAUBER Postgres database and clenas the
# local data mount for GeoServer.
# After cleaning the lightweight GeoServer centric development stack is started.

# ONLY INTENDED FOR LOCAL DEVELOPMENT - NEVER USE THIS IN PRODUCTION !!!

read -p "Your local SAUBER DB and GeoServer will be reset. Continue (Y/n)?" CONF
echo    # (optional) move to a new line
if [ "$CONF" = "Y" ]; then

  if docker stack ls | grep -q sauber-stack; then
    echo "Removing running Docker stack  ...";
    docker stack rm sauber-stack
    sleep 10 # wait a bit until the stack and related things are really down
  fi

  echo "Resetting DB volume ...";
  if docker volume ls | grep -q sauber-stack_db_data; then
    docker volume rm sauber-stack_db_data
  fi

  echo "Resetting GeoServer data ..."
  if [ -d "geoserver_mnt" ]; then
    sudo rm -r geoserver_mnt/*
  else
    mkdir geoserver_mnt
  fi
  # cerate necessary sub folder for geoserver_mnt/
  mkdir geoserver_mnt/raster_data && mkdir geoserver_mnt/geoserver_data

  echo "Creating Docker network (if not existing ) ...";
  docker network create sauber-network

  echo "Starting Docker stack ...";
  docker stack deploy -c docker-stack-geoserver-only.yml sauber-stack
else
  echo "Abort ...";
fi
