FROM maven:3.6.0-jdk-8-slim
LABEL maintainer="Christian Mayer<chris@meggsimum.de>"

ENV UM_SERVER="um_server:9000"
ENV UM_CHANNEL="raster_data"

RUN apt-get update && apt-get -y install -qq cron

WORKDIR /opt

# copy the maven project
COPY local-deps/ local-deps/
COPY src/ src/
COPY pom.xml pom.xml
COPY cron/cronjob.txt cronjob.txt
COPY cron/run.sh run.sh

# install local dependency for UM Java client
RUN mvn install:install-file -Dfile=local-deps/nClient.jar -DgroupId=com.pcbsys.nirvana.client -DartifactId=sample -Dversion=1.0 -Dpackaging=jar

# build the executable JAR file
RUN mvn clean package -DskipTests

RUN crontab cronjob.txt

#CMD umchannel=$UM_CHANNEL umserver=$UM_SERVER java -jar target/test-messenger-jar-with-dependencies.jar

ENTRYPOINT ["cron", "-f"]
