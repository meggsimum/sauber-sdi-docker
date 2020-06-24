/*
 * Script to publish SAUBER rasters as granules into the SAUBER SDI.
 *
 * @author C. Mayer, meggsimum
 */
import fetch from 'node-fetch';
import GeoServerRestClient from 'geoserver-node-client';

const verbose = true;

const postgRestUrl = 'http://localhost:3000';
const postgRestUser = '';
const postgRestPw = '';

const rasterMetaTable = 'raster_metadata';
const dataBasePath = '/opt/raster_data/';

const geoserverUrl = 'http://localhost:8080/geoserver';
const geoserverUser = 'admin';
const geoserverPw = 'geoserver';

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

  try {
    const url = postgRestUrl + rasterMetaTable;
    // const auth = getPostgRestAuth();

    const response = await fetch(url, {
      // credentials: 'include',
      method: 'GET',
      headers: {
        // Authorization: 'Basic ' + auth
      }
    });
    const rasters = await response.json();

    const rasterToPublish = [];
    rasters.forEach(rasterMetaInf => {
      if (rasterMetaInf.is_published === 0) {
        rasterToPublish.push(rasterMetaInf);
      }
    });

    console.info('Loaded all unpublished rasters from raster meta info DB');

    return rasterToPublish;
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

  if (verbose) {
    const granulesBefore = await grc.imagemosaics.getCoverages('imagemosaic_test', 'nrw_no2', 'nrw_no2_mosaic');
    verboseLogging('Having', granulesBefore.features.length, 'granules before adding');
  }

  // add granule by GeoServer REST API
  const coverageToAdd = 'file://' + dataBasePath + rasterMetaInf.rel_path;
  verboseLogging('Try to add Granule', coverageToAdd);
  const added = await grc.imagemosaics.addGranuleByServerFile('imagemosaic_test', 'nrw_no2', coverageToAdd);
  verboseLogging('Added granule by server file', added);

  if (verbose) {
    const granulesAfter = await grc.imagemosaics.getCoverages('imagemosaic_test', 'nrw_no2', 'nrw_no2_mosaic');
    verboseLogging('Having', granulesAfter.features.length, 'granules after adding');
  }

  console.info('Added granule', rasterMetaInf.rel_path, 'in GeoServer mosaic', rasterMetaInf.name_mosaic);

  return added;
}

/**
 * Marks the raster as published in the raster meta info DB.
 *
 * @param {Object} rasterMetaInf
 */
async function markRastersPublished(rasterMetaInf) {
  verboseLogging('Mark raster', rasterMetaInf.rel_path ,'as published ...');

  try {
    const rasterDbId = rasterMetaInf.idpk_image;
    const body = {
      "is_published": 1
    };
    const url = postgRestUrl + rasterMetaTable + '?idpk_image=eq.' + rasterDbId;
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
      console.info('Marked raster', rasterMetaInf.rel_path ,'as published in DB');
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
 * Logs the given message, when `verbose` flag is set to true.
 *
 * @param {*} msg
 */
function verboseLogging(msg) {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

/**
 * Logs message embedded in a big frame.
 *
 * @param {String} msg
 */
function framedBigLogging(msg) {
  console.log('##############################################################');
  console.log(msg);
  console.log('##############################################################');
  console.log();
}

/**
 * Logs message embedded in a medium frame.
 *
 * @param {String} msg
 */
function framedMediumLogging(msg) {
  console.log('--------------------------------------------------------------');
  console.log(msg);
  console.log('--------------------------------------------------------------');
  console.log();
}

// check if we can connect to GeoServer REST API
const grc = new GeoServerRestClient(geoserverUrl, geoserverUser, geoserverPw);
grc.exists().then(gsExists => {
  if (gsExists !== true) {
    framedMediumLogging('Could not connect to GeoServer REST API - ABORT!');
    process.exit(1);
  }
});

publishRasters();
