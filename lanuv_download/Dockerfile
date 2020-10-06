FROM alpine:latest 

# install dependencies
RUN apk update && \
    apk del sed && \
    apk add \
    bash \
    curl \
    postgresql-client \
    sed

# set time zone 
COPY resources/ . 
RUN mkdir lanuv_data
RUN chmod 775 lanuv_data scripts 

# add to crontab
RUN crontab /cron/tab.txt

# order of execution: 
# read_secrets > cron > download script
ENTRYPOINT ["scripts/read_secrets.sh"]