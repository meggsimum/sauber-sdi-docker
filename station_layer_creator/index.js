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

const verbose = process.env.STCR_VERBOSE || true;

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
verboseLogging('GeoServer WS:', config.geoserverWs);
verboseLogging('GeoServer DS:', config.geoserverDs);
verboseLogging('GeoServer Station FT:', config.stationsTypeName);

// create re-usable GeoServer REST Client instance
const grc = new GeoServerRestClient(geoserverRestUrl, config.geoserverRestUser, config.geoserverRestPw);

/**
 * Main process creating the DB views and the corresponding GeoServer layers
 * for all the station+pollutant combinations and for aggregated stations for
 * a pollutant data.
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

    // all pollutants for later usage
    let allPollutants = [];

    // go over all stations
    await asyncForEach(stationsFc.features, async station => {
      const attrs = station.properties;
      const stationCode = attrs.station_code;

      framedMediumLogging(`${attrs.station_name} (${attrs.station_code})`);

      // go over all pollutants for station
      const pollutants = JSON.parse(attrs.pollutants);
      // collect all pollutants for later usage
      allPollutants = allPollutants.concat(pollutants);

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

        const dbView = await createDbView(pollutant, stationCode);
        if (dbView) {
          await createGeoServerLayer(dbView, stationCode);
        } else {
          console.error(`No valid DB returned, skipping GeoServer layer creation for ${stationCode} ${pollutant}`);
        }
      });
    });

    // unique list of pollutants
    const uniquePollutants = allPollutants.filter((x, i, a) => a.indexOf(x) == i);
    console.info('Creating aggregated station layers for pollutants', uniquePollutants);

    await asyncForEach(uniquePollutants, async pollutant => {
      console.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      console.log('Pollutant', pollutant);

      const dbView = await createDbView(pollutant);
      if (dbView) {
        await createGeoServerLayer(dbView);
      } else {
        console.error(`No valid DB returned, skipping GeoServer aggregated layer creation for ${pollutant}`);
      }
    })

  } else {
    console.error('Got non HTTP 200 response (HTTP status code', response.status, ') for loading station WFS data');
    return false;
  }
}

/**
 * Creates a DB view for either
 *   - the combination of a station and a measured pollutant or
 *   - the aggregated stations for a pollutant
 *
 * @param {String} pollutant The pollutant, e.g. NO2_AM1H
 * @param {String} stationCode The station code, e.g. RODE
 */
async function createDbView(pollutant, stationCode) {
  let sql;
  let dbViewName = null;
  const Client = pg.Client;
  const client = new Client({
    host: config.postgresHost,
    port: config.postgresPort,
    database: config.postgresDb,
    user: config.postgresUser,
    password: config.postgresPw,
  });

  try {

    await client.connect();

    if (stationCode) {
      // Combined Station + Pollutant Prediction View as
      console.info(`Creating combined station+pollutant DB view for ${stationCode} ${pollutant}`);

      sql = `SELECT station_data.create_prediction_view('${stationCode}', '${pollutant}');`;
      verboseLogging('Executing SQL:', sql);
      const dbResp = await client.query(sql);

      if (dbResp.rows.length > 0 && dbResp.rows[0].create_prediction_view &&
            dbResp.rows[0].create_prediction_view !== '1') {
        dbViewName = dbResp.rows[0].create_prediction_view;

        console.info(`Created DB view ${dbViewName} for ${stationCode} ${pollutant}`);
      } else {
        console.error(`Creation of DB view for ${stationCode} ${pollutant} failed!`);
      }
    } else {
      // Aggregated Station Prediction View as
      console.info(`Creating aggregated pollutant DB view for ${pollutant}`);

      sql = `SELECT station_data.create_component_view('${pollutant}');`;
      verboseLogging('Executing SQL:', sql);
      const dbResp = await client.query(sql);

      if (dbResp.rows.length > 0 && dbResp.rows[0].create_component_view &&
            dbResp.rows[0].create_prediction_view !== '1') {
        dbViewName = dbResp.rows[0].create_component_view;

        console.info(`Created aggregated stations for pollutant DB view ${dbViewName} for ${pollutant}`);
      } else {
        console.error(`Creation of aggregated stations for pollutant DB view for ${pollutant} failed!`);
      }
    }

    await client.end();

  } catch (error) {
      console.log('Error while creating DB view', error);
      return;
  }

  return dbViewName;
}

/**
 * Creates a GeoServer layer based on the given DB view.
 *
 * @param {String} dbViewName The DB view name as base for the GeoServer layer
 * @param {String} stationCode The station code, e.g. RODE
 */
async function createGeoServerLayer(dbViewName, stationCode) {
  console.info(`Creating GeoServer layer for ${dbViewName}`);

  // creating combined station+pollutant layer?
  const stationLayer = !!stationCode;

  const connected = await grc.exists();

  if (!connected) {
    exitWithErrMsg('Could not connect to GeoServer - EXIT!');
  }

  let layerName = dbViewName;

  if (stationLayer) {
    // little hack to fulfill naming convention between station WFS and layer name
    if (stationCode.indexOf('-') !== -1) {
      const pos_ = dbViewName.indexOf("_"); // position of first '_'
      // replace first '_' with '-' due to naming convention
      layerName = dbViewName.replace(dbViewName.substring(pos_, pos_ + 1), "-");

      verboseLogging(`Corrected layer name from ${dbViewName} to ${layerName}`);
    }
  }

  const layerCreated = await grc.layers.publishFeatureType(
    config.geoserverWs, config.geoserverDs, dbViewName,
    layerName, layerName,
    config.srs, true
  );

  if (layerCreated) {
    console.info(`Successfully created GeoServer layer ${layerName}`);

    if (!stationLayer) {
      // enable time dimension for aggregated layers
      const attribute = 'date_time';
      const presentation = 'DISCRETE_INTERVAL';
      const resolutionMs = 3600000; // 1 hour
      const defaultValue = 'MINIMUM';
      const nearestMatch = true;
      const rawNearestMatch = false;
      const acceptableInterval = 'PT30M';
      const timeEnabled = grc.layers.enableTimeFeatureType(
        config.geoserverWs, config.geoserverDs, layerName, attribute,
        presentation, resolutionMs, defaultValue, nearestMatch, rawNearestMatch,
        acceptableInterval
      );
      console.info(`Successfully enabled TIME for dimension for GeoServer layer ${layerName}`);
    }

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
