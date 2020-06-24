/**
 *
 */
package de.meggsimum.sauber.sdi;

/**
 * @author C. Mayer, meggsimum
 */
public class JSONDownloaderApp {

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
		JSONDownloader mySelf = new JSONDownloader();

		// Subscribe to the channel specified
		mySelf.subscribe(umUrl, channel);

	}

}
