/**
 *
 */
package de.meggsimum.sauber.sdi;

/**
 * @author C. Mayer, meggsimum
 */
public class RasterDownloaderApp {

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		// Universal Messaging protocol, server address and port
		String umServer = System.getenv("umserver");

		System.out.println("Connecting to UM server: " + umServer);

		String[] umUrl = { "nsp://" + umServer };
		// Name of the channel where the event should be published
		String channel = "HeartbeatChannel";

		// Create an instance for this class
		RasterDownloader mySelf = new RasterDownloader();

		// Subscribe to the channel specified
		while (true) {
		mySelf.subscribe(umUrl, channel);
		}
	}

}
