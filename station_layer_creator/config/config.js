import dockerSecret from './../js-utils/docker-secrets.js';

const config = {
  postgresHost: process.env.SAUBER_POSTGRES_HOST || 'db',
  postgresPort: process.env.SAUBER_POSTGRES_PORT || 5432,
  postgresDb: process.env.SAUBER_POSTGRES_DB || 'sauber_data',
  postgresUser: process.env.SAUBER_POSTGRES_USER || 'sauber_manager',
  postgresPw: dockerSecret.read('sauber_manager_password') || process.env.SAUBER_POSTGRES_PW,

  geoserverUrl: process.env.SAUBER_GS_URL || 'https://sauber-sdi.meggsimum.de/geoserver',
  geoserverRestUser: dockerSecret.read('geoserver_user') || process.env.SAUBER_GS_USER || 'sauber_geoserver',
  geoserverRestPw: dockerSecret.read('geoserver_password') || process.env.SAUBER_GS_PW,
  geoserverWs: process.env.STCR_GS_WS || 'station_data',
  geoserverDs: process.env.STCR_GS_DS || 'station_data',
  stationsTypeName: process.env.STCR_STATIONS_TYPENAME || 'station_data:fv_stations',

  srs: process.env.SAUBER_SRS || 'EPSG:3035'
};

export default config;
