/*
 * Script to publish SAUBER rasters as granules into the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import fetch from 'node-fetch';
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging} from './js-utils/logging.js';
import dockerSecret from './js-utils/docker-secrets.js';

const verbose = process.env.GSPUB_VERBOSE;

const postgRestUrl = process.env.GSPUB_PG_REST_URL || 'http://postgrest_raster_publisher:3000';
const postgRestUser = process.env.GSPUB_PG_REST_USER;
const postgRestPw = dockerSecret.read('pgrst_password.txt') || process.env.GSPUB_PG_REST_PW;

verboseLogging('PostgREST URL: ', postgRestUrl);
verboseLogging('PostgREST User:', postgRestUser);
verboseLogging('PostgREST PW:  ', postgRestPw);

const rasterMetaTable = process.env.GSPUB_RASTER_META_TBL || 'raster_metadata';

const geoserverUrl = process.env.GSPUB_GS_REST_URL || 'http://geoserver:8080/geoserver/rest/';
const geoserverUser = dockerSecret.read('geoserver_user.txt') || process.env.GSPUB_GS_REST_USER;
const geoserverPw = dockerSecret.read('geoserver_password.txt') || process.env.GSPUB_GS_REST_PW;

verboseLogging('GeoServer REST URL: ', geoserverUrl);
verboseLogging('GeoServer REST User:', geoserverUser);
verboseLogging('GeoServer REST PW:  ', geoserverPw);

// array with blacklisted (mostly non existing) CoverageStores
const ignoreCovStores = [];

/**
 * Main process:
 *  - Queries all unpublished rasters from DB
 *  - Publishes the unpublished rasters in GeoServer mosaic
 *  - Marks the raster as published in the DB
 */
async function publishRasters() {
  framedBigLogging('Start process publishing SAUBER rasters to GeoServer...');

  // Query all unpublished rasters from DB
  const unpublishedRasters = await getUnpublishedRasters();
  // exit if raster metadata could not be loaded
  if (!unpublishedRasters) {
    framedMediumLogging('Could not get raster metadata - ABORT!');
    process.exit(1);
  }

  framedMediumLogging('Checking CoverageStores for existance');

  // check if given CoverageStores exists and blacklist them if not
  await asyncForEach(unpublishedRasters, checkIfCoverageStoresExist);

  framedMediumLogging('Publish rasters')

  await asyncForEach(unpublishedRasters, async (rasterMetaInf) => {
    verboseLogging('Publish raster', rasterMetaInf.image_path);

    await addRasterToGeoServer(rasterMetaInf).then(async (success) => {
      if (success) {
        await markRastersPublished(rasterMetaInf);
      } else {
        console.warn('Could not add raster/granule "', rasterMetaInf.image_path ,'" to store', rasterMetaInf.coverage_store);
      }
      verboseLogging('-----------------------------------------------------\n');
    });
  });

}

/**
 * Checks if GeoServer has the CoverageStore given in the raster meta info.
 * If not it is added to the ignoreCovStores array so it can be ignored in the
 * process.
 *
 * @param {Object} rasterMetaInf
 */
async function checkIfCoverageStoresExist(rasterMetaInf) {
  const ws = rasterMetaInf.workspace;
  const covStore = rasterMetaInf.coverage_store;

  verboseLogging('Checking', covStore, 'if it exists in GeoServer');

  const covStoreObj = await grc.datastores.getCoverageStore(ws, covStore);

  if (!covStoreObj) {
    console.error('CoverageStore', covStore, 'does not exist. Ensure this is created in advance.');
    ignoreCovStores.push(covStore);
  }
}

/**
 * Returns all unpublished rasters from the raster meta info DB.
 *
 * @param {Object[]} publishedRasters
 */
async function getUnpublishedRasters() {
  verboseLogging('Load all unpublished rasters from raster meta info DB ...');

  // add trailing '/' if necessary
  const pgrstUrl = postgRestUrl.endsWith('/') ? postgRestUrl : postgRestUrl + '/';

  try {
    const url = pgrstUrl + rasterMetaTable;
    verboseLogging('URL to load raster meta info:', url);
    // const auth = getPostgRestAuth();

    const response = await fetch(url, {
      // credentials: 'include',
      method: 'GET',
      headers: {
        // Authorization: 'Basic ' + auth
      }
    });

    if (response.status === 200) {
      const rasters = await response.json();

      const rasterToPublish = [];
      rasters.forEach(rasterMetaInf => {
        if (rasterMetaInf.is_published === 0) {
          rasterToPublish.push(rasterMetaInf);
        }
      });

      console.info('Loaded all unpublished rasters from raster meta info DB');

      return rasterToPublish;
    } else {
      console.error('Got non HTTP 200 response (HTTP status code', response.status, ') for loading raster meta info');
      return false;
    }

  } catch (error) {
    return false;
  }
}

/**
 * Publishes the given raster in GeoServer to dedicated mosaic.
 *
 * @param {Object} rasterMetaInf
 */
async function addRasterToGeoServer(rasterMetaInf) {
  verboseLogging('Adding raster to GeoServer mosaic ...', rasterMetaInf.image_path);

  // TODO remove defaults
  const ws = rasterMetaInf.workspace || 'sauber-sdi';
  const covStore = rasterMetaInf.coverage_store || 'nrw_pm10_gm1h24h_mosaic';
  const imgMosaic = rasterMetaInf.image_mosaic || 'nrw_pm10_gm1h24h_mosaic';
  const rasterFile = rasterMetaInf.image_path;

  // exit if coverage store does not exist
  if (ignoreCovStores.includes(covStore)) {
    return false;
  }

  if (verbose) {
    const granulesBefore = await grc.imagemosaics.getGranules(ws, covStore, imgMosaic);
    if (granulesBefore && granulesBefore.features) {
      verboseLogging('Having', granulesBefore.features.length, 'granules before adding', rasterFile);
    }
  }

  // // add granule by GeoServer REST API
  const coverageToAdd = 'file://' + rasterFile;
  verboseLogging('Try to add Granule ...', coverageToAdd);
  const added = await grc.imagemosaics.addGranuleByServerFile(ws, covStore, coverageToAdd);
  verboseLogging('... Added granule by server file', added);

  if (verbose) {
    const granulesAfter = await grc.imagemosaics.getGranules(ws, covStore, imgMosaic);
    verboseLogging('Having', granulesAfter.features.length, 'granules after adding', rasterFile);
  }

  console.info('Added granule', rasterFile, 'in GeoServer mosaic', imgMosaic);

  return added;
}

/**
 * Marks the raster as published in the raster meta info DB.
 *
 * @param {Object} rasterMetaInf
 */
async function markRastersPublished(rasterMetaInf) {
  verboseLogging('Mark raster', rasterMetaInf.image_path ,'as published ...');

  // add trailing '/' if necessary
  const pgrstUrl = postgRestUrl.endsWith('/') ? postgRestUrl : postgRestUrl + '/';

  try {
    const rasterDbId = rasterMetaInf.idpk_image;
    const body = {
      "is_published": 1
    };
    const url = pgrstUrl + rasterMetaTable + '?idpk_image=eq.' + rasterDbId;

    // const auth = getPostgRestAuth();

    const response = await fetch(url, {
      // credentials: 'include',
      method: 'PATCH',
      headers: {
        'Content-type': 'application/json'
        // Authorization: 'Basic ' + auth
      },
      body: JSON.stringify(body)
    });

    verboseLogging('PATCH to raster meta info DB responded with code', response.status);

    if (!response.status === 200 && !response.status === 204) {
      const respText = await response.text();
      console.warn('Failed to mark raster as published in DB', respText);
      console.warn('It is very likely that your raster meta info DB is out of sync with GeoServer!');
    } else {
      console.info('Marked raster', rasterMetaInf.image_path ,'as published in DB');
    }

  } catch (error) {
    console.error(error);
    return false;
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
 * Returns the authentication header for PostgREST API.
 */
function getPostgRestAuth() {
  return Buffer.from(postgRestUser + ':' + postgRestPw).toString('base64');
}

/**
 *
 * @param {String} msg
 */
function exitWithErrMsg(msg) {
  framedMediumLogging(msg);
  process.exit(1);
}

function verboseLogging(msg) {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

// check if we can connect to GeoServer REST API
const grc = new GeoServerRestClient(geoserverUrl, geoserverUser, geoserverPw);
grc.exists().then(gsExists => {
  if (gsExists === true) {
    // start publishing process
    publishRasters();
  } else {
    exitWithErrMsg('Could not connect to GeoServer REST API - ABORT!');
  }
});
