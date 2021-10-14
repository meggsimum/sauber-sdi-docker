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
COPY  /sld/ /opt/sld/
COPY  /js-utils/docker-secrets.js /opt/js-utils/docker-secrets.js
COPY  /000_change-auth.js /opt/000_change-auth.js
COPY  /010_init-gs.js /opt/010_init-gs.js
COPY  /wait-for.sh /opt/wait-for.sh

RUN chmod +x /opt/wait-for.sh

CMD ["npm", "start"]
