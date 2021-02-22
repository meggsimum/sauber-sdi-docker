/*
 * Util to handle Docker secrets.
 * Heavily inspired by https://medium.com/better-programming/how-to-handle-docker-secrets-in-node-js-3aa04d5bf46e
 * All KUDOS to the author of the article.
 *
 * @author C. Mayer, meggsimum
 */
import fs from 'fs';

const dockerSecret = {};

/**
 * Reads out the Docker secret.
 *
 * @param {String} secretName
 */
dockerSecret.read = function read(secretName) {
  try {
    return fs.readFileSync(`/run/secrets/${secretName}`, 'utf8');
  } catch(err) {
    if (err.code !== 'ENOENT') {
      console.error(`An error occurred while trying to read the secret: ${secretName}. Err: ${err}`);
    } else {
      console.log(`Could not find the secret, probably not running in swarm mode: ${secretName}. Err: ${err}`);
    }
    return false;
  }
};

export default dockerSecret;
