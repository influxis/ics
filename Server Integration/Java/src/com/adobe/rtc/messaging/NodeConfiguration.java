package com.adobe.rtc.messaging;

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

import java.util.HashMap;
import java.util.Map;

/**
 * NodeConfiguration is a "descriptor" for describing the properties of a node's configuration. 
 * <p>
 * See Example 129 of XEP-60's pubsub functionality. <a href="http://www.xmpp.org/extensions/xep-0060.html#owner-configure">http://www.xmpp.org/extensions/xep-0060.html</a><br>
 * This class describes the subset of and additions to the set of configuration options supported in CoCoMo. 
 * <p>
 * Within each CollectionNode is a series of one or more nodes. A node is a channel through which 
 * to send and receive MessageItems. Nodes are also configured according to rules concerning what 
 * UserRoles may publish and subscribe MessageItems through them, as well as other policies 
 * concering message storage and privacy. NodeConfigurations are used to set these policies.
 * <p>
 * For more information, refer to the Developer Guide's "Messaging and Permissions" chapter.
 * 
 * @see com.adobe.rtc.sharedModel.CollectionNode
 * @see com.adobe.rtc.messaging.MessageItem
 * @see com.adobe.rtc.messaging.UserRoles
 */
public class NodeConfiguration //implements IValueObjectEncodable
{ 
	/**
	 * The storage scheme if a node is to only store and update one MessageItem. 
	 * The item will be given the <code>itemID</code> "item" by default. 
	 */
	final public static int STORAGE_SCHEME_SINGLE_ITEM = 0;

	/**
	 * The storage scheme to enable storage of a queue of MessageItems. 
	 * Items will have their <code>itemIDs</code> start at 0 and continue to auto-increment. 
	 */
	final public static int STORAGE_SCHEME_QUEUE = 1;

	/**
	 * The storage scheme to enable manual management of <code>itemIDs</code> for each MessageItem. 
	 * It allows the node to behave as if it were a hash table. 
	 */
	final public static int STORAGE_SCHEME_MANUAL = 2;

	private Map<String, Object> configuration = new HashMap<String, Object>();
	
	/**
	 * Constructor to create a default NodeConfiguration
	 */
	public NodeConfiguration()
	{
		this(10, 50, true, true, false, false, STORAGE_SCHEME_SINGLE_ITEM, false, false, false);
	}

	public NodeConfiguration(int p_accessModel, int p_publishModel)
	{
		this(p_accessModel, p_publishModel, true, true, false, false, STORAGE_SCHEME_SINGLE_ITEM, false, false, false);
	}
	
	public NodeConfiguration(int p_accessModel,
			 int p_publishModel,
			 boolean p_persistItems, 
			 boolean p_modifyAnyItem, 
			 boolean p_userDependentItems, 
			 boolean p_sessionDependentItems)
	{
		this(p_accessModel, p_publishModel, p_persistItems, p_modifyAnyItem, p_userDependentItems, p_sessionDependentItems, 
			STORAGE_SCHEME_SINGLE_ITEM, false, false, false);
	}
	
	public NodeConfiguration(int p_accessModel,
			 int p_publishModel,
			 boolean p_persistItems, 
			 boolean p_modifyAnyItem, 
			 boolean p_userDependentItems, 
			 boolean p_sessionDependentItems,
			 int p_storageScheme)
	{
		this(p_accessModel, p_publishModel, p_persistItems, p_modifyAnyItem, p_userDependentItems, p_sessionDependentItems, 
			p_storageScheme, false, false, false);
	}
	
	public NodeConfiguration(int p_accessModel,
			 int p_publishModel,
			 boolean p_persistItems, 
			 boolean p_modifyAnyItem, 
			 boolean p_userDependentItems, 
			 boolean p_sessionDependentItems,
			 int p_storageScheme,
			 boolean p_allowPrivateMessages)
	{
		this(p_accessModel, p_publishModel, p_persistItems, p_modifyAnyItem, p_userDependentItems, p_sessionDependentItems, 
			p_storageScheme, p_allowPrivateMessages, false, false);
	}
	
	public NodeConfiguration(int p_accessModel,
			 int p_publishModel,
			 boolean p_persistItems, 
			 boolean p_modifyAnyItem, 
			 boolean p_userDependentItems, 
			 boolean p_sessionDependentItems,
			 int p_storageScheme,
			 boolean p_allowPrivateMessages,
			 boolean p_lazySubscription)
	{
		this(p_accessModel, p_publishModel, p_persistItems, p_modifyAnyItem, p_userDependentItems, p_sessionDependentItems, 
			p_storageScheme, p_allowPrivateMessages, p_lazySubscription, false);
	}
	
	public NodeConfiguration(int p_accessModel,
				 int p_publishModel,
				 boolean p_persistItems, 
				 boolean p_modifyAnyItem, 
				 boolean p_userDependentItems, 
				 boolean p_sessionDependentItems,
				 int p_storageScheme,
				 boolean p_allowPrivateMessages,
				 boolean p_lazySubscription,
				 boolean p_p2pDataMessaging)
	{
		setAccessModel(p_accessModel);
		setPublishModel(p_publishModel);
		setPersistItems(p_persistItems);
		setModifyAnyItem(p_modifyAnyItem);
		setUserDependentItems(p_userDependentItems);
		setSessionDependentItems(p_sessionDependentItems);
		setItemStorageScheme(p_storageScheme);
		setAllowPrivateMessages(p_allowPrivateMessages);
		setLazySubscription(p_lazySubscription);
		setP2pDataMessaging(p_p2pDataMessaging);
	}

	/**
	 * Creates a NodeConfiguration object from a VO
	 * (as received from the LCCS server)
	 */
	public NodeConfiguration(Map<String, Object> vo) {
		configuration = new HashMap<String, Object>(vo);
	}

	/**
	 * The minimum role value required to subscribe to the node and receive MessageItems. 
	 *  
	 * @see com.adobe.rtc.messaging.UserRoles
	 */
	public int getAccessModel() {
		if (configuration.containsKey("accessModel"))
			return (Integer) configuration.get("accessModel");
		else
			return 10;
	}

	public void setAccessModel(int p_accessModel) {
		configuration.put("accessModel", p_accessModel);
	}

	/**
	 * The minimum role value required to publish MessageItems to the node.
	 * @see com.adobe.rtc.messaging.UserRoles
	 */
	public int getPublishModel() {
		if (configuration.containsKey("publishModel"))
			return (Integer) configuration.get("publishModel");
		else
			return 50;
	}
			
	public void setPublishModel(int p_publishModel) {
		configuration.put("publishModel", p_publishModel);
	}

	/**
	 * Whether or not MessageItems should be stored and forwarded to users arriving later (true) 
	 * or not stored at all (false). 
	 * <p>
	 * default true
	 */
	public boolean getPersistItems() {
		if (configuration.containsKey("persistItems"))
			return (Boolean) configuration.get("persistItems");
		else
			return true;
	}

	public void setPersistItems(boolean p_persistItems) {
		configuration.put("persistItems", Boolean.valueOf(p_persistItems));
	}

	/**
	 * Whether or not publishers may modify other users' stored items on the node (true) or only 
	 * MessageItems they have published (false).
	 * <p>
	 * default true
	 */
	public boolean getModifyAnyItem() {
		if (configuration.containsKey("modifyAnyItems"))
			return (Boolean) configuration.get("modifyAnyItems");
		else
			return true;
	}

	public void setModifyAnyItem(boolean p_modifyAnyItem) {
		configuration.put("modifyAnyItem", Boolean.valueOf(p_modifyAnyItem));
	}

	/**
	 * Whether or not stored MessageItems should be retracted from the server when their sender 
	 * leaves the room (true) or left until manually retracted (false).
	 * <p>
	 * default false
	 */
	public boolean getUserDependentItems() {
		if (configuration.containsKey("userDependentItems"))
			return (Boolean) configuration.get("userDependentItems");
		else
			return false;
	}

	public void setUserDependentItems(boolean p_userDependentItems) {
		configuration.put("userDependentItems", Boolean.valueOf(p_userDependentItems));
	}

	/**
	 * Whether or not stored MessageItems should be retracted from the server when meeting session 
	 * ends (true) or left until manually retracted (false).
	 * <p>
	 * default false
	 */
	public boolean getSessionDependentItems() {
		if (configuration.containsKey("sessionDependentItems"))
			return (Boolean) configuration.get("sessionDependentItems");
		else
			return false;
	}

	public void setSessionDependentItems(boolean p_sessionDependentItems) {
		configuration.put("sessionDependentItems", Boolean.valueOf(p_sessionDependentItems));
	}
	
	/**
	 * Storage scheme for the MessageItems sent over this node. It is one of the STORAGE_SCHEME constants listed.
	 *
	 */
	public int getItemStorageScheme() {
		if (configuration.containsKey("itemStorageScheme"))
			return (Integer) configuration.get("itemStorageScheme");
		else
			return STORAGE_SCHEME_SINGLE_ITEM;
	}

	public void setItemStorageScheme(int p_storageScheme) {
		configuration.put("itemStorageScheme", p_storageScheme);
	}
	
	/**
	 * Whether or not private messages are allowed.
	 * <p>
	 * default false
	 */
	public boolean getAllowPrivateMessages() {
		if (configuration.containsKey("allowPrivateMessages"))
			return (Boolean) configuration.get("allowPrivateMessages");
		else
			return false;
	}

	public void setAllowPrivateMessages(boolean p_allowPrivateMessages) {
		configuration.put("allowPrivateMessages", Boolean.valueOf(p_allowPrivateMessages));
	}

	/**
	 * Whether or not the subscription to this node is "lazy" - that is, it doesn't receive items automatically.
	 * For fetching items from a node with <code>lazySubscription</code>, use <code>collectionNode.fetchItems()</code>
	 * <p>
	 * default false
	 */
	public boolean getLazySubscription() {
		if (configuration.containsKey("lazySubscription"))
			return (Boolean) configuration.get("lazySubscription");
		else
			return false;
	}

	public void setLazySubscription(boolean p_lazySubscription) {
		configuration.put("lazySubscription", Boolean.valueOf(p_lazySubscription));
	}
	
	/**
	 * This collection will try to use p2p data messaging
	 */
	public boolean getP2pDataMessaging() {
		if (configuration.containsKey("p2pDataMessaging"))
			return (Boolean) configuration.get("p2pDataMessaging");
		else
			return false;
	}

	public void setP2pDataMessaging(boolean p_p2pDataMessaging) {
		configuration.put("p2pDataMessaging", Boolean.valueOf(p_p2pDataMessaging));
	}
	
	/**
	 * @return String representation of this object as String
	 */
	public String toString()
	{
		return configuration.toString();
	}

	/**
	 * @return String representation of this object as XML
	 */
	public String toXML()
	{
		RTCModel.Node node = new RTCModel.Node("");
		node.addConfiguration(configuration);

		StringBuilder sb = new StringBuilder();
		node.getConfigurationXML(sb);

		return sb.toString();
	}
}
