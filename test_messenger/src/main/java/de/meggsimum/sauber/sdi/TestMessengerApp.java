/**
 *
 */
package de.meggsimum.sauber.sdi;

/**
 * @author J. Kaeflein, geomer
 */
public class TestMessengerApp {

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
		TestMessenger mySelf = new TestMessenger();
		
		String sourceName="hhi";
		String category="areal-forecast";

		// Subscribe to the channel specified
		mySelf.publish(umUrl, umChannel, sourceName, category);
				
	}

}
