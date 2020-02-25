# Courtesy of Christian Mayer <chris@meggsimum.de>

FROM nginx:alpine
WORKDIR /etc/nginx/html
COPY /lib/um-js/nirvana.js ./lib/um-js/nirvana.js
COPY /index.html .
COPY /index.js .
COPY nginx.conf ../nginx.conf

ARG PORT=80

EXPOSE ${PORT}
