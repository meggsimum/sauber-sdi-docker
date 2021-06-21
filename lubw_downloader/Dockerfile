-FROM alpine:latest 

# install dependencies
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

# set time zone 
RUN ln -snf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && echo Europe/Berlin > /etc/timezone

# add to crontab
RUN crontab /cron/tab.txt

CMD ["crond", "-f", "-d", "8"]
