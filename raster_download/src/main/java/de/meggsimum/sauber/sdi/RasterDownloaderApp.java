/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.io.IOException;

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
		RasterDownloader mySelf = null;
		try {
			mySelf = new RasterDownloader();
		} catch (IOException ioe) {
//			ioe.printStackTrace();
			System.out.println("Error while resolving secret files for RasterDownloader");
			System.exit(-1);
		} catch (Exception e) {
			System.out.println("Error while resolving secret files for RasterDownloader");
			System.exit(-1);
		}

		// Subscribe to the channel specified
		while (true) {
			mySelf.subscribe(umUrl, channel);
		}
	}

}
