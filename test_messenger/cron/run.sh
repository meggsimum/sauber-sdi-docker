#!/bin/bash
echo 'Running'
cd /opt/target
umchannel='raster_data' umserver='um_server:9000' /usr/bin/java -jar /opt/target/test-messenger-jar-with-dependencies.jar >> /proc/1/fd/1
