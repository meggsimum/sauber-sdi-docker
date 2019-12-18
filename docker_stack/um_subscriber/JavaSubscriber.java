/**
 * @author Lisa Scherf
 * Software AG, Darmstadt, Germany
 * 30.10.2019
 * 
 * Documentation: https://documentation.softwareag.com/onlinehelp/Rohan/num10-3/10-3_UM_webhelp/index.html#page/um-webhelp%2Fco-index_dg_17.html%23
 *
 * This example shows how to receive an event from a Universal Messaging Channel.
 * When executed, the program listens to the channel "HeartbeatChannel" and is waiting for events.
 * If an event is published, the program prints the information of the event to the console.
 */

import com.pcbsys.nirvana.client.*;
import java.io.*;
import java.util.Date;
import java.net.URL;
import java.net.HttpURLConnection;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import org.json.JSONObject;

public class JavaSubscriber implements nEventListener {

	private static JavaSubscriber mySelf = null;

	protected nSession mySession = null;
	protected nSessionAttributes nsa = null;
	
	private nChannel myChannel;
	
	public static String request;

	// Universal Messaging protocol, server adress and port
	static String um_server = System.getenv("umserver");
	static String[] RNAME={"nsp://" + um_server};
	// Name of the channel where the event should be published
	static String CHNAME="HeartbeatChannel";

	public static void main (String[] args) {
		
		// Create an instance for this class
	    mySelf = new JavaSubscriber();
	    
	    // Subscribe to the channel specified
	    mySelf.subscribe(RNAME, CHNAME);
	}
	
	/**
	 * Connects to the given Universal Messaging realms and channel.
	 * Then listens for events and prints them to the console until the user pressed a key 
	 * and stops the program. 
	 * 
	 * @param rname a String[] containing the possible RNAME values
	 * @param chname the channel name to listen for events
	 */
	public void subscribe(String[] rname, String chname) {
				
		mySelf.constructSession(rname);
		
		// Subscribes to the specified channel
	    try {
	    	
	      //Create HeartbeatChannel and obtain channel reference
		  try {
			nChannelAttributes cattrib = new nChannelAttributes(); 
			cattrib.setMaxEvents(0); 
			cattrib.setTTL(0); 
			cattrib.setType(nChannelAttributes.PERSISTENT_TYPE); 
			cattrib.setName(chname); 
			myChannel=mySession.createChannel(cattrib);
		  } catch(nChannelAlreadyExistsException e){
			nChannelAttributes chattr=new nChannelAttributes();
			chattr.setName(chname);
			myChannel=mySession.findChannel(chattr);
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
	   * received from the Universal Messaging channel. Be carefull not to spend too much time
	   * processing the message inside this method, as until it exits the next
	   * message can not be pushed.
	   *
	   * @param evt nConsumeEvent object containing the message received from the channel
	   */
	public void go(nConsumeEvent evt) {		
		/* 
		 * Insert handling of the events here!
		 * You get the event properties with evt.getProperties() and 
		 * the event data with evt.getEventData().
		 * 
		 * The data is a JSON-Object transformed to a string and the properties are separated fields.
		 * 
		 */
		
	    // Print the message tag
	    //System.out.println("Event tag : " + evt.getEventTag());
	    // Print the message data
	    System.out.println("Event data : " + new String(evt.getEventData()));
	    // Print the timestamp
	    if (evt.hasAttributes()) {
	    	System.out.println("Published on: " + new Date(evt.getAttributes().getTimestamp()).toString());
	    }
	    // Print the properties
	    nEventProperties prop = evt.getProperties();
	    if (prop != null) {
	    	System.out.println("Source: "+ prop.get("source"));
	    	System.out.println("Category: "+ prop.get("category"));
	    }
		JSONObject evtdata = new JSONObject (new String(evt.getEventData()));
		String request = evtdata.getString("url");  
		System.out.println("Raster URL: "+request);
		try {
			downloadRaster(request);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Create a Session to the given Universal Messaging realms with 
	 * session attributes, a session factory
	 * 
	 * @param rname Array with the Universal Messaging server addresses and ports
	 */
	private void constructSession(String[] rname) {
		//Create a realm session attributes object from the array of strings
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
		
		//Initialise the Universal Messaging session. This physically opens the connection to the
	    //Universal Messaging realm, using the specified protocol. 
	    try {
	        mySession.init();
	    }
	    //Handle errors
	    catch (Exception e) {
	      e.printStackTrace();
	      System.exit(1);
	    }
	}
	int HTTP_TIMEOUT = 10000;

	private File downloadRaster(String request) throws IOException {
        URL url = new URL(request);
		System.out.println(url);
        HttpURLConnection con = (HttpURLConnection) url.openConnection();
        con.setRequestMethod("GET");
        con.setConnectTimeout(HTTP_TIMEOUT);
        con.setReadTimeout(HTTP_TIMEOUT);

        int status = con.getResponseCode();
        System.out.println("HTTP STATUS: " + status);
        //TODO check if status equals 200

        InputStream is = con.getInputStream();
        BufferedImage buffImage = ImageIO.read(is);

        // write to tmp. location
        File imgFile = File.createTempFile("sauber-raster", ".jpg");
        ImageIO.write(buffImage, "jpg", imgFile);
		System.out.println("Temp Raster created"); 
        is.close();

        return imgFile;
    }
}
