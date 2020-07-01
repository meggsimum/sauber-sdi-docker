/*
 * Script to publish SAUBER rasters as granules into the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import fetch from 'node-fetch';
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging, verboseLogging} from './js-utils/logging.js';
import dockerSecret from './js-utils/docker-secrets.js';

const verbose = process.env.GSPUB_VERBOSE;

const postgRestUrl = process.env.GSPUB_PG_REST_URL || 'http://localhost:3000';
const postgRestUser = process.env.GSPUB_PG_REST_USER;
const postgRestPw = dockerSecret.read('pgrst_password.txt') || process.env.GSPUB_PG_REST_PW;

const rasterMetaTable = process.env.GSPUB_RASTER_META_TBL || 'raster_metadata';

const geoserverUrl = process.env.GSPUB_GS_REST_URL || 'http://localhost:8080/geoserver/rest/';
const geoserverUser = dockerSecret.read('geoserver_user.txt') || process.env.GSPUB_GS_REST_USER;
const geoserverPw = dockerSecret.read('geoserver_password.txt') || process.env.GSPUB_GS_REST_PW;

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

  unpublishedRasters.forEach(rasterMetaInf => {
    verboseLogging('publish raster', rasterMetaInf);

    // add raster to GeoServer mosaic and mark as published
    addRasterToGeoServer(rasterMetaInf).then((success) => {
      if (success) {
        markRastersPublished(rasterMetaInf);
      } else {
        console.warn('Could not add raster/granule "', rasterMetaInf.name_mosaic ,'" to GeoServer');
      }
    });
  });
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
  verboseLogging('Adding raster to GeoServer mosaic ...');

  // TODO remove defaults
  const ws = rasterMetaInf.workspace || 'sauber-sdi';
  const covStore = rasterMetaInf.coverage_store || 'nrw_pm10_gm1h24h_mosaic';
  const imgMosaic = rasterMetaInf.image_mosaic || 'nrw_pm10_gm1h24h_mosaic';

  if (verbose) {
    const granulesBefore = await grc.imagemosaics.getGranules(ws, covStore, imgMosaic);
    if (!granulesBefore) {
      exitWithErrMsg('Could not load granules for ' + ws + ' | ' + covStore + ' | ' + imgMosaic + ' - ABORT!');
    }
    verboseLogging('Having', granulesBefore.features.length, 'granules before adding');
  }

  // add granule by GeoServer REST API
  const coverageToAdd = 'file://' + rasterMetaInf.image_path;
  verboseLogging('Try to add Granule', coverageToAdd);
  const added = await grc.imagemosaics.addGranuleByServerFile(ws, covStore, coverageToAdd);
  verboseLogging('Added granule by server file', added);

  if (verbose) {
    const granulesAfter = await grc.imagemosaics.getGranules(ws, covStore, imgMosaic);
    verboseLogging('Having', granulesAfter.features.length, 'granules after adding');
  }

  console.info('Added granule', rasterMetaInf.image_path, 'in GeoServer mosaic', rasterMetaInf.name_mosaic);

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
