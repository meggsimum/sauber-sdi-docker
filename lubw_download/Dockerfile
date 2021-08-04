FROM alpine:latest
# install dependencies
# del preinstalled busybox's sed with limited functionality & install fully fledged sed
RUN apk update && \
    apk del sed && \
    apk add \
    bash \
    curl \
    postgresql-client \
    sed

# copy and credentials
COPY resources/ . 
RUN mkdir -p /data/xml_data /data/temp
RUN chmod -R 775 /data /scripts 

# add to crontab
RUN crontab /cron/tab.txt

CMD ["crond", "-f", "-d", "8"]
