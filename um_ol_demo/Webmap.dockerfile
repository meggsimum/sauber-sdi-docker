FROM nginx:alpine
ARG PORT=80

#COPY index.html /usr/share/nginx/html/index.html
#COPY lib /usr/share/nginx/html/lib/
COPY lib /etc/nginx/html/lib/
COPY index.html /etc/nginx/html/index.html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE ${PORT}
