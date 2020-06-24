/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

import java.net.HttpURLConnection;
import java.net.URL;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import org.postgresql.util.PGobject;

import java.text.SimpleDateFormat;

import java.util.Base64;
import java.util.Date;
import java.util.Properties;

import org.apache.commons.io.IOUtils;

import org.json.JSONException;
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
public class JSONDownloader implements nEventListener {

	/** */

	private static JSONObject evtData = new JSONObject();

	private static final String user = "SauberPartner";
	
	private static final String pw = "";
	
	private static final int HTTP_TIMEOUT = 10000;

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
		// Print the timestamp
		if (evt.hasAttributes()) {
			System.out.println("Published on: " + new Date(evt.getAttributes().getTimestamp()).toString());
		}
		// Print the properties
		nEventProperties prop = evt.getProperties();
		if (prop != null) {
			System.out.println("Source: " + prop.get("source"));
			System.out.println("Category: " + prop.get("category"));
			System.out.println("URL: " + prop.get("url")); //JK debug
		}

		// download raster

		if (prop.get("source").equals("hhi")) {
				
			//JSONObject evtData = new JSONObject(new String(evt.getEventData()));
			//TODO tmp example message
			evtData = new JSONObject("{\"category\": \"station-forecast\", \"source\": \"hhi\", \"payload\": {\"url\": \"https://www.geomer.de/dltemp/julian_test.json\", \"predictionStartTime\": 1578232800, \"region\": \"NRW\", \"interval\": 3600, \"creationTime\": 1590565911, \"stationId\": \"WESE\", \"predictionEndTime\": 1578405600, \"type\": \"PM10_GM1H24H\", \"unit\": \"microgm-3\"}, \"timestamp\": 1591679045}");
									
	  	try {
			//String category = evtData.getString("category");
			Long time_stamp = evtData.getLong("timestamp");
			String source = evtData.getString("source");
			
			JSONObject payload = evtData.getJSONObject("payload");				
			
			String request = payload.getString("url");
			String type = payload.getString("type");
			String region = payload.getString("region");

			//TODO leftover metada. use hashmap if needed?  
			/*
			String stationId = payload.getString("stationId");
			Integer interval = payload.getInt("interval"); 
			Integer predictionStartTime = payload.getInt("predictionStartTime"); 
			Integer creationTime = payload.getInt("creationTime"); 
			Integer predictionEndTime = payload.getInt("predictionEndTime"); 
			String unit = payload.getString("unit");
			*/

		// TODO whitelist request URLs

			if (source.equals("hhi")) {
				try {
					this.downloadJSON(request, region, type, time_stamp);
				} catch (IOException e) {
					System.out.println("Could not download JSON file");
					e.printStackTrace();
				}
			}
				
	  	} 
	  	catch(Exception e) {
	  		e.printStackTrace();
	  		System.exit(1);
	  	};
		
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
	 * @param region
	 * @param type 
	 * @param time_stamp
	 * @return
	 * @throws IOException
	 * @throws SQLException 
	 */

	private void downloadJSON(String request, String region, String type, Long time_stamp) throws IOException, JSONException, SQLException {
				
		SimpleDateFormat format = new SimpleDateFormat("yyyyMMddhh");
		String readableTime = format.format(time_stamp*1000);
	
		Path jsonDir = Paths.get("/station_data");
		Files.createDirectories(jsonDir);
		
		String filePathString = "/station_data/"+ region +"_"+ type +"_"+ readableTime +".json"; 
		File jsonFile = new File(filePathString);		
		
		URL url = new URL(request);
		String authStr = user + ":" + pw;
	    String authEncoded = Base64.getEncoder().encodeToString(authStr.getBytes());		
		HttpURLConnection con = (HttpURLConnection) url.openConnection();
		
		con.setRequestMethod("GET");
		con.setRequestProperty("Accept", "application/json");
		con.setRequestProperty  ("Authorization", "Basic " + authEncoded);
		con.setConnectTimeout(HTTP_TIMEOUT);
		con.setReadTimeout(HTTP_TIMEOUT);
		con.connect();

		int status = con.getResponseCode();
		
		if (status == 200) {

		FileOutputStream jsonOut = new FileOutputStream(jsonFile);
		IOUtils.copy(con.getInputStream(), jsonOut);
		jsonOut.close();
		
//		try (BufferedReader br = new BufferedReader(new FileReader(jsonFile))) {
//			   String line;
//			   while ((line = br.readLine()) != null) {
//			       System.out.println(line);
//			   }
//			}                   
	} else if (status == 401) {
		System.out.println("Connection to server unauthorized. Check credentials");
		System.exit(1);
	} else {
		System.out.println("Connection to server failed with HTTP status "+status+". Check connection.");
		System.exit(1);
	}
		//return jsonFile;
		insertDB(filePathString);
		return;
	}

	
	public void insertDB(String filePathString) throws SQLException, IOException {
		
		//setup db connection
		// TODO: cannot resolve "DB" as host within Docker Stack ?!
		// TODO: From Docker secrets
		String url = "jdbc:postgresql://localhost:5430/sauber_data";
		Properties props = new Properties();
		props.setProperty("user","postgres");
		props.setProperty("password","postgres");
		props.setProperty("ssl","false");
		Connection conn = DriverManager.getConnection(url, props);
		conn.setAutoCommit(false);
		
		PreparedStatement inputStmt = conn.prepareStatement("INSERT INTO station_data.raw_input (json_payload,json_message) VALUES(?,?)");

		//read payload from stored json file 
		//add as pgobject for statement
		Path filePath = Paths.get(filePathString);
		String payloadString = Files.readString(filePath);
		PGobject payloadObject = new PGobject();
		payloadObject.setType("jsonb");
		payloadObject.setValue(payloadString);
		inputStmt.setObject(1, payloadObject);	
	
		//add message metadata to pgobject
		String msgString = evtData.toString();
		PGobject msgObject = new PGobject();
		msgObject.setType("jsonb");
		msgObject.setValue(msgString);		
		inputStmt.setObject(2, msgObject);	
	
		int insertReturn = inputStmt.executeUpdate();
	
		if (insertReturn == 1) {
			conn.commit();
			inputStmt.close();
			
			Statement parseStmt = conn.createStatement();
			String selectQuery = "SELECT station_data.parsejson()";
			
			ResultSet rSet = parseStmt.executeQuery(selectQuery);
			
			while(rSet.next()) {
				  String output = rSet.getString(1);
				  System.out.println(output);
			}
			
			System.out.println("Inserted "+insertReturn+" row/s into JSON raw input table");
			System.exit(0);
		} else
			System.out.println("Could not insert JSON");
			System.exit(1);
		}
	}