ARG POSTGRES_VERSION=12
ARG TIMESCALE_VERSION=2.1.1

FROM timescale/timescaledb:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}
LABEL maintainer="Julian Kaeflein<Julian.Kaeflein@geomer.de>"

ARG POSTGIS_VERSION=3.1.1
ENV POSTGIS=${POSTGIS_VERSION}
ENV PG_CRON_VERSION=1.3.0

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps ca-certificates openssl tar bash \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        llvm \
        clang \
        clang-dev \
        gdal-dev \
        gdal \
    \
    && apk add --no-cache --virtual .build-deps-edge \
        g++ gdal-dev geos-dev proj-dev protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
    && ./configure -q \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-edge \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
        geos proj gdal-dev gdal protobuf-c libstdc++ \
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps .build-deps-edge

RUN apk add --no-cache --virtual .build-deps build-base ca-certificates clang-dev llvm10 openssl tar \
    && wget -O /pg_cron.tgz https://github.com/citusdata/pg_cron/archive/v$PG_CRON_VERSION.tar.gz \
    && tar xvzf /pg_cron.tgz && cd pg_cron-$PG_CRON_VERSION \
    && sed -i.bak -e 's/-Werror//g' Makefile \
    && sed -i.bak -e 's/-Wno-implicit-fallthrough//g' Makefile \
    && make && make install \
    && cd .. && rm -rf pg_cron.tgz && rm -rf pg_cron-* \
    && apk del .build-deps

RUN mkdir -p /update-files.d
COPY update-files.d/* update-files.d/
RUN chmod 775 /docker-entrypoint-initdb.d/*

RUN mkdir -p /docker-entrypoint-initdb.d
COPY docker-entrypoint-initdb.d/* docker-entrypoint-initdb.d/

RUN mkdir -p /update-files.d
COPY update-files.d/* update-files.d/
RUN chmod 775 /docker-entrypoint-initdb.d/*

COPY resources/bin/import-data.sh /usr/local/bin/import-data.sh
RUN chmod 775 /usr/local/bin/import-data.sh

COPY resources/conf/pg_hba.conf /tmp/
RUN chown postgres:postgres /tmp/pg_hba.conf
RUN chmod 600 /tmp/pg_hba.conf

RUN chown -R postgres:postgres /var/lib/postgresql

COPY resources/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 775 /usr/local/bin/docker-entrypoint.sh
RUN ln -s usr/local/bin/docker-entrypoint.sh

RUN mkdir /var/backup
COPY resources/conf/pg_backup.config /var/backup/pg_backup.config
COPY resources/bin/pg_backup.sh /var/backup/pg_backup.sh
COPY resources/cron/tab.txt /cron/tab.txt
RUN chmod 775 /var/backup/pg_backup.sh
RUN crontab /cron/tab.txt

ENV POSTGIS_ENABLE_OUTDB_RASTERS=1 \
    POSTGIS_GDAL_ENABLED_DRIVERS=ENABLE_ALL
