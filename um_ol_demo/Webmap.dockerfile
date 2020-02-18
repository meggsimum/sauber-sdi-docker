FROM nginx:alpine
ARG PORT=80

COPY lib /etc/nginx/html/lib/
COPY index.html /etc/nginx/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE ${PORT}
