ARG POSTGRES_VERSION=12
ARG TIMESCALE_VERSION=2.1.0

FROM timescale/timescaledb:${TIMESCALE_VERSION}-pg${POSTGRES_VERSION}
LABEL maintainer="Julian Kaeflein<Julian.Kaeflein@geomer.de>"

ARG POSTGIS_VERSION=3.1.1
ENV POSTGIS=${POSTGIS_VERSION}

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps ca-certificates openssl tar \
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

RUN mkdir -p /docker-entrypoint-initdb.d
COPY docker-entrypoint-initdb.d/* docker-entrypoint-initdb.d/
RUN chmod 775 /docker-entrypoint-initdb.d/*

COPY resources/bin/import-data.sh /usr/local/bin/import-data.sh
RUN chmod 775 /usr/local/bin/import-data.sh

COPY resources/conf/pg_hba.conf /tmp/
RUN chown postgres:postgres /tmp/pg_hba.conf
RUN chmod 600 /tmp/pg_hba.conf

RUN chown -R postgres:postgres /var/lib/postgresql

ENV POSTGIS_ENABLE_OUTDB_RASTERS=1 \
    POSTGIS_GDAL_ENABLED_DRIVERS=ENABLE_ALL