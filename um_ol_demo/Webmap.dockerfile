# Courtesy of Christian Mayer <chris@meggsimum.de>

FROM node:lts-alpine AS builder
WORKDIR /app
COPY . .
RUN npm install && npm run build

FROM nginx:alpine
WORKDIR /etc/nginx/html
COPY --from=builder /app/dist/ .
COPY nginx.conf ../nginx.conf

ARG PORT=80

EXPOSE ${PORT}