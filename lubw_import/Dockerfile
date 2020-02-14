FROM alpine:latest
LABEL maintainer="Julian Kaeflein<Julian.Kaeflein@geomer.de>"
LABEL Name=sauber_lubw_download Version=0.0.1

RUN sed -i '/edge/s/^#//' /etc/apk/repositories

RUN apk update \ 
        && apk add -U \ 
        busybox-initscripts \
        busybox \
        openrc \ 
        curl \
        postgresql-client \
        bash

COPY /resources/bin/dl_sauber_ftp.sh /dl_sauber_ftp.sh
RUN mkdir -p /data/xml_data/
RUN mkdir -p /data/temp/

COPY /resources/bin/read_secrets.sh /read_secrets.sh
COPY /resources/bin/sauber_cron.txt /sauber_cron.txt

RUN ln -snf /usr/share/zoneinfo/Europe/Berlin /etc/localtime && echo Europe/Berlin > /etc/timezone

RUN crontab sauber_cron.txt

RUN chmod 775 /dl_sauber_ftp.sh
RUN chmod 775 /data/xml_data/
RUN chmod 775 /data/temp/       

RUN sed -i 's/bin\/ash/bin\/bash/' /etc/passwd

CMD ["cron", "-f"]
ENTRYPOINT [ "/read_secrets.sh" ]