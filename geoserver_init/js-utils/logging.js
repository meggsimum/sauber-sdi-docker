/**
 * Logs given message embedded in a big frame.
 *
 * @param {String} msg Message to log
 */
export function framedBigLogging(msg) {
  console.log('##############################################################');
  console.log(msg);
  console.log('##############################################################');
  console.log();
}

/**
 * Logs given message embedded in a medium frame.
 *
 * @param {String} msg Message to log
 */
export function framedMediumLogging(msg) {
  console.log('--------------------------------------------------------------');
  console.log(msg);
  console.log('--------------------------------------------------------------');
  console.log();
}
