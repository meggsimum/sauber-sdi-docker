# geoserver_init

`geoserver_init` service in order to initialize the SAUBER GeoServer:

  - Adapting the login credentials
  - Creating the workspaces
  - Creating the PostGIS DataStore connect
  - Creating the stations layer

The service is executed directly after the `geoserver` service is fully
available (ensured by a `wait.for.sh` script).
