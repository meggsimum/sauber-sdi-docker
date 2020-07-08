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
