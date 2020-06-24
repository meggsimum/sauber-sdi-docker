# To start the container, the following environment vars must be set:
# PGRST_USER_FILE / PGRST_USER: Mutual exclusive parameters to define a user name
#    - either from docker secret file or directly.
# PGRST_PASSWORD_FILE / PGRST_PASSWORD: Mutual exclusive parameters to define a password -
#    - either from docker secret file or directly.
# PGRST_JWT_SECRET_FILE / PGRST_JWT_SECRET: Mutual exclusive parameters to define a jwt secret -
#    - either from docker secret file or directly.
# PGRST_DB_SERVER: Server name to build the connection URI.
# PGRST_DB_PORT: Server port to build the connection URI.
# PGRST_DB_NAME: Database name to build the connection URI.
# PGRST_DB_SCHEMA: The database schema to expose to REST clients
# PGRST_DB_ANON_ROLE: The database role to use when executing commands on
#   behalf of unauthenticated clients.
# For more information see https://postgrest.org/en/v5.0/install.html#configuration.

FROM postgrest/postgrest:latest
LABEL maintainer="Felix Schmenger<Felix.Schmenger@geomer.de>"
LABEL maintainer="Christian Mayer<chris@meggsimum.de>"


USER root
RUN apt-get update && apt-get -y upgrade
RUN apt-get update && apt-get install -y make git curl wget 

# RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
# RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
# RUN apt-get update && apt-get install -y postgresql-server-dev-11 postgresql-11-pgtap

# RUN mkdir "/pgjwt"
# WORKDIR "/pgjwt"
# COPY . .
# RUN make && make install

# Declare all optional environment variables used in configuration files and set them to defaults.
# The values provided here are fallbacks and can be overwritten in the docker-compose.yml file.
ENV \
  PGRST_DB_POOL=10 \
  PGRST_SERVER_HOST=*4 \
  PGRST_SERVER_PORT=3000 \
  PGRST_SERVER_PROXY_URI= \
  PGRST_SECRET_IS_BASE64=false \
  PGRST_JWT_AUD= \
  PGRST_ROLE_CLAIM_KEY=.role \
  PGRST_MAX_ROWS= \
  PGRST_PRE_REQUEST=

COPY ./resources/config/postgrest.conf /etc/postgrest.conf

# Set an entrypoint script to obtain secrets from the secure mount point.
COPY ./resources/bin/docker-entrypoint.sh /usr/local/bin/
RUN chmod 775 /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3000
