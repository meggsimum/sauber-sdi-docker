/*
 * Script to init the GeoServer within the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging} from './js-utils/logging.js';
import dockerSecret from './js-utils/docker-secrets.js';
import path from 'path';
import fs from 'fs';

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
const nameSpaceBaseUrl = process.env.GSINIT_NAMESPACE_BASE_URL || 'https://www.meggsimum.de/namespace/';

// constants
const SLD_SUFFIX = '.sld';
const SLD_DIRECTORY = 'sld';

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
verboseLogging('Namespace URL:  ', nameSpaceBaseUrl);

/**
 * Main process:
 *  - Create workspaces
 *  - Set proxy base url
 *  - Create store and layer for stations
 *  - Create layer for all stations: station_data:fv_stations
 */
async function initGeoserver() {
  framedBigLogging('Start initalizing SAUBER GeoServer...');

  await createWorkspaces();

  await setProxyBaseUrl();

  await createPostgisDatastore();

  await createStationsLayer();

  await createStyles();

  framedBigLogging('... DONE initalizing SAUBER GeoServer');
}

/**
 * Loops over all files of the SLD directory and publishes them to GeoServer.
 */
async function createStyles() {
  framedMediumLogging('Creating styles...');

  const workspace = 'image_mosaics';

  const sldFiles = await fs.readdirSync(SLD_DIRECTORY);

  // loop over SLD files
  await asyncForEach(sldFiles, async file => {
    const styleName = path.parse(file).name;
    const extension = path.parse(file).ext;

    if (extension !== SLD_SUFFIX) {
      // skip files that are not SLD
      return;
    }
    await createSingleStyle(SLD_DIRECTORY, styleName, workspace);
  });
}

/**
 * Reads a SLD file and publishes it to GeoServer.
 *
 * We assume the name of the file without extension is the name of the style.
 *
 * @param {String} directory The directory where the SLD files are located
 * @param {String} styleName The name of the style and the file
 * @param {String} workspace The workspace to publish the style to
 */
async function createSingleStyle(directory, styleName, workspace) {
  console.log(`Creating style '${styleName}' ... `);
  const styleFile = styleName + SLD_SUFFIX;

  const styleExists = await grc.styles.getStyleInformation(styleName, workspace);

  if (styleExists) {
    console.log(`Style already exists. SKIP`);
  }
  else {
    const sldFilePath = path.join(directory, styleFile);
    const sldBody = fs.readFileSync(sldFilePath, 'utf8');

    // publish style
    const stylePublished = await grc.styles.publish(workspace, styleName, sldBody);
    if (stylePublished) {
      console.log(`Successfully created style '${styleName}'`);
    } else {
      console.log(`Creation of style '${styleName}' failed`);
    }
  }
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
    console.error('Failed setting proxy base url: ', proxyBaseUrl);
  }
}

/**
 * Creates the desired project workspaces.
 */
async function createWorkspaces() {
  framedMediumLogging('Creating workspaces...');

  console.info('Configuring the workspaces', workspacesList);

  const workspaces = workspacesList.split(',');
  await asyncForEach(workspaces, async ws => {
    // create namespace URI from workspace name
    const nameSpaceUri = nameSpaceBaseUrl + ws;
    const wsCreated = await grc.namespaces.create(ws, nameSpaceUri);
    if (wsCreated) {
      console.info('Successfully created workspace', wsCreated);
    } else {
      console.error('Failed creating workspace (maybe already existing)  ',
          ws, wsCreated);
    }
  });
}

/**
 * Creates a DataStore for our PostGIS database.
 */
async function createPostgisDatastore() {
  framedMediumLogging('Creating PostGIS data store...');

  const stationNamespace = nameSpaceBaseUrl + stationWorkspace;
  const created = await grc.datastores.createPostgisStore(
    stationWorkspace, stationNamespace, stationDataStore, pgHost, pgPort, pgUser, pgPassword,
    pgSchema, pgDb
  );

  if (created) {
    console.info('Successfully created PostGIS store', stationDataStore);
  } else {
    console.error('Failed creating PostGIS store (maybe already existing) ',
        stationDataStore, created);
  }
}

/**
 * Creates the stations layer.
 */
 async function createStationsLayer() {
  framedMediumLogging('Creating stations layer...');

  const workspace = 'station_data';
  const dataStore = 'station_data';
  const stationLayerName = 'fv_stations';
  const nativeName = stationLayerName;
  const stationLayerTitle = 'All Stations';
  const abstract = 'All stations in the SDI.';
  const srs = 'EPSG:3035';
  // BBOX of the SRS
  const nativeBoundingBox = {
    minx: 1896628.6179337814,
    maxx: 7104179.202731105,
    miny: 1098068.900387804,
    maxy: 6829874.453973565
  };

  verboseLogging(`WS: ${workspace}, DS: ${dataStore}, NATIVE: ${nativeName}, NAME: ${stationLayerName}, TITLE: ${stationLayerTitle}`)

  const success = await grc.layers.publishFeatureType(
    workspace, dataStore, nativeName, stationLayerName, stationLayerTitle, srs,
    true, abstract, nativeBoundingBox
  );

  if (success) {
    console.info('Successfully created stations layer', stationLayerName);
  } else {
    console.error('Failed creating stations layer', stationLayerName);
  }
}

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
