import GeoServerRestClient from 'geoserver-node-client';
import dockerSecret from './js-utils/docker-secrets.js';
import {framedBigLogging} from './js-utils/logging.js';

const verbose = process.env.GSINIT_VERBOSE;

const geoserverUrl = 'http://geoserver:8080/geoserver/rest/';
const geoserverDefaultUser = 'admin';
const geoserverDefaultPw = 'geoserver';
const role = 'ADMIN';

verboseLogging('GeoServer REST URL: ', geoserverUrl);
verboseLogging('GeoServer Default REST User:', geoserverDefaultUser);
verboseLogging('GeoServer Default REST PW:  ', geoserverDefaultPw);

// read GS login from secrets
const newGeoserverUser = dockerSecret.read('geoserver_user');
const newGeoserverPw = dockerSecret.read('geoserver_password');

/**
 * Adapts security settings for GeoServer
 */
async function adaptSecurity () {
  const user = newGeoserverUser;
  const userPw = newGeoserverPw;

  if (!user || !userPw || user === '' || userPw === '') {
    console.error('No valid user or user password given - EXIT.');
    return;
  }

  const userCreated = await grc.security.createUser(user, userPw);
  if (userCreated) {
    console.info('Successfully created user', user);
  } else {
    console.error('Failed creating user', user);
  }

  const roleAssigend = await grc.security.associateUserRole(user, role);
  if (roleAssigend) {
    console.info(`Successfully added role ${role} to user ${user}`);
  } else {
    console.error(`Failed adding role ${role} to user ${user}`, roleAssigend);
  }

  // disable user
  const adminDisabled = await grc.security.updateUser(geoserverDefaultUser, geoserverDefaultPw, false);
  if (adminDisabled) {
    console.info('Successfully disabled default "admin" user');
  } else {
    console.error('Failed disabling default "admin" user');
  }
}

/**
 * logging util
 * @param {*} _msg Message to log in verbose mode
 */
// eslint-disable-next-line no-unused-vars
function verboseLogging(msg) {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

// check if we can connect to GeoServer REST API
const grc = new GeoServerRestClient(geoserverUrl, geoserverDefaultUser, geoserverDefaultPw);
grc.exists().then(gsExists => {
  if (gsExists === true) {
    framedBigLogging('Start adapting credentials for SAUBER GeoServer ...');

    adaptSecurity();

    framedBigLogging('... DONE adapting credentials for SAUBER GeoServer');
  } else {
    console.error('Could not connect to GeoServer REST API - seems like auth has been changed in this setup!');
  }
});
