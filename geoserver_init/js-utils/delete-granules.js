/*
 * Script to publish SAUBER rasters as granules into the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import fetch from 'node-fetch';
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging} from './logging.js';
import dockerSecret from './docker-secrets.js';

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


async function deleteGranules() {

  // Query all unpublished rasters from DB
  const publishedRasters = await getPublishedRasters();
  // exit if raster metadata could not be loaded
  if (!publishedRasters) {
    framedMediumLogging('Could not get raster metadata - ABORT!');
    process.exit(1);
  }

  publishedRasters.forEach(rasterMetaInf => {
    verboseLogging('delete raster / granule', rasterMetaInf);

    grc.imagemosaics.deleteSingleGranule(
      rasterMetaInf.workspace, rasterMetaInf.coverage_store,
      rasterMetaInf.image_mosaic, rasterMetaInf.image_path
    ).then((succ) => {
      if (succ) {
        markRastersUnPublished(rasterMetaInf);
      }
    });
  });
}

/**
 * Returns all unpublished rasters from the raster meta info DB.
 *
 * @param {Object[]} publishedRasters
 */
async function getPublishedRasters() {
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

      const rasterToDelete = [];
      rasters.forEach(rasterMetaInf => {
        if (rasterMetaInf.is_published === 1) {
          rasterToDelete.push(rasterMetaInf);
        }
      });

      console.info('Loaded all published rasters from raster meta info DB');

      return rasterToDelete;
    } else {
      console.error('Got non HTTP 200 response (HTTP status code', response.status, ') for loading raster meta info');
      return false;
    }

  } catch (error) {
    return false;
  }
}

/**
 * Marks the raster as published in the raster meta info DB.
 *
 * @param {Object} rasterMetaInf
 */
async function markRastersUnPublished(rasterMetaInf) {
  verboseLogging('Mark raster', rasterMetaInf.image_path ,'as published ...');

  // add trailing '/' if necessary
  const pgrstUrl = postgRestUrl.endsWith('/') ? postgRestUrl : postgRestUrl + '/';

  try {
    const rasterDbId = rasterMetaInf.idpk_image;
    const body = {
      "is_published": 0
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
      console.warn('Failed to mark raster as unpublished in DB', respText);
      console.warn('It is very likely that your raster meta info DB is out of sync with GeoServer!');
    } else {
      console.info('Marked raster', rasterMetaInf.image_path ,'as unpublished in DB');
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
    deleteGranules();
  } else {
    exitWithErrMsg('Could not connect to GeoServer REST API - ABORT!');
  }
});