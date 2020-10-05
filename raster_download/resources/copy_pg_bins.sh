#!/bin/bash

# append this array with additional binaries for export
# note: must be in path
bins=(raster2pgsql psql)

for i in ${bins[@]}; do :
   
   # get path of binary 
   # create target dir of same name in root
   SRC_PATH=$(which $i)
   TARGET_PATH="/$i"
   mkdir $TARGET_PATH
   
   # copy binary to target dir
   # preserve path structure
   cp --parents $SRC_PATH $TARGET_PATH

   # get all shared dependency files for the binary by invoking ldd 
   # get the path can copy each lib to the target path, including its dir structure 
   # results in folder of the binary and all dependencies for export 
   for j in `ldd ${SRC_PATH[@]} | cut  -d'>' -f2 | awk '{print $1}'` ; do
      if [[ -f $j ]] ; then
         #echo $j
         cp --parents $j $TARGET_PATH
      fi  
   done

done;