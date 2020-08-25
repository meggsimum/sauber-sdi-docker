#!/bin/bash

SRC_PATH=("/usr/local/bin/raster2pgsql")
TARGET_PATH="/r2p"
mkdir $TARGET_PATH

cp --parents $SRC_PATH $TARGET_PATH

for j in `ldd ${SRC_PATH[@]} | cut  -d'>' -f2 | awk '{print $1}'` ; do
   if [[ -f $j ]] ; then
      #echo $i
      cp --parents $j $TARGET_PATH
   fi  
done

SRC_PATH=("/usr/local/bin/psql")
TARGET_PATH="/psql"
mkdir $TARGET_PATH

cp --parents $SRC_PATH $TARGET_PATH

for j in `ldd ${SRC_PATH[@]} | cut  -d'>' -f2 | awk '{print $1}'` ; do
   if [[ -f $j ]] ; then
      cp --parents $j $TARGET_PATH
   fi  
done
