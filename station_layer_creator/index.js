/*
 * Script to create station layers in the SAUBER GeoServer offering their
 * pollutant data.
 *
 * @author C. Mayer, meggsimum
 */
import fetch from 'node-fetch';
import pg from 'pg';
import GeoServerRestClient from 'geoserver-node-client';
import {framedBigLogging, framedMediumLogging} from './js-utils/logging.js';
import config from './config/config.js';

const verbose = process.env.STCR_VERBOSE || false;

// DB SETTINGS

verboseLogging('Postgres URL: ', config.postgresHost);
verboseLogging('Postgres Port:', config.postgresPort);
verboseLogging('Postgres DB:', config.postgresDb);
verboseLogging('Postgres User:', config.postgresUser);
verboseLogging('Postgres PW:  ', config.postgresPw);
verboseLogging('--------------------------------');

// GEOSERVER SETTINGS

const geoserverRestUrl = config.geoserverUrl + '/rest';

verboseLogging('GeoServer URL: ', config.geoserverUrl);
verboseLogging('GeoServer REST URL:', geoserverRestUrl);
verboseLogging('GeoServer REST User:', config.geoserverRestUser);
verboseLogging('GeoServer REST PW:', config.geoserverRestPw);
verboseLogging('GeoServer WS:', config.geoserverWs);
verboseLogging('GeoServer DS:', config.geoserverDs);
verboseLogging('GeoServer Station FT:', config.stationsTypeName);

// create re-usable GeoServer REST Client instance
const grc = new GeoServerRestClient(geoserverRestUrl, config.geoserverRestUser, config.geoserverRestPw);

/**
 * Main process creting the DB views and the corresponding GeoServer layers
 * for all the station / pollutant combinations.
 */
async function createStationLayers() {
  framedBigLogging('Start process creating SAUBER station layers in to GeoServer...');

  const stationWfsUrl = `${config.geoserverUrl}/${config.geoserverWs}/ows?service=WFS&version=2.0.0&request=GetFeature&outputFormat=application/json&typeName=${config.stationsTypeName}`;
  verboseLogging('Station WFS Request:', stationWfsUrl);

  const response = await fetch(stationWfsUrl, {
    method: 'GET',
    headers: {
      'Content-type': 'application/json'
    },
  });

  if (response.status === 200) {
    const stationsFc = await response.json();

    console.info(`Found ${stationsFc.features.length} stations registered in SAUBER GeoServer`);

    // go over all stations
    await asyncForEach(stationsFc.features, async station => {
      const attrs = station.properties;
      const stationCode = attrs.station_code;

      framedMediumLogging(`${attrs.station_name} (${attrs.station_code})`);

      // go over all pollutants for station
      const pollutants = JSON.parse(attrs.pollutants);
      await asyncForEach(pollutants, async pollutant => {
        console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

        // check if target layer exists in GeoServer -> no action needed
        const layerName = stationCode.toLowerCase() + '_prediction_' + pollutant.toLowerCase();
        const qLayerName = `${config.geoserverWs}:${layerName}`;
        const layer = await grc.layers.get(qLayerName);
        if (layer) {
          console.info(`GeoServer layer ${qLayerName} exists. Skip.`);
          return;
        }

        const dbView = await createDbView(stationCode, pollutant);
        if (dbView) {
          await createGeoServerLayer(dbView, stationCode);
        } else {
          console.error(`No valid DB returned, skipping GeoServer layer creation for ${stationCode} ${pollutant}`);
        }
      });
    })

  } else {
    console.error('Got non HTTP 200 response (HTTP status code', response.status, ') for loading raster meta info');
    return false;
  }
}

/**
 * Creates a DB view for the combination of a station and a measured pollutant.
 *
 * @param {String} stationCode The station code, e.g. RODE
 * @param {String} pollutant The pollutant, e.g. NO2_AM1H
 */
async function createDbView(stationCode, pollutant) {
  console.info(`Creating DB view for ${stationCode} ${pollutant}`);

  const Client = pg.Client;
  const client = new Client({
    host: config.postgresHost,
    port: config.postgresPort,
    database: config.postgresDb,
    user: config.postgresUser,
    password: config.postgresPw,
  });

  client.connect();
  const sql = `SELECT station_data.create_prediction_view('${stationCode}', '${pollutant}');`;
  verboseLogging('Executing SQL:', sql);
  const dbResp = await client.query(sql);

  let dbViewName = null;
  if (dbResp.rows.length > 0 && dbResp.rows[0].create_prediction_view &&
        dbResp.rows[0].create_prediction_view !== '1') {
    dbViewName = dbResp.rows[0].create_prediction_view;

    console.info(`Created DB view ${dbViewName} for ${stationCode} ${pollutant}`);
  } else {
    console.error(`Creation of DB view for ${stationCode} ${pollutant} failed!`);
  }

  client.end();

  return dbViewName;
}

/**
 * Creates a GeoServer layer based on the given DB view.
 *
 * @param {String} dbViewName The DB view name as base for the GeoServer layer
 * @param {String} stationCode The station code, e.g. RODE
 */
async function createGeoServerLayer(dbViewName, stationCode) {
  console.info(`Creating GeoServer layer for ${stationCode} ${dbViewName}`);

  const connected = await grc.exists();

  if (!connected) {
    exitWithErrMsg('Could not connect to GeoServer - EXIT!');
  }

  let layerName = dbViewName;

  // little hack to fulfill naming convention between station WFS and layer name
  if (stationCode.indexOf('-') !== -1) {
    const pos_ = dbViewName.indexOf("_"); // position of first '_'
    // replace first '_' with '-' due to naming convention
    layerName = dbViewName.replace(dbViewName.substring(pos_, pos_+1), "-");

    verboseLogging(`Corrected layer name from ${dbViewName} to ${layerName}`);
  }

  const layerCreated = await grc.layers.publishFeatureType(
    config.geoserverWs, config.geoserverDs, dbViewName,
    layerName, layerName,
    config.srs, true
  );

  if (layerCreated) {
    console.info(`Successfully created GeoServer layer ${layerName}`);
  } else {
    console.error(`Error while creating GeoServer layer ${layerName}`);
  }
}

// start main process
createStationLayers();

// -------------------------------------------
// HELPERS
// -------------------------------------------

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
 * Logs in case verbose=true.
 */
function verboseLogging() {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

/**
 * Exits the script and logs the given message.
 *
 * @param {String} msg
 */
function exitWithErrMsg(msg) {
  framedMediumLogging(msg);
  process.exit(1);
}
