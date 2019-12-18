ARG POSTGRES_VERSION=11
ARG TIMESCALE_VERSION=1.5.1

FROM timescale/timescaledb:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}
LABEL maintainer ="Julian.Kaeflein@geomer.de"

ARG POSTGIS_VERSION=3.0.0
ENV POSTGIS=${POSTGIS_VERSION} 

RUN set -ex \
    && apk add --no-cache --virtual .fetch-deps \
                ca-certificates \
                openssl \
                tar \
    && apk add -U --no-cache --virtual .crypto-rundeps \
                --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
                libressl2.7-libcrypto \
                libcrypto1.1 \
    && apk add -U --no-cache --virtual .postgis-deps \ 
    --repository http://nl.alpinelinux.org/alpine/edge/community \
    --repository http://nl.alpinelinux.org/alpine/edge/main \
        geos \
        gdal \
        proj \
        protobuf-c \
    && apk add -U --no-cache --virtual .build-deps \
    --repository http://nl.alpinelinux.org/alpine/edge/testing \
    --repository http://nl.alpinelinux.org/alpine/edge/main \
    --repository http://nl.alpinelinux.org/alpine/edge/community \
        postgresql-dev \
        perl \
        file \
        geos-dev \
        libxml2-dev \
        gdal-dev \
        proj-dev \
        protobuf-c-dev \
        json-c-dev \
        gcc g++ \
        make \
    && cd /tmp \
    && wget http://download.osgeo.org/postgis/source/postgis-${POSTGIS}.tar.gz -O - | tar -xz \
    && chown root:root -R postgis-${POSTGIS} \
    && cd /tmp/postgis-${POSTGIS} \
    && ./configure \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis/Makefile \
    && echo "PERL = /usr/bin/perl" >> extensions/postgis_topology/Makefile \
    && make -s \
    && make -s install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && cd / \
    \
    && rm -rf /tmp/postgis-${POSTGIS} \
    && apk del .fetch-deps .build-deps

RUN mkdir -p /docker-entrypoint-initdb.d 

COPY docker-entrypoint-initdb.d/* docker-entrypoint-initdb.d/
COPY resources/bin/import-data.sh /usr/local/bin/import-data.sh

RUN chmod 775 /docker-entrypoint-initdb.d/*
RUN chmod 775 /usr/local/bin/import-data.sh
RUN chown -R postgres:postgres /var/lib/postgresql

ENV POSTGIS_ENABLE_OUTDB_RASTERS=1 \
    POSTGIS_GDAL_ENABLED_DRIVERS=ENABLE_ALL 
