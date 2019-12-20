/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import javax.imageio.ImageIO;

import org.json.JSONObject;

import com.pcbsys.nirvana.client.nChannel;
import com.pcbsys.nirvana.client.nChannelAlreadyExistsException;
import com.pcbsys.nirvana.client.nChannelAttributes;
import com.pcbsys.nirvana.client.nConsumeEvent;
import com.pcbsys.nirvana.client.nEventListener;
import com.pcbsys.nirvana.client.nEventProperties;
import com.pcbsys.nirvana.client.nSession;
import com.pcbsys.nirvana.client.nSessionAttributes;
import com.pcbsys.nirvana.client.nSessionFactory;

/**
 * Demo class to receive messages via Universal Messaging Channel and download a
 * possible reference to a raster file.
 *
 * @author Lisa Scherf, Software AG
 * @author C. Mayer, meggsimum
 */
public class RasterDownloader implements nEventListener {

	/** */
	private static final int HTTP_TIMEOUT = 10000;

	private static final Map<String, String> mappingFormatEnding = new HashMap<String, String>() {
		/** */
		private static final long serialVersionUID = 8044765805880427026L;

		{
			put("image/tiff", "tiff");
			put("image/jpg", "jpg");
		}
	};

	/** */
	protected nSession mySession = null;

	/** */
	protected nSessionAttributes nsa = null;

	/** */
	private nChannel myChannel;

	/**
	 * Connects to the given Universal Messaging realms and channel. Then listens
	 * for events and prints them to the console until the user pressed a key and
	 * stops the program.
	 *
	 * @param rname  a String[] containing the possible RNAME values
	 * @param chname the channel name to listen for events
	 */
	public void subscribe(String[] rname, String chname) {

		this.constructSession(rname);

		// Subscribes to the specified channel
		try {

			// Create HeartbeatChannel and obtain channel reference
			try {
				nChannelAttributes cattrib = new nChannelAttributes();
				cattrib.setMaxEvents(0);
				cattrib.setTTL(0);
				cattrib.setType(nChannelAttributes.PERSISTENT_TYPE);
				cattrib.setName(chname);
				myChannel = mySession.createChannel(cattrib);
			} catch (nChannelAlreadyExistsException e) {
				nChannelAttributes chattr = new nChannelAttributes();
				chattr.setName(chname);
				myChannel = mySession.findChannel(chattr);
			}

			// Add this object as a subscribe to the channel with the specified
			// message selector and start eid
			myChannel.addSubscriber(this);

			// Stay subscribed until the user presses any key
			System.out.println("Press any key to quit !");
			BufferedInputStream bis = new BufferedInputStream(System.in);
			try {
				bis.read();
			} catch (Exception read) {
			} // Ignore this

			// Remove this subscriber
			myChannel.removeSubscriber(this);
		}

		// Handle errors
		catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		// Close the session we opened
		try {
			nSessionFactory.close(mySession);
		} catch (Exception ex) {
		}
		// Close any other sessions within this JVM so that we can exit
		nSessionFactory.shutdown();
	}

	/**
	 * A callback is received by the API to this method each time an event is
	 * received from the Universal Messaging channel. Be carefull not to spend too
	 * much time processing the message inside this method, as until it exits the
	 * next message can not be pushed.
	 *
	 * @param evt nConsumeEvent object containing the message received from the
	 *            channel
	 */
	public void go(nConsumeEvent evt) {

		// Print the message data
		System.out.println("Event data : " + new String(evt.getEventData()));

		// Print the timestamp
		if (evt.hasAttributes()) {
			System.out.println("Published on: " + new Date(evt.getAttributes().getTimestamp()).toString());
		}
		// Print the properties
		nEventProperties prop = evt.getProperties();
		if (prop != null) {
			System.out.println("Source: " + prop.get("source"));
			System.out.println("Category: " + prop.get("category"));
		}

		// download raster

		if (prop.get("source").equals("hhi")) {
			JSONObject evtData = new JSONObject(new String(evt.getEventData()));
			String request = evtData.getString("url");

			System.out.println("URL to raster to download: " + request);

			// TODO whitelist request URLs

			// tmp. overwrite to a trusted resource
			request = "https://sauber-projekt.meggsimum.de/demo-data/STK10_32354_5670_6_nwfarbe.tif";
//			request = "https://dummyimage.com/100x100/000/fff.jpg&text=SAUBER+Dummy+Raster";

			try {

				this.downloadRaster(request);

			} catch (IOException e) {
				System.out.println("Could not download raster file");
				e.printStackTrace();
			}
		}

	}

	/**
	 * Create a Session to the given Universal Messaging realms with session
	 * attributes, a session factory
	 *
	 * @param rname Array with the Universal Messaging server addresses and ports
	 */
	private void constructSession(String[] rname) {
		// Create a realm session attributes object from the array of strings
		try {
			nsa = new nSessionAttributes(rname, 2);
			nsa.setFollowTheMaster(true);
			nsa.setDisconnectOnClusterFailure(false);
			nsa.setName(getClass().getSimpleName());
			mySession = nSessionFactory.create(nsa);
		} catch (Exception ex) {
			System.out.println("Error creating Session Attributes. Please check your RNAME");
			System.exit(1);
		}

		// Initialise the Universal Messaging session. This physically opens the
		// connection to the
		// Universal Messaging realm, using the specified protocol.
		try {
			mySession.init();
		}
		// Handle errors
		catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}

	/**
	 *
	 * @param request
	 * @return
	 * @throws IOException
	 */
	private File downloadRaster(String request) throws IOException {
		URL url = new URL(request);
		HttpURLConnection con = (HttpURLConnection) url.openConnection();
		con.setRequestMethod("GET");
		con.setConnectTimeout(HTTP_TIMEOUT);
		con.setReadTimeout(HTTP_TIMEOUT);

		int status = con.getResponseCode();
		System.out.println("HTTP STATUS: " + status);
		// TODO check if status equals 200

		InputStream is = con.getInputStream();
		BufferedImage buffImage = ImageIO.read(is);

		// write to tmp. location
		String contentType = con.getContentType();
		String fileEnding = RasterDownloader.mappingFormatEnding.get(contentType);
		System.out.println("Detected " + contentType + " -> using ." + fileEnding + " as ending");

		File imgFile = File.createTempFile("sauber-raster", "." + fileEnding);
		ImageIO.write(buffImage, fileEnding, imgFile);

		System.out.println("Temp raster saved at " + imgFile.getAbsolutePath());

		is.close();

		return imgFile;
	}

}
