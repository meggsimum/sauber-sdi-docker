/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.io.IOException;

/**
 * @author C. Mayer, meggsimum
 * @author J. Kaeflein, geomer
 */
public class JSONDownloaderApp {

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		// Universal Messaging protocol, server address and port
		String umServer = System.getenv("umserver");
		String umChannel = System.getenv("umchannel");

		System.out.println("Connecting to UM server: " + umServer);
		
		String[] umUrl = { "nsp://" + umServer };


		// Create an instance for this class
		JSONDownloader mySelf = null;
		try {
			mySelf = new JSONDownloader();
		} catch (IOException ioe) {
//			ioe.printStackTrace();
			System.out.println("Error while resolving secret files for JSONDownloader: "+ioe.getMessage());
			System.exit(-1);
		} catch (Exception e) {
			System.out.println("Error while resolving secret files for JSONDownloader");
			System.exit(-1);
		}

		// Subscribe to the channel specified
		while (true) {
			mySelf.subscribe(umUrl, umChannel);
		}
	}

}