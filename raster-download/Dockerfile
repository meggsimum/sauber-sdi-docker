FROM maven:3.6.0-jdk-8-slim
LABEL maintainer="Christian Mayer<chris@meggsimum.de>"

ENV UM_SERVER="um_server:9000"
ENV UM_CHANNEL="raster_data"
ENV DB_USER="sauber_user"

WORKDIR /opt

# copy the maven project
COPY local-deps/ local-deps/
COPY src/ src/
COPY pom.xml pom.xml

#.crt file in the same folder as your Dockerfile
ARG CERT="sdkama.cer"

#import cert into java
COPY $CERT .
RUN keytool -importcert -file $CERT -alias $CERT  -storepass changeit -noprompt -v

# install local dependency for UM Java client
RUN mvn install:install-file -Dfile=local-deps/nClient.jar -DgroupId=com.pcbsys.nirvana.client -DartifactId=sample -Dversion=1.0 -Dpackaging=jar

# build the executable JAR file
RUN mvn clean package -DskipTests

CMD umchannel=$UM_CHANNEL umserver=$UM_SERVER dbuser=$DB_USER java -jar target/raster-download-jar-with-dependencies.jar