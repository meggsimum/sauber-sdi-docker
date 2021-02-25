FROM node:14-alpine3.12
LABEL maintainer="chris@meggsimum.de"


# install git to resolve git based dependency in package.json
RUN apk add --no-cache git
RUN git --version

COPY  /package.json /opt/package.json

WORKDIR /opt
RUN npm install --only=production

# copy JS sources
COPY  /js-utils/logging.js /opt/js-utils/logging.js
COPY  /js-utils/docker-secrets.js /opt/js-utils/docker-secrets.js
COPY  /index.js /opt/index.js

CMD ["npm", "start"]
