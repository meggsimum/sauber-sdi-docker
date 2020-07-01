/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.imageio.ImageIO;

import org.json.JSONObject;
import org.json.JSONString;
import org.postgresql.util.PGobject;

import com.pcbsys.foundation.filters.fEventStringRule;
import com.pcbsys.foundation.system.memory.fPage.type;
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
	
	//TODO inject, read from docker secrets
	static final String user = "SauberPartner";
	
	static final String pw = "";
	
	
	private static JSONObject evtData = new JSONObject();
	
	private static String evtPollutant = "";
	
	private static String evtRegion = "";
	
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

			// parse incoming message 
		
			//TODO tmp example message
			evtData = new JSONObject("{\"category\": \"raster-forecast\", \"source\": \"hhi\", \"payload\": {\"url\":\"https://www.geomer.de/dltemp/nrw_2020010109.tif\", \"predictionStartTime\": 1578240000, \"region\": \"NRW\", \"interval\": 3600, \"creationTime\": 1590573111, \"stationId\": \"WESE\", \"predictionEndTime\": 1578412800, \"type\": \"PM10_GM1H24H\", \"unit\": \"microgm-3\"}, \"timestamp\": 1591686245}");
			//JSONObject evtData = new JSONObject(new String(evt.getEventData()));

			String category = evtData.getString("category");			

			Long time_stamp = evtData.getLong("timestamp"); //get timestamp and convert to format readable by geoserver regex
			SimpleDateFormat format = new SimpleDateFormat("yyyyMMddhh");
			String readableTime = format.format(time_stamp*1000);
			
			JSONObject payload = evtData.getJSONObject("payload");	
			String request = payload.getString("url");

			evtRegion = payload.getString("region");
			evtPollutant = payload.getString("type");
			
			String fileName = evtRegion.toLowerCase()+"_"+evtPollutant+"_"+readableTime;
			
			// TODO Check if there actually is "realtime" data
			if (category.contains("forecast")) {
				fileName = "fc_"+fileName;				
			} else if (category.contains("realtime")) {
				fileName = "rt_"+fileName;				
			} else {
				System.out.println("Error: Could not determine if real time / forecast");
				System.exit(1);
			}
			
	
			System.out.println("URL to raster to download: " + request);

			// TODO whitelist request URLs

			try {

				this.downloadRaster(request, fileName);

			} catch (IOException e) {
				System.out.println("Could not download raster file");
				e.printStackTrace();
			}
		}
	return;
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
	//private File downloadRaster(String request) throws IOException {
	private void downloadRaster(String request, String fileName) throws IOException {
		URL url = new URL(request);
		String authStr = user + ":" + pw;
	    String authEncoded = Base64.getEncoder().encodeToString(authStr.getBytes());		
		HttpURLConnection con = (HttpURLConnection) url.openConnection();
		con.setRequestMethod("GET");
		con.setRequestProperty  ("Authorization", "Basic " + authEncoded);
		con.setConnectTimeout(HTTP_TIMEOUT);
		con.setReadTimeout(HTTP_TIMEOUT);

		int status = con.getResponseCode();
		System.out.println("HTTP STATUS: " + status);


		if (status == 200) {

			InputStream is = con.getInputStream();
			BufferedImage buffImage = ImageIO.read(is);
	
			// write to tmp. location
			String contentType = con.getContentType();
			String fileEnding = RasterDownloader.mappingFormatEnding.get(contentType);
			System.out.println("Detected " + contentType + " -> using ." + fileEnding + " as ending");

			String outDir = "/opt/raster_data/"+ evtRegion.toLowerCase() +"/"+ evtPollutant.toLowerCase() +"/";

			String filePathStr = outDir + fileName +"."+ fileEnding;
			
			File imgFile = new File(filePathStr);
			imgFile.getParentFile().mkdirs(); 
			imgFile.createNewFile();
			
			ImageIO.write(buffImage, fileEnding, imgFile);
		
			System.out.println("Raster saved at " + imgFile.getAbsolutePath());
			
			is.close();
			
			try {
				insertRaster(fileName,filePathStr);  // insert raster into database via raster2pgsql
			} catch (IOException e) {
				System.out.println("Error inserting raster into DB");
				e.printStackTrace();
			}
				
			try {
				insertMetadata(filePathStr); // insert raster metadata into db
			} catch (SQLException e) {
				System.out.println("Error inserting raster metadata into DB");
				e.printStackTrace();
			}
			
			
		} else if (status == 401) {
				System.out.println("Connection to server unauthorized. Check credentials");
				System.exit(1);
		} else {
			System.out.println("Connection to server failed with HTTP status "+status+". Check connection.");
			System.exit(1);
		}
			
		//return //imgFile;
		return;
	}
	
	
	private void insertRaster(String fileName, String filePathStr) throws IOException {
		
		
		//declutter process builder args
		String raster2pgsql = "/usr/local/bin/raster2pgsql"; 
		String psql = "/usr/local/bin/psql";
		String schemaName = evtRegion.toLowerCase() +"_"+ evtPollutant.toLowerCase();
		String targetTable = schemaName +"."+ fileName;

		ProcessBuilder pb =
				//new ProcessBuilder("/bin/sh", "-c", raster2pgsql +"-s 4326 -I -C -M -F -t auto"+ filePathStr +" "+  targetTable +"; | psql -h db -U postgres -d sauber_data"); //TODO docker secrets
				//TODO verify r2pg is called in local win env. Delete below.
				new ProcessBuilder("C:/WINDOWS/system32/cmd.exe", "/C", "raster2pgsql -G");
	    Process p = pb.start();
	    
	    //TODO Ouput for r2pg debug convenience. Delete below.
	    BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
	    String line;

	    String temp="";
	    while ((line = reader.readLine()) != null)
	    {
	        temp=temp.concat(line);
	        System.out.println("raster2pgsql: " + line);
	    }
	}
	
	public void insertMetadata(String filePathStr) throws SQLException, IOException {
		
		//setup db connection
		// TODO JK: inject/read params from docker secrets, e.g. host/port/db
		String url = "jdbc:postgresql://localhost:5430/sauber_data"; 
		Properties props = new Properties();
		props.setProperty("user","postgres");
		props.setProperty("password","postgres");
		props.setProperty("ssl","false");
		Connection conn = DriverManager.getConnection(url, props);
		conn.setAutoCommit(false);
		
		//gather info to fill statement for raster metadata table 
		String JSONString = evtData.toString();
		String workspace = "image_mosaics";
		String coverageName = evtRegion.toLowerCase() +"_"+ evtPollutant.toLowerCase();
		String mosaicName = coverageName +"_mosaic";		
				
		PreparedStatement inputStmt = conn.prepareStatement("INSERT INTO image_mosaics.raster_metadata (image_path, source_payload, workspace, coverage_store, image_mosaic, is_published) VALUES(?, ?, ?, ?, ?, ?)");
		
		PGobject jsonObject = new PGobject();
		jsonObject.setType("jsonb");
		jsonObject.setValue(JSONString);
		inputStmt.setString(1, filePathStr);	
		inputStmt.setObject(2, jsonObject);		
		inputStmt.setObject(3, workspace);
		inputStmt.setObject(4, coverageName);
		inputStmt.setString(5, mosaicName);	// TODO complete pollutant name (PM10_GM241H) etc?
		inputStmt.setInt(6, 0);
		
		// execute statement 
		int insertReturn = inputStmt.executeUpdate();
	
		//check if == 1 line was inserted as expected
		if (insertReturn == 1) {
			conn.commit();
			inputStmt.close();
		} else 
			System.out.println("Error: "+insertReturn+" rows inserted");
			System.exit(1);
}
}