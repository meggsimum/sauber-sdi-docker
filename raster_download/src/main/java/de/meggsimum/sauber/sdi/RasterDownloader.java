/**
 *
 */
package de.meggsimum.sauber.sdi;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;
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

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.json.JSONObject;
import org.postgresql.util.PGobject;

import com.pcbsys.nirvana.client.nChannel;
import com.pcbsys.nirvana.client.nChannelAlreadyExistsException;
import com.pcbsys.nirvana.client.nChannelAttributes;
import com.pcbsys.nirvana.client.nConsumeEvent;
import com.pcbsys.nirvana.client.nEventListener;
import com.pcbsys.nirvana.client.nSession;
import com.pcbsys.nirvana.client.nSessionAttributes;
import com.pcbsys.nirvana.client.nSessionFactory;

/**
 * Retrieve messages from universal messaging channel 
 * Download raster from URL 
 * Get path where image mosaic is defined 
 * Insert raster data, metadata	 into database
 *
 * @author Lisa Scherf, Software AG
 * @author C. Mayer, meggsimum
 * @author J. Kaeflein, geomer
 */
public class RasterDownloader implements nEventListener {

	/** */
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

	// read from docker secrets in constructor
	private String hhiRestUser = null;
	private String hhiRestPw = null;
	private String dbUserPw = null;
	private String hhiIP = null;
	private String dbUser = System.getenv("dbuser");
	
	/**
	 * 
	 * @throws Exception
	 */
	public RasterDownloader() throws Exception {
		this.resolveSecrets();
	}

	/**
	 * 
	 * @throws Exception
	 */

	 
	public void resolveSecrets() throws Exception {
				
		String workingDir = System.getProperty("user.dir");
		
		// load HHI REST user from docker secret or use local dev file as backup
		File secretFileHhiRestUsrCtn  = new File("/run/secrets/hhi_rest_user");
		File secretFileHhiRestUsrLoc  = new File(workingDir + "/../secrets/hhi_rest_user.txt");
		if (secretFileHhiRestUsrCtn .exists()) {
			InputStream fis = new FileInputStream(secretFileHhiRestUsrCtn );
			this.hhiRestUser = IOUtils.toString(fis, "UTF-8");
		} else if (secretFileHhiRestUsrLoc .exists()) {
			System.out.println("Using local backup secret at " + secretFileHhiRestUsrLoc.getAbsolutePath());
			InputStream fis = new FileInputStream(secretFileHhiRestUsrLoc );
			this.hhiRestUser = IOUtils.toString(fis, "UTF-8");
		} else {
			throw new FileNotFoundException("Not able not load REST user from secrets");
		}

		// load HHI REST password from docker secret or use local dev file as backup
		File secretFilePwCtn = new File("/run/secrets/hhi_rest_pw");
		File secretFilePwLoc = new File(workingDir + "/../secrets/hhi_rest_pw.txt");
		if (secretFilePwCtn.exists()) {
			InputStream fis = new FileInputStream(secretFilePwCtn);
			this.hhiRestPw = IOUtils.toString(fis, "UTF-8");
		} else if (secretFilePwLoc.exists()) {
			System.out.println("Using local backup secret at " + secretFilePwLoc.getAbsolutePath());
			InputStream fis = new FileInputStream(secretFilePwLoc);
			this.hhiRestPw = IOUtils.toString(fis, "UTF-8");
		} else {
			throw new FileNotFoundException("Not able not load REST password from secrets");
		}
	
		// load database password from docker secret or use local dev file as backup
		File secretFileDbPwCtn = new File("/run/secrets/app_password");
		File secretFileDbPwLoc = new File(workingDir + "/../secrets/app_password.txt");
		if (secretFileDbPwCtn.exists()) {
			InputStream fis = new FileInputStream(secretFileDbPwCtn);
			this.dbUserPw = IOUtils.toString(fis, "UTF-8");
		} else if (secretFileDbPwLoc.exists()) {
			System.out.println("Using local backup secret at " + secretFileDbPwLoc.getAbsolutePath());
			InputStream fis = new FileInputStream(secretFileDbPwLoc);
			this.dbUserPw = IOUtils.toString(fis, "UTF-8");
		} else {
			throw new FileNotFoundException("Not able not load DB password from secrets");
			
		}
		
		File secretFileIpCtn = new File("/run/secrets/hhi_ip_address");
		File secretFileIpLoc = new File(workingDir + "/../secrets/hhi_ip_address.txt");
		if (secretFileIpCtn.exists()) {
			InputStream fis = new FileInputStream(secretFileIpCtn);
			this.hhiIP = IOUtils.toString(fis, "UTF-8");
		} else if (secretFileIpLoc.exists()) {
			System.out.println("Using local backup secret at " + secretFileIpLoc.getAbsolutePath());
			InputStream fis = new FileInputStream(secretFileIpLoc);
			this.hhiIP = IOUtils.toString(fis, "UTF-8");
		} else {
			throw new FileNotFoundException("Not able not load HHI IP address from secrets");
		}
	}

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


		// Print the timestamp
		if (evt.hasAttributes()) {
			System.out.println("Published on: " + new Date(evt.getAttributes().getTimestamp()).toString());
		}

		try {	
			// parse incoming message
			RasterDownloader.evtData = new JSONObject(new String(evt.getEventData()));

			String category = evtData.getString("category");
			SimpleDateFormat format = new SimpleDateFormat("yyyyMMddHH");

			JSONObject payload = evtData.getJSONObject("payload");
			String request = payload.getString("url");			
			Long predictionStartTime  = payload.getLong("predictionStartTime"); //get timestamp and convert to format readable by geoserver regex
			String readableTime = format.format(predictionStartTime *1000);

			evtRegion = payload.getString("region");
			evtPollutant = payload.getString("type");	
			String fileName = evtRegion.toLowerCase()+"_"+evtPollutant+"_"+readableTime;

			// TODO Check if there actually will be "real time" data
			if (category.contains("forecast")) {
				fileName = "fc_"+fileName;
			} else if (category.contains("realtime")) {
				fileName = "rt_"+fileName;
			} else {
				System.out.println("Error: Could not determine if real time / forecast");
				System.exit(1);
			}

			URL requestUrl = new URL(request);
			InetAddress requestAddress = InetAddress.getByName(requestUrl.getHost());
			String requestIP = requestAddress.getHostAddress();
			
			if (requestIP.equals(hhiIP)) {
				try {
					this.downloadRaster(request, fileName);
				} catch (IOException | InterruptedException e) {
					System.out.println("Could not download&insert raster file");
					e.printStackTrace();
					System.exit(1);
				}
			} else {
				System.out.println("Request URL " + requestIP + " does not match allowed IP");
				System.exit(1);
			}
		} catch (Exception e) {
	  		e.printStackTrace();
	  		System.exit(1);
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
	 * @throws InterruptedException 
	 */
	private void downloadRaster(String request, String fileName) throws IOException, InterruptedException {
		
		URL url = new URL(request);
		String authStr = this.hhiRestUser + ":" + this.hhiRestPw;
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

			// write to tmp. location
			String contentType = con.getContentType();
			String fileEnding = RasterDownloader.mappingFormatEnding.get(contentType);
			System.out.println("Detected " + contentType + " -> using ." + fileEnding + " as ending");

			String outDir = "/opt/raster_data/"+ evtRegion.toLowerCase() +"/"+ evtPollutant.toLowerCase() +"/";

			String filePathStr = outDir + fileName +"."+ fileEnding;

			File imgFile = new File(filePathStr);

			Boolean rasterExists = true;

			if (!imgFile.isFile()) {
				imgFile.getParentFile().mkdirs();
				imgFile.createNewFile();
				rasterExists = false;
			}

			FileUtils.copyInputStreamToFile(is, imgFile);
			String absPath = imgFile.getAbsolutePath();
			System.out.println("Raster saved at " + absPath);
			
			is.close();

			try {
				insertRaster(fileName, absPath, rasterExists);  // insert raster into database via raster2pgsql
			} catch (IOException e) {
				System.out.println("Error inserting raster into DB");
				e.printStackTrace();
		  		System.exit(1);
			} catch (SQLException e) {
				System.out.println("SQL Error:");
				e.printStackTrace();
		  		System.exit(1);
			}

		} else if (status == 401) {
				System.out.println("Connection to server unauthorized. Check credentials");
				System.exit(1);
		} else {
			System.out.println("Connection to server failed with HTTP status "+status+". Check connection.");
			System.exit(1);
		}

		return;
	}

	private void insertRaster(String fileName, String absPath, Boolean rasterExists) throws SQLException, IOException, InterruptedException {

		//declutter process builder args
		String schemaName = evtRegion.toLowerCase().replaceAll("\\s","") +"_"+ evtPollutant.toLowerCase().replaceAll("\\s","");
		String targetTable = schemaName +"."+ fileName;		
		String url = "jdbc:postgresql://db:5432/sauber_data";
		Properties props = new Properties();
		props.setProperty("user",dbUser);
		props.setProperty("password",dbUserPw);
		props.setProperty("ssl","false");
		Connection conn = DriverManager.getConnection(url, props);
		conn.setAutoCommit(false);
		
		String createStmt = "CREATE SCHEMA IF NOT EXISTS " + schemaName +" AUTHORIZATION "+ dbUser;
		
		PreparedStatement createSchema = conn.prepareStatement(createStmt);
		
		createSchema.executeUpdate();
		conn.commit();
		createSchema.close();
		ProcessBuilder pb =
				new ProcessBuilder("/bin/sh", "-c", "raster2pgsql -d -R -I -C -M -t auto "+ absPath +" "+  targetTable + " | PGPASSWORD="+ dbUserPw +" psql -h db -U "+ dbUser +" -d sauber_data -v ON_ERROR_STOP=ON");

		Process p = pb.inheritIO().start();
		p.waitFor();
		
		Integer exitcode = p.exitValue();
		
		if (exitcode != 0) {
			System.out.println("Error inserting raster tiles: Return code "+ exitcode +". Exiting.");
			System.exit(1);
		}

		if (!rasterExists) {
			try {
				insertMetadata(absPath, conn);
			} catch (SQLException e) {
				System.out.println("Error inserting raster metadata into DB");
				e.printStackTrace();
			}	
		} else {
			System.out.println("Sucessfully updated raster.");
		}
			
	}	
	
	private void insertMetadata(String filePathStr, Connection conn) throws SQLException, IOException {

		//gather info to fill statement for raster metadata table
		String JSONString = evtData.toString();
		String workspace = "image_mosaics";
		String coverageName = evtRegion.toLowerCase() +"_"+ evtPollutant.toLowerCase();
		String mosaicName = coverageName +"_mosaic";
		
		PreparedStatement inputStmt = conn.prepareStatement("INSERT INTO image_mosaics.raster_metadata (image_path, source_payload, workspace, coverage_store, image_mosaic, is_published) VALUES( ?, ?, ?, ?, ?, ?)");

		PGobject jsonObject = new PGobject();
		jsonObject.setType("jsonb");
		jsonObject.setValue(JSONString);
		inputStmt.setString(1, filePathStr);
		inputStmt.setObject(2, jsonObject);
		inputStmt.setObject(3, workspace);
		inputStmt.setObject(4, coverageName);
		inputStmt.setString(5, mosaicName);
		inputStmt.setInt(6, 0);

		// execute statement
		int insertReturn = inputStmt.executeUpdate();

		//check if == 1 line was inserted as expected
		if (insertReturn == 1) {
			conn.commit();
			inputStmt.close();
			conn.close();
			System.out.println("Successfully inserted raster and metadata.");
		} else
			System.out.println("Error: "+insertReturn+" rows inserted");
			System.exit(1);
	}
}
