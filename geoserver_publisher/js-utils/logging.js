/**
 * Logs the given message, when `verbose` flag is set to true.
 *
 * @param {*} msg
 */
export function verboseLogging(msg) {
  if (verbose) {
    console.log.apply(console, arguments);
  }
}

/**
 * Logs message embedded in a big frame.
 *
 * @param {String} msg
 */
export function framedBigLogging(msg) {
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
export function framedMediumLogging(msg) {
  console.log('--------------------------------------------------------------');
  console.log(msg);
  console.log('--------------------------------------------------------------');
  console.log();
}
