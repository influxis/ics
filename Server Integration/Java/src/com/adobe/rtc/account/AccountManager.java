package com.adobe.rtc.account;

/*
 *  $File$ $Revision$ $Date$
 *
 *  ADOBE SYSTEMS INCORPORATED
 *    Copyright 2007 Adobe Systems Incorporated
 *    All Rights Reserved.
 *
 *  NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
 *  terms of the Adobe license agreement accompanying it.  If you have received this file from a 
 *  source other than Adobe, then your use, modification, or distribution of it requires the prior 
 *  written permission of Adobe.
 */

import java.io.InputStream;
import java.net.URL;
import java.net.URLEncoder;
import java.util.*;

import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.adobe.rtc.util.*;
import com.adobe.rtc.messaging.*;

/**
 * AccountManager - high-level account manipulation
 *
 * @version $Revision: #6 $ - $Date: 2008/10/21 $
 */
public class AccountManager {

	public final static String VERSION = "$Revision: #6 $ - $Date: 2008/10/21 $";
	
	final static String ROOM_ITEMS     = "meetings";
	final static String TEMPLATE_ITEMS = "templates";
	final static String ARCHIVE_ITEMS = "archives";	
	final static String DEFAULT_ARCHIVE_ID = "__defaultArchive__";
	
	public String url;

	public String authToken = "";
	private Map<String, String> authHeaders = new HashMap<String, String>();
	private Authenticator authenticator = null;
	private String baseURL = null;
	private String contentPath = null;
	private String roomInstance = null;

	/**
	 * Constructor
	 * 
	 * @param url account URL
	 * @throws Exception
	 */
	public AccountManager(String url) throws Exception {
		this.url = url;
		do_initialize();
	}

	private String getContentURL() {
		return baseURL + "app/content" + contentPath;
	}

	/**
	 * Login as guest
	 * 
	 * @param guest guest name
	 * @return true if login succeeds, false if fails
	 * @throws Exception
	 */
	public boolean  login(String guest) throws Exception {
		return login(guest, null);
	}

	/**
	 * Login as the account owner
	 * 
	 * @param user developer's user name
	 * @param password developer's password
	 * @return true if login succeeds, false if fails
	 * @throws Exception
	 */
	public boolean login(String user, String password) throws Exception {

		if (password != null) {
			authToken = authenticator.login(user, password, authHeaders);
		} else {
			authToken = authenticator.guestLogin(user);
		}

		return do_initialize();
	}

	/**
	 * keep the authentication token alive by accessing the account
	 * 
	 * @return true if the authentication token is still valid
	 * @throws Exception
	 */
	public boolean keepalive() throws Exception {
		return keepalive(null, null);
	}

	/**
	 * keep the authentication token alive and re-login if needed
	 * 
	 * @param user developer's user name
	 * @param password developer's password
	 * @return true if the authentication token is still valid
	 * @throws Exception
	 */
	public boolean keepalive(String user, String password) throws Exception {
		contentPath = null;
		if (do_initialize()) return true;
		if (user != null) return login(user, password);
		return false;
	}

	/**
	 * Create a room using the default template
	 * 
	 * @param room room name
	 * @throws Exception
	 */
	public void createRoom(String room) throws Exception {
		createRoom(room, null, false);
	}

	/**
	 * Create a room using the default template
	 * 
	 * @param room room name
	 * @param deleteOnExit autodelete room when session ends
	 * @throws Exception
	 */
	public void createRoom(String room, boolean deleteOnExit) throws Exception {
		createRoom(room, null, deleteOnExit);
	}

	/**
	 * Create a room using the specified template
	 * 
	 * @param room room name
	 * @param template template name
	 * @throws Exception
	 */
	public void createRoom(String room, String template) throws Exception {
		createRoom(room, template, false);
	}

	/**
	 * Create a room using the specified template
	 * 
	 * @param room room name
	 * @param template template name
	 * @param deleteOnExit autodelete room when session ends
	 * @throws Exception
	 */
	public void createRoom(String room, String template, boolean deleteOnExit) throws Exception {

		if (template == null)
			template = "default";

		String data = "mode=xml&room=" + room + "&template=" + template;

		if (deleteOnExit)
			data += "&deleteonexit=true";

		if (authToken != null)
			data += "&" + authToken;

		Utils.http_post(url, data, authHeaders);
	}

	/**
	 * List rooms, templates, or archives
	 * 
	 * @param type specifies if room, template, or archive
	 * @return list of rooms, templates, or archives
	 * @throws Exception
	 * @see ContentItem
	 */
	public List<ContentItem> listItems(String type) throws Exception {

		if (type != AccountManager.TEMPLATE_ITEMS
				&& type != AccountManager.ARCHIVE_ITEMS) {
			// default to listing rooms
			type = AccountManager.ROOM_ITEMS;
		}
		
		List<ContentItem> items = new ArrayList<ContentItem>();

		InputStream data = Utils.http_get(getContentURL() + "/" + type + "/?" + authToken, 
				authHeaders);

		Element repository = Utils.parseXML(data);
		if (repository == null) {
			throw new RTCError("bad-response");
		}
		
		Element children = (Element) repository.getElementsByTagName("children").item(0);
		if (children == null) // no children
			return items;

		NodeList nodes = children.getElementsByTagName("node");
		for (int i = 0; i < nodes.getLength(); i++) {
			Element n = (Element) nodes.item(i);
			String name = n.getElementsByTagName("name").item(0).getTextContent().trim();					
			String desc = null;
			Date created = null;
			NodeList properties = n.getElementsByTagName("property");
			for (int j = 0; j < properties.getLength(); j++) {
				Element p = (Element) properties.item(j);
				if (p.getAttribute("name").equals("cr:description")) {
					desc = p.getTextContent().trim();
				} else if (p.getAttribute("name").equals("jcr:created")) {
					String raw = p.getTextContent().trim();
					// ends with "-HH:MM" and we need to turn this into " -HHMM" so that it will parse!
					raw = raw.substring(0,raw.length()-6) + " " + raw.substring(raw.length()-6,raw.length()-3) + raw.substring(raw.length()-2);
					created = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.S Z").parse(raw);
				}
			}

			items.add(new ContentItem(name, desc, created));
		}

		return items;
	}
	
	/**
	 * Delete room, template, or archive
	 * 
	 * @param item the item name (room, template, or archive name)
	 * @param type the item type (room, template, or archive)
	 * @throws Exception
	 */
	public void delete(String item, String type) throws Exception {
		delete(item, type, false);
	}

	protected void delete(String item, String type, boolean list) throws Exception {
		if (type != AccountManager.TEMPLATE_ITEMS
				&& type != AccountManager.ARCHIVE_ITEMS) {
			// default to deleting rooms
			type = AccountManager.ROOM_ITEMS;
		}
				
		String limitCount = list ? "" : "&count=0";
		String data = "action=delete&response=inline" + limitCount + "&" + authToken;
		Utils.http_post(getContentURL() + "/" + type + "/" + item, data, authHeaders);
	}

	/**
	 * List rooms
	 * 
	 * @throws Exception
	 */
	public List<ContentItem> listRooms() throws Exception {
		return listItems(AccountManager.ROOM_ITEMS);
	}

	/**
	 * List templates
	 * 
	 * @throws Exception
	 */
	public List<ContentItem> listTemplates() throws Exception {
		return listItems(AccountManager.TEMPLATE_ITEMS);
	}

	/**
	 * List archives
	 * 
	 * @throws Exception
	 */
	public List<ContentItem> listArchives() throws Exception {
		return listItems(AccountManager.ARCHIVE_ITEMS);
	}
	
	/**
	 * Delete room
	 * 
	 * @param room room name
	 * @throws Exception
	 */
	public void deleteRoom(String room) throws Exception {
		deleteRoom(room, false);
	}

	protected void deleteRoom(String r, boolean list) throws Exception {
		if (r == null) throw new RTCError("parameter-required");
		delete(r.toLowerCase(), AccountManager.ROOM_ITEMS, list);
	}

	/**
	 * Delete template
	 * 
	 * @param template
	 * @throws Exception
	 */
	public void deleteTemplate(String template) throws Exception {
		deleteTemplate(template, false);
	}

	protected void deleteTemplate(String t, boolean list) throws Exception {
		if (t == null) throw new RTCError("parameter-required");
		delete(t, AccountManager.TEMPLATE_ITEMS, list);
	}

	/**
	 * Delete archive
	 * 
	 * @param archive
	 * @throws Exception
	 */
	public void deleteArchive(String archive) 
	throws Exception {
		deleteArchive(archive, false);
	}

	protected void deleteArchive(String t, boolean list) 
	throws Exception {
		if (t == null) throw new RTCError("parameter-required");
		delete(t, AccountManager.ARCHIVE_ITEMS, list);
	}

	/**
	 * Moves an archive to default template
	 * 
	 * @param archive
	 * @throws Exception
	 */
	public void moveArchive(String archive) 
	throws Exception {
		moveArchive(archive, null);
	}
	
	/**
	 * Moves an archive to a specified template.
	 * 
	 * @param archive
	 * @param template template name	 
	 * @throws Exception
	 */
	public void moveArchive(String archive, String template) 
	throws Exception {
				
		String data = "action=set-property&response=inline&name=cr:description";
		if (template != null) {
			data += "&value=" + template;
		}		
		if (authToken != null) {
			data += "&" + authToken;
		}
		
		Utils.http_post(getContentURL() + "/" + AccountManager.ARCHIVE_ITEMS + "/" + archive, data, authHeaders);
	}
	
	/**
	 * Return a room session for external authentication
	 * 
	 * @param room room name
	 * @throws Exception
	 */
	public Session getSession(String room) throws Exception {
		String[] parts = this.url.split("/");
		Session session = new Session(this.roomInstance, parts[parts.length-1], room);
		session.getSecret(this.baseURL, this.authToken, this.authHeaders);
		return session;
	}

	/**
	 * Invalidate room session
	 * 
	 * @param session authentication session object
	 * @throws Exception
	 */
	public void invalidateSession(Session session) throws Exception {
		session.invalidate(this.baseURL, this.authToken, this.authHeaders);
	}

	/**
	 * Return the node configuration
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @return the node configuration
	 * @throws Exception
	 * @see NodeConfiguration
	 */
	public NodeConfiguration getNodeConfiguration(String room, String collectionName, String nodeName) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String path = "/" + collectionName + "/nodes/" + nodeName + "/configuration";
		InputStream data = Utils.http_get(baseURL + "app/rtc?instance=" + instance + "&path=" + path + "&" + authToken, authHeaders);
		Map<String, Object> result = new HashMap<String, Object>();
		Utils.parseXML(data, RTCCollectionHandler.getResult(result, "result"));

		// return a NodeConfiguration
		RTCModel model = new RTCModel(result);
		RTCModel.Collection rtcColl = model.getCollection(collectionName);
		if (rtcColl == null)
			throw new RTCError("invalid-collection-name");
		
		RTCModel.Node rtcNode = rtcColl.getNode(nodeName);
		if (rtcNode == null)
			throw new RTCError("invalid-node-name");
		
		return rtcNode.getNodeConfiguration();
	}

	/**
	 * Return all items for the specified collection and node
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @return a list of MessageItem
	 * @throws Exception
	 * @see MessageItem
	 */
	public Collection<MessageItem> fetchItems(String room, String collectionName, String nodeName) throws Exception {
		return fetchItems(room, collectionName, nodeName, null);
	}

	/**
	 * Return the specified items for the collection and node
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param itemIDs list of itemID
	 * @return a list of MessageItem
	 * @throws Exception
	 * @see MessageItem
	 */
	public Collection<MessageItem> fetchItems(String room, String collectionName, String nodeName, String itemIDs[]) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String params = "instance=" + instance + "&collection=" + collectionName + "&node=" + nodeName;

		if (itemIDs != null) {
			for (String item : itemIDs)
				params += "&item=" + item;
		}

		InputStream data = Utils.http_get(baseURL + "app/rtc?" + params + "&" + authToken, authHeaders);

		Map<String, Object> result = new HashMap<String, Object>();
		Utils.parseXML(data, RTCCollectionHandler.getResult(result, "result"));

		// return a list of MessageItem
		RTCModel model = new RTCModel(result);
		RTCModel.Collection rtcColl = model.getCollection(collectionName);
		if (rtcColl == null)
			throw new RTCError("invalid-collection-name");

		RTCModel.Node rtcNode = rtcColl.getNode(nodeName);
		if (rtcNode == null)
			throw new RTCError("invalid-node-name");
		
		return rtcNode.getMessageItems();
	}

	/**
	 * Register endpoint URL for webhooks
	 * 
	 * @param endpoint URL for RTC callbacks
	 * @throws Exception
	 */
	public void registerHook(String endpoint) throws Exception {
		 registerHook(endpoint, null);
	}

	/**
	 * Register endpoint URL and "validation" token for webhooks
	 * 
	 * @param endpoint URL for RTC callbacks
	 * @param token "validation" token to pass on callbacks
	 * @throws Exception
	 */
	public void registerHook(String endpoint, String token) throws Exception {
		String acctid = this.roomInstance.split("/")[0];

		String data = "account=" + acctid + "&action=registerhook";
		if (endpoint != null)
			data += "&endpoint=" + URLEncoder.encode(endpoint, "utf-8");
		if (token != null)
			data += "&token=" + URLEncoder.encode(token, "utf-8");
		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);
		
		Element result = Utils.parseXML(res);
		checkStatus(result);
	}
	
	/**
	 * Unregister callback URL (and stop callbacks)
	 * 
	 * @throws Exception
	 */
	public void unregisterHook() throws Exception {
		registerHook(null, null);
	}

	/**
	 * Returns the hook URL and security token for the account.
	 * 
	 * @return EndpointInfo
	 * @throws Exception
	 */
	public EndpointInfo getHookInfo() throws Exception {
		String acctid = this.roomInstance.split("/")[0];
		InputStream data = Utils.http_get(baseURL 
				+ "app/rtc?action=hookinfo&account=" + acctid +"&" + authToken, authHeaders);
		Element result = Utils.parseXML(data);
		checkStatus(result);
		
		EndpointInfo info = new EndpointInfo();
		NodeList params = result.getElementsByTagName("param");
		
		for (int i=0; i < params.getLength(); i++) {
			Element p = (Element) params.item(i);
			String name = p.getAttribute("name");
			String value = p.hasChildNodes() ? p.getFirstChild().getNodeValue() : null;
			
			if ("registerHookEndpoint".equals(name))
				info.endpoint = value;
			else if ("registerHookToken".equals(name))
				info.token = value;
		}
		
		return info;
	}

	/**
	 * Register endpoint URL and "validation" token for archive repository
	 * 
	 * @param endpoint URL for archive repository
	 * @param token "validation" token to pass on callbacks
	 * @throws Exception
	 */
	public void registerRepository(String endpoint, String token) throws Exception {
		String acctid = this.roomInstance.split("/")[0];

		String data = "account=" + acctid + "&action=registerrepository";
		if (endpoint != null)
			data += "&endpoint=" + URLEncoder.encode(endpoint, "utf-8");
		if (token != null)
			data += "&token=" + URLEncoder.encode(token, "utf-8");
		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Register endpoint URL for archive repository
	 * 
	 * @param endpoint URL for archive repository
	 * @throws Exception
	 */
	public void registerRepository(String endpoint) throws Exception {
		 registerRepository(endpoint, null);
	}

	/**
	 * Unregister repository URL
	 * 
	 * @throws Exception
	 */
	public void unregisterRepository() throws Exception {
		registerRepository(null, null);
	}

	/**
	 * Returns the repository endpoint URL and security token for the account.
	 * 
	 * @return EndpointInfo
	 * @throws Exception
	 */
	public EndpointInfo getRepositoryInfo() throws Exception {
		String acctid = this.roomInstance.split("/")[0];
		InputStream data = Utils.http_get(baseURL 
				+ "app/rtc?action=repositoryinfo&account=" + acctid +"&" + authToken, authHeaders);
		Element result = Utils.parseXML(data);
		checkStatus(result);

		EndpointInfo info = new EndpointInfo();
		NodeList params = result.getElementsByTagName("param");

		for (int i=0; i < params.getLength(); i++) {
			Element p = (Element) params.item(i);
			String name = p.getAttribute("name");
			String value = p.hasChildNodes() ? p.getFirstChild().getNodeValue() : null;

			if ("repositoryEndpoint".equals(name))
				info.endpoint = value;
			else if ("repositoryToken".equals(name))
				info.token = value;
		}

		return info;
	}

	/**
	 * Starts recording a specified room.
	 * 
	 * @param room room name
	 * @throws Exception
	 */
	public void startRecording(String room) 
	throws Exception {
		startRecording(room, DEFAULT_ARCHIVE_ID, true);
	}
	
	/**
	 * Starts recording a specified room. 
	 * Optional parameter archiveId can be used to overwrite the default value of "__defaultArchive__".
	 * 
	 * @param room room name
	 * @param archiveId archive id
	 * @throws Exception
	 */
	public void startRecording(String room, String archiveId) 
	throws Exception {
		startRecording(room, archiveId, true);
	}
	
	/**
	 * Starts recording a specified room. 
	 * Optional parameter archiveId can be used to overwrite the default value of "__defaultArchive__".
	 * 
	 * @param room room name
	 * @param guestsAllowed guest recording playback access
	 * @throws Exception
	 */
	public void startRecording(String room, boolean guestsAllowed) 
	throws Exception {
		startRecording(room, DEFAULT_ARCHIVE_ID, guestsAllowed);
	}
	
	/**
	 * Starts recording a specified room. 
	 * Optional parameter archiveId can be used to overwrite the default value of "__defaultArchive__".
	 * Optional parameter guestsAllowed can be used to specify a guest access to this recording's playback.
	 * 
	 * @param room room name
	 * @param archiveId archive id
	 * @param guestsAllowed guest recording playback access, defaults to true
	 * @throws Exception
	 */
	public void startRecording(String room, String archiveId, boolean guestsAllowed) 
	throws Exception {
		if (archiveId == null
				|| archiveId.length() == 0)
		{
			archiveId = DEFAULT_ARCHIVE_ID;
		}
		
		//	item.body = {fullSession:true, archiveID:p_archiveID, guestsAllowed:p_guestsAllowed};
		Map<String, Object> map = new HashMap<String, Object>();
		map.put("fullSession", true);
		map.put("archiveID", archiveId);		
		map.put("guestsAllowed", guestsAllowed);
		
		// it's the full session
		MessageItem item = new MessageItem("roomState", map, "recordingState");
		publishItem(room, "RoomManager", "roomState", item);
	}
	
	/**
	 * Stops a recording.
	 * 
	 * @param room room name
	 * @throws Exception
	 */
	public void stopRecording(String room) 
	throws Exception {
		retractItem(room, "RoomManager", "roomState", "recordingState");
	}
	
	/**
	 * Subscribe to collection event
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @throws Exception
	 */
	public void subscribeCollection(String room, String collectionName) throws Exception {
		subscribeCollection(room, collectionName, null);
	}

	protected void subscribeCollection(String room, String collection, String nodeNames[]) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String data = "instance=" + instance + "&action=subscribe" + "&collection=" + collection;

		if (nodeNames != null) {
			for (String node : nodeNames)
				data += "&node=" + node;
		}

		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Unsubscribe from collection events (and stop notifications)
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @throws Exception
	 */
	public void unsubscribeCollection(String room, String collectionName) throws Exception {
		unsubscribeCollection(room, collectionName, null);
	}

	protected void unsubscribeCollection(String room, String collection, String nodeNames[]) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String data = "instance=" + instance + "&action=unsubscribe" + "&collection=" + collection;

		if (nodeNames != null) {
			for (String node : nodeNames)
				data += "&node=" + node;
		}

		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Publish an item
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param itemVO item VO (as returned from LCDS)
	 * @throws Exception
	 */
	public void publishItem(String room, String collectionName, String nodeName, Map<String, Object> itemVO) throws Exception
	{
		publishItem(room, collectionName, nodeName, new MessageItem(itemVO), false);
	}

	/**
	 * Publish an item
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param itemVO item VO (as returned from LCDS)
	 * @param overwrite overwrite or create
	 * @throws Exception
	 */
	public void publishItem(String room, String collectionName, String nodeName, Map<String, Object> itemVO, boolean overwrite)
	throws Exception {
		publishItem(room, collectionName, nodeName, new MessageItem(itemVO), overwrite);
	}

	/**
	 * Publish an item
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param item MessageItem to publish
	 * @throws Exception
	 * @see MessageItem
	 */
	public void publishItem(String room, String collectionName, String nodeName, MessageItem item) throws Exception
	{
		publishItem(room, collectionName, nodeName, item, false);
	}
	
	/**
	 * Publish an item
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param item MessageItem to publish
	 * @param overwrite overwrite or create
	 * @throws Exception
	 * @see MessageItem
	 */
	public void publishItem(String room, String collectionName, String nodeName, MessageItem item, boolean overwrite)
	throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);

		Map<String, String> headers = new HashMap<String, String>(authHeaders);
		headers.put("Content-Type", "text/xml");

		String params = "instance=" + instance + "&action=publish&collection=" + collectionName + "&node=" + nodeName;
		if (overwrite)
			params += "&overwrite=true";

		params += "&" + authToken;

		String data = "<request>" + item.toXML() + "</request>";
		InputStream res = Utils.http_post(baseURL + "app/rtc?" + params, data, headers);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Retract an item
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param itemID item ID
	 * @throws Exception
	 */
	public void retractItem(String room, String collectionName, String nodeName, String itemID) throws Exception
	{
		String instance = this.roomInstance.replaceAll("#room#", room);
		String data = "instance=" + instance 
		+ "&collection=" + collectionName + "&node=" + nodeName + "&item=" + itemID + "&" + authToken;
		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Create a node or collection
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @throws Exception
	 */
	public void createNode(String room, String collectionName, String nodeName) throws Exception
	{
		createNode(room, collectionName, nodeName, (NodeConfiguration)null);
	}

	/**
	 * Create a node with specified node configuration
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param configurationVO configuration VO (as returned from LCDS)
	 * @throws Exception
	 */
	public void createNode(String room, String collectionName, String nodeName, Map<String, Object> configurationVO) throws Exception
	{
		NodeConfiguration configuration = configurationVO==null ? null : new NodeConfiguration(configurationVO);
		createNode(room, collectionName, nodeName, configuration);
	}

	/**
	 * Create a node with specified node configuration
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param configuration NodeConfiguration
	 * @throws Exception
	 * @see NodeConfiguration
	 */
	public void createNode(String room, String collectionName, String nodeName, NodeConfiguration configuration)
	throws Exception
	{
		String instance = this.roomInstance.replaceAll("#room#", room);
		String params = "instance=" + instance + "&action=configure"
		+ "&collection=" + collectionName + "&node=" + nodeName + "&" + authToken;

		InputStream res;

		if (configuration != null) {
			Map<String, String> headers = new HashMap<String, String>(authHeaders);
			headers.put("Content-Type", "text/xml");

			String data = "<request>" + configuration.toXML() + "</request>";
			res = Utils.http_post(baseURL + "app/rtc?" + params, data, headers);
		} else {
			res = Utils.http_post(baseURL + "app/rtc", params, authHeaders);
		}

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Remove a collection
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @throws Exception
	 */
	public void removeNode(String room, String collectionName) throws Exception {
		removeNode(room, collectionName, null);
	}

	/**
	 * Remove a node
	 * 
	 * @param room room name 
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @throws Exception
	 */
	public void removeNode(String room, String collectionName, String nodeName) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String data = "instance=" + instance + "&action=remove"
		+ "&collection=" + collectionName;

		if (nodeName != null)
			data += "&node=" + nodeName;

		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Configure a node
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param configuration configuration VO (as returned from LCDS)
	 * @throws Exception
	 */
	public void setNodeConfiguration(String room, String collectionName, String nodeName, Map<String, Object> configuration)
	throws Exception
	{
		setNodeConfiguration(room, collectionName, nodeName, new NodeConfiguration(configuration));
	}

	/**
	 * Configure a node
	 * 
	 * @param room room name
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @param configuration NodeConfiguration
	 * @throws Exception
	 * @see NodeConfiguration
	 */
	public void setNodeConfiguration(String room, String collectionName, String nodeName, NodeConfiguration configuration)
	throws Exception
	{
		String instance = this.roomInstance.replaceAll("#room#", room);
		String params = "instance=" + instance + "&action=configure"
		+ "&collection=" + collectionName + "&node=" + nodeName + "&" + authToken;

		Map<String, String> headers = new HashMap<String, String>(authHeaders);
		headers.put("Content-Type", "text/xml");

		String data = "<request>" + configuration.toXML() + "</request>";
		InputStream res = Utils.http_post(baseURL + "app/rtc?" + params, data, headers);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Set user role
	 * 
	 * @param room room name
	 * @param userID user ID
	 * @param role role value
	 * @throws Exception
	 * @see UserRoles
	 */
	public void setUserRole(String room, String userID, int role) throws Exception {
		setUserRole(room, userID, role, null, null);
	}

	/**
	 * Set user role for the specified collection
	 * 
	 * @param room room name
	 * @param userID user ID
	 * @param role role value
	 * @param collectionName collection name
	 * @throws Exception
	 * @see UserRoles
	 */
	public void setUserRole(String room, String userID, int role, String collectionName) throws Exception {
		setUserRole(room, userID, role, collectionName, null);
	}

	/**
	 * Set user role for the specified node
	 * 
	 * @param room room name
	 * @param userID user ID
	 * @param role role value
	 * @param collectionName collection name
	 * @param nodeName node name
	 * @throws Exception
	 * @see UserRoles
	 */
	public void setUserRole(String room, String userID, int role, String collectionName, String nodeName) throws Exception {
		String instance = this.roomInstance.replaceAll("#room#", room);
		String data = "instance=" + instance + "&action=setrole&user=" + userID + "&role=" + role;

		if (collectionName != null)
			data += "&collection=" + collectionName;
		if (nodeName != null)
			data += "&node=" + nodeName;

		data += "&" + authToken;

		InputStream res = Utils.http_post(baseURL + "app/rtc", data, authHeaders);

		Element result = Utils.parseXML(res);
		checkStatus(result);
	}

	/**
	 * Return account information, if active
	 * 
	 * @return account info as XML string
	 * @throws Exception
	 */
	public AccountInfo getAccountInfo() throws Exception {
		String acctid = this.roomInstance.split("/")[0];
		InputStream data = Utils.http_get(baseURL + "app/account?account=" + acctid + "&" + authToken, authHeaders);
		Element result = Utils.parseXML(data);
		checkStatus(result);	
		
		AccountInfo info = new AccountInfo();
		
		info.userCount = Utils.getElementValueLong(result, "user-count");
		info.peakUsers = Utils.getElementValueLong(result, "peak-user-count");
		info.bytesUp = Utils.getElementValueLong(result, "total-bytes-up");
		info.bytesDown = Utils.getElementValueLong(result, "total-bytes-down");
		info.messages = Utils.getElementValueLong(result, "total-messages");
		info.userTime = Utils.getElementValueLong(result, "total-time");
		info.dateCreated = Utils.getElementValueDate(result, "date-created");
		info.dateExpired = Utils.getElementValueDate(result, "date-expired");

		String activeRooms = Utils.getElementValue(result, "active-FMS-instances");
		if (activeRooms != null && activeRooms.length() > 2) // [account/room1,account/room2,...]
			info.activeRooms = activeRooms.substring(1,activeRooms.length()-1)
				.replaceAll(acctid+"/", "").split(",");
		else
			info.activeRooms = new String[0];

		return info;
	}

	/**
	 * Return room information, if active
	 * 
	 * @param room room name
	 * @return room info as XML string
	 * @throws Exception
	 */
	public RoomInfo getRoomInfo(String room) throws Exception {
		String instance = room;

		if (room.indexOf("/") < 0)
			instance = this.roomInstance.replaceAll("#room#", room);

		InputStream data = Utils.http_get(baseURL + "app/account?instance=" + instance + "&" + authToken, authHeaders);
		Element result = Utils.parseXML(data);
		checkStatus(result);
		
		RoomInfo info = new RoomInfo();
		
		info.userCount = Utils.getElementValueLong(result, "user-count");
		info.peakUsers = Utils.getElementValueLong(result, "peak-users");
		info.bytesUp = Utils.getElementValueLong(result, "total-bytes-up");
		info.bytesDown = Utils.getElementValueLong(result, "total-bytes-down");
		info.messages = Utils.getElementValueLong(result, "total-messages");
		info.dateCreated = Utils.getElementValueDate(result, "date-created");
		info.dateStarted = Utils.getElementValueDate(result, "date-started");
		info.dateEnded = Utils.getElementValueDate(result, "date-ended");
		info.dateExpired = Utils.getElementValueDate(result, "date-expired");

		return info;
	}

	private boolean do_initialize() throws Exception {

		if (contentPath != null)
			return true;

		InputStream data = Utils.http_get(url + "?mode=xml&accountonly=true&" + authToken, authHeaders);

		Element result = Utils.parseXML(data);
		if (result == null)
			throw new RTCError("bad-response");

		if (Utils.DEBUG)
			System.out.println(Utils.printXML(result));

		if (result.getTagName().equals("meeting-info")) {
			Element baseURL = (Element) result.getElementsByTagName("baseURL").item(0);
			this.baseURL = baseURL.getAttribute("href");
			url = this.baseURL + new URL(url).getPath().substring(1);
			Element accountPath = (Element) result.getElementsByTagName("accountPath").item(0);
			contentPath = accountPath.getAttribute("href");
			NodeList room = result.getElementsByTagName("room");
			if (room != null) {
				this.roomInstance = ((Element) room.item(0)).getAttribute("instance");
			}

			return true;
		}

		if (result.getTagName().equals("result")) {
			if (result.getAttribute("code").equals("unauthorized")) {
				NodeList baseURL = result.getElementsByTagName("baseURL");
				if (baseURL != null) {
					this.baseURL = ((Element) baseURL.item(0)).getAttribute("href");
					url = this.baseURL + new URL(url).getPath().substring(1);
				}
				Element authentication = (Element) result.getElementsByTagName("authentication").item(0);
				String authURL = authentication.getAttribute("href");
				if (authURL.charAt(0) == '/')
					authURL = this.baseURL + authURL;
				authenticator = new Authenticator(authURL);
				return false;
			}
		}

		throw new RTCError(Utils.printXML(result));
	}
	
	private void checkStatus(Element result) throws Exception {
		if (result == null)
			throw new RTCError("bad-response");

		if (Utils.DEBUG)
			System.out.println(Utils.printXML(result));
		
		Element status = (Element) result.getElementsByTagName("status").item(0);
		String code = status.getAttribute("code");
		if (!"ok".equals(code)) {
			if (status.getAttribute("subcode") != null)
				code = status.getAttribute("subcode");
			throw new RTCError(code);
		}
	}
}
