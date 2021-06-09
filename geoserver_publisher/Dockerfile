FROM node:14-alpine3.12
LABEL maintainer="chris@meggsimum.de"


# install git to resolve git based dependency in package.json
# install zip to pack *.properties files for ImageMosaic GS Store
RUN apk add --no-cache git zip
RUN git --version
RUN zip --version

COPY  /package.json /opt/package.json

WORKDIR /opt
RUN npm install --only=production

# copy JS sources
COPY  /gs-img-mosaic-tpl/ /opt/gs-img-mosaic-tpl/
COPY  /js-utils/logging.js /opt/js-utils/logging.js
COPY  /js-utils/docker-secrets.js /opt/js-utils/docker-secrets.js
COPY  /index.js /opt/index.js

# copy crontabs for root user
COPY cronjob/config /etc/crontabs/root

# start crond with log level 8 in foreground, output to stderr
CMD ["crond", "-f", "-d", "8"]
