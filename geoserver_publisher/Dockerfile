FROM node:14-alpine3.12
LABEL maintainer="chris@meggsimum.de"

COPY  /package.json /opt/package.json
COPY  /index.js /opt/index.js

WORKDIR /opt
RUN npm install --only=production

# copy crontabs for root user
COPY cronjob/config /etc/crontabs/root

# start crond with log level 8 in foreground, output to stderr
CMD ["crond", "-f", "-d", "8"]
