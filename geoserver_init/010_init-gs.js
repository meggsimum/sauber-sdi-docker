/*
 * Script to init the GeoServer within the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging} from './js-utils/logging.js';
import dockerSecret from './js-utils/docker-secrets.js';

const verbose = process.env.GSINIT_VERBOSE;

const geoserverUrl = process.env.GSPUB_GS_REST_URL || 'http://geoserver:8080/geoserver/rest/';
const newGeoserverUser = dockerSecret.read('geoserver_user');
const newGeoserverPw = dockerSecret.read('geoserver_password');

const workspacesList = process.env.GSINIT_WS || 'station_data,image_mosaics';
const stationWorkspace = process.env.GSINIT_STATION_WS || 'station_data';
const stationDataStore = process.env.GSINIT_STATION_DS || 'station_data';
const pgHost = process.env.GSINIT_PG_HOST || 'db';
const pgPort = process.env.GSINIT_PG_PORT || '5432';
const pgUser = process.env.GSINIT_PG_USER || 'app';
const proxyBaseUrl = process.env.GSINIT_PROXY_BASE_URL;
const pgPassword = dockerSecret.read('app_password') || process.env.GSINIT_PG_PW;
const pgSchema = process.env.GSINIT_PG_SCHEMA || 'station_data';
const pgDb = process.env.GSINIT_PG_DB || 'sauber_data';

verboseLogging('-----------------------------------------------');

verboseLogging('GS REST URL:    ', geoserverUrl);
verboseLogging('Workspaces:     ', workspacesList);
verboseLogging('Station WS:     ', stationWorkspace);
verboseLogging('Station DS:     ', stationDataStore);
verboseLogging('PG Host:        ', pgHost);
verboseLogging('PG Port:        ', pgPort);
verboseLogging('PG User:        ', pgUser);
verboseLogging('Proxy Base URL: ', proxyBaseUrl);
verboseLogging('PG Schema:      ', pgSchema);
verboseLogging('PG Database:    ', pgDb);

/**
 * Main process:
 *  - Create workspaces
 *  - Change user + password
 *  - Set proxy base url
 *  - Create store and layer for stations
 */
async function initGeoserver() {
  framedBigLogging('Start initalizing SAUBER GeoServer...');

  await createWorkspaces();

  await setProxyBaseUrl();

  await createPostgisDatastore();

  framedBigLogging('... DONE initalizing SAUBER GeoServer');
}

/**
 * Sets the proxy base url if it is provided
 */
 async function setProxyBaseUrl () {
  if (!proxyBaseUrl) {
    // no proxy base url provided
    return;
  }

  const proxyBaseUrlChanged = await grc.settings.updateProxyBaseUrl(proxyBaseUrl);
  if (proxyBaseUrlChanged) {
    console.info(`Set proxy base url to "${proxyBaseUrl}"`);
  } else {
    console.info('Setting proxy base url failed.');
  }
}

/**
 * Creates the desired project workspaces.
 */
async function createWorkspaces() {
  framedMediumLogging('Creating workspaces...');

  console.info('Configuring the workspaces ', workspacesList);

  const workspaces = workspacesList.split(',');
  await asyncForEach(workspaces, async ws => {
    const wsCreated = await grc.workspaces.create(ws);
    if (wsCreated) {
      console.info('Successfully created workspace', wsCreated);
    }
  });
}

/**
 * Creates a DataStore for our PostGIS database.
 */
async function createPostgisDatastore() {
  framedMediumLogging('Creating PostGIS data store...');

  const success = await grc.datastores.createPostgisStore(
    stationWorkspace, stationDataStore, pgHost, pgPort, pgUser, pgPassword,
    pgSchema, pgDb
  );

  if (success) {
    console.info('Successfully created PostGIS store');
  }
}

/**
 * Creates the station layer.
 */
// async function createStationsLayer() {
//   framedMediumLogging('Creating stations layer...');
//
//   const workspace = 'station_data';
//   const dataStore = 'station_data';
//   const stationLayerName = 'fv_stations';
//   const srs = 'EPSG:3035';
//
//   const success = await grc.layers.publishFeatureType(workspace, dataStore, stationLayerName, stationLayerName, stationLayerName, srs);
//
//   if (success) {
//     console.info('Successfully created stations layer ', stationLayerName);
//   }
// }

/**
 * Helper to perform asynchronous forEach.
 * Found at https://codeburst.io/javascript-async-await-with-foreach-b6ba62bbf404
 *
 * @param {*[]} array
 * @param {Function} callback
 */
async function asyncForEach(array, callback) {
  for (let index = 0; index < array.length; index++) {
    await callback(array[index], index, array);
  }
}

/**
 * Exits script and logs an error message.
 *
 * @param {String} msg The error message to log before exiting
 */
function exitWithErrMsg(msg) {
  framedMediumLogging(msg);
  process.exit(1);
}

/**
 * logging util
 * @param {*} msg Message to log in verbose mode
 */
// eslint-disable-next-line no-unused-vars
function verboseLogging(msg) {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

// check if we can connect to GeoServer REST API
const grc = new GeoServerRestClient(geoserverUrl, newGeoserverUser, newGeoserverPw);
grc.exists().then(gsExists => {
  if (gsExists === true) {
    initGeoserver();
  } else {
    exitWithErrMsg('Could not connect to GeoServer REST API - ABORT!');
  }
});
