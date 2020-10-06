FROM alpine:latest 

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
RUN mkdir -p lubw_data/temp lubw_data/xml_data
RUN chmod -R 775 lubw_data scripts 

# set time zone 
RUN ln -snf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && echo Europe/Berlin > /etc/timezone

# add to crontab
RUN crontab /cron/tab.txt

# order of execution: 
# read_secrets > cron > download script
ENTRYPOINT ["scripts/read_secrets.sh"]