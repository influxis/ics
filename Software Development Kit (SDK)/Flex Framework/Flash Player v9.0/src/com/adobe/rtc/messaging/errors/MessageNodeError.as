/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright [2007-2010] Adobe Systems Incorporated
* All Rights Reserved.
*
* NOTICE:  All information contained herein is, and remains
* the property of Adobe Systems Incorporated and its suppliers,
* if any.  The intellectual and technical concepts contained
* herein are proprietary to Adobe Systems Incorporated and its
* suppliers and are protected by trade secret or copyright law.
* Dissemination of this information or reproduction of this material
* is strictly forbidden unless prior written permission is obtained
* from Adobe Systems Incorporated.
*/
package com.adobe.rtc.messaging.errors
{
	/**
	 * MessageNodeError is an Error class containing the constants for various messaging error descriptions.
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  MessageNodeError extends Error
	{
		public static const NODE_NOT_SYNCHRONIZED:String = "The node is not synchronized. Make sure you've subscribed."; 

		public static const CANNOT_CHANGE_COLLECTIONNAME:String = "You cannot change the name of a MessageNodeCollection."; 
		public static const NO_SUCH_NODE:String = "Could not find the requested node."; 
		public static const NODE_ALREADY_CREATED:String = "This node was already created in this collection.";
		public static const COLLECTION_ALREADY_CREATED:String = "This collection already exists.";
		
		public static const DO_NOT_PASS_ID:String = "The itemStorageScheme for this node is STORAGE_SCHEME_SINGLE_ITEM; therefore, you cannot pass an itemID other than MessageItem.SINGLE_ITEM_ID. In fact, you shouldn't pass an itemID at all! Do you want to use STORAGE_SCHEME_MANUAL instead?";
		public static const INVALID_ID:String = "The itemStorageScheme for this node is STORAGE_SCHEME_SINGLE_MANUAL. You must pass an itemID.";
		public static const CANNOT_CREATE_NODE:String = "You are trying to publish to a node that doesn't exist and you are not an owner.";
		
		public static const ASSOCIATEDUSERID_MUST_BE_CONNECTED:String = "The associatedUserID must be connected.";
		
		public function MessageNodeError(p_message:String)
		{
			super(p_message);
		}
	}
}
