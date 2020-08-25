FROM maven:3.6.0-jdk-8-slim
LABEL maintainer="Julian Kaeflein<julian.kaeflein@geomer.de>"

ENV UM_SERVER="um_server:9000"
ENV UM_CHANNEL="station_data"

WORKDIR /opt

# copy the maven project
COPY local-deps/ local-deps/
COPY src/ src/
COPY pom.xml pom.xml

# install local dependency for UM Java client
RUN mvn install:install-file -Dfile=local-deps/nClient.jar -DgroupId=com.pcbsys.nirvana.client -DartifactId=sample -Dversion=1.0 -Dpackaging=jar

# build the executable JAR file
RUN mvn clean package -DskipTests

CMD umchannel=$UM_CHANNEL umserver=$UM_SERVER dbuser=$DB_USER java -jar target/json-download-jar-with-dependencies.jar