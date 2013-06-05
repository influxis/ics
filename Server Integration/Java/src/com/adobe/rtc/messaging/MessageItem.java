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

import java.util.*;

/**
 * MessageItem
 */
public class MessageItem 
{
	/**
	 * if you use STORAGE_SCHEME_SINGLE_ITEM in your node configuration, we'll use this as the item name (unless you pass one yourself, in which case we'll respect your itemID)
	 */
	public final static String SINGLE_ITEM_ID = "item";
	
	private Map<String, Object> item = new HashMap<String, Object>();

	public MessageItem()
	{
		this(null, null, null);
	}

	public MessageItem(String p_nodeName)
	{
		this(p_nodeName, null, null);
	}

	public MessageItem(String p_nodeName, Object p_body)
	{
		this(p_nodeName, p_body, null);
	}

	public MessageItem(String p_nodeName, Object p_body, String p_itemID)
	{
		if (p_nodeName!=null){
			setNodeName(p_nodeName);
		}
		if (p_body!=null) {
			setBody(p_body);
		}
		if (p_itemID!=null) {
			setItemID(p_itemID);
		}
	}
	
	public MessageItem(Map<String, Object> vo)
	{
		item = vo;
	}

	/**
	 * Name of the Node this item belongs to 
	 * */
	public String getNodeName()
	{
		return (String) item.get("nodeName");
	}

	public void setNodeName(String p_nodeName)
	{
		item.put("nodeName", p_nodeName);
	}

	/**
	 * ID for this stored item. Note this must be unique within the node. Publishing an item with an existing itemID will overwrite the existing item.
	 * */
	public String getItemID()
	{
		return (String) item.get("itemID");
	}

	public void setItemID(String p_itemID)
	{
		item.put("itemID", p_itemID);
	}

	/**
	 * Value actually being sent within this message.
	 * */
	public Object getBody()
	{
		return item.get("body");
	}

	public void setBody(Object p_body)
	{
		item.put("body", p_body);
	}


	/**
	 * [read-only] userID of the user who published this item. Depending on nodeConfigurations for this message, publishers may not be able 
	 * to modify stored items they didn't publish themselves. Note : overwritten by the server, to prevent spoofing.
	 * */
	public String getPublisherID()
	{
		return (String) item.get("publisherID");
	}
	
	public void setPublisherID(String p_publisherID)
	{
		item.put("publisherID", p_publisherID);
	}

	/**
	 * For nodeConfigurations with userDependentItems=true or modifyAnyItem=false, this property is used to determine the user associated 
	 * with this item. This is typically the publisherID of the first userID to publish the item (owners may also publish items associated with other users), and 
	 * almost never needs setting.
	 * */
	public String getAssociatedUserID()
	{
		return (String) item.get("associatedUserID");
	}
	
	public void setAssociatedUserID(String p_associatedUserID)
	{
		item.put("associatedUserID", p_associatedUserID);
	}
	
	/**
	 * For nodes where allowPrivateMessages has been set to true, this field allows messages to be received by only *one* recipient. 
	 * Note that for cases where groups of people are recipients, specialized nodes where those recipients have been promoted to 
	 * be able to subscribe should be used. We do want to avoid the one-to-one private message case devolving to "one node per user",
	 * so recipientID allows this in a much simpler manner.
	 */		
	public String getRecipientID()
	{
		return (String) item.get("recipientID");
	}
	
	public void setRecipientID(String p_recipientID)
	{
		item.put("recipientID", p_recipientID);
	}

	/**
	 * [read-only] Time this message was broadcast (written on the server)
	 * */
	public int getTimeStamp()
	{
		if (item.containsKey("timeStamp"))
			return (Integer) item.get("timeStamp");
		else
			return -1;
	}
	
	public void setTimeStamp(int p_timeStamp)
	{
		item.put("timeStamp", p_timeStamp);
	}

	/**
	 * [read-only] Name of the CollectionNode this item belongs to 
	 * */
	public String getCollectionName()
	{
		return (String) item.get("collectionName");
	}
	
	public void setCollectionName(String p_collectionName)
	{
		item.put("collectionName", p_collectionName);
	}

	
	/**
	* For nodes where <code>allowPrivateMessages</code> has been set to true, this field allows 
	* messages to be received by multiple recipients. Note that recipients will not receive the entire recipientIDs array,
	* only their own <code>recipientID</code>.
	*/		
		@SuppressWarnings("unchecked")
	public List<String> getRecipientIDs()
	{
		return (List<String>) item.get("recipientIDs");
	}

	public void setRecipientIDs(List<String> p_recipientIDs)
	{
		item.put("recipientIDs", p_recipientIDs);
	}

	/**
	 * @return String representation of this object as String
	 */
	public String toString()
	{
		return item.toString();
	}

	/**
	 * @return String representation of this object as XML
	 */
	public String toXML()
	{
		RTCModel.Item rtcItem = new RTCModel.Item(item);

		StringBuilder sb = new StringBuilder();
		rtcItem.toXML(sb, null);

		return sb.toString();
	}
}

