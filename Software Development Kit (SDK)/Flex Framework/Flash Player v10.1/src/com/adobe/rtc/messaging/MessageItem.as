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
package com.adobe.rtc.messaging
{
	import flash.utils.IExternalizable;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;

	/**
	 * MessageItem is a "descriptor" for the properties of messages sent, received, and stored by a CollectionNode.
	 * 
	 * See Example 86 of XEP-60's pubsub functionality. <a href="http://www.xmpp.org/extensions/xep-0060.html#publisher-publish">http://www.xmpp.org/extensions/xep-0060.html</a><br>
	 * 
	 * @see Docs, "LCCS Messaging and Permissions" in the docs
	 * @see com.adobe.rtc.messaging.NodeConfiguration
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */	
	
   public class  MessageItem implements IValueObjectEncodable
	{	
		
		/**
		 * registerBodyClass allows the LCCS services to send fully-typed objects in the body of MessageItems. 
		 * Similar to flash.net.registerClassAlias, this causes any message body of this type to be encoded as a ByteArray. Upon receipt,
		 * the body will be deserialized as a fully-typed object. Note that if your class contains other typed object as properties, those classes
		 * will need to be registered as well.
		 * @param p_class The class to register as a body.
		 * 
		 */
		public static function registerBodyClass(p_class:Class):void
		{
			var className:String = flash.utils.getQualifiedClassName(p_class);
			if (registeredClasses[className]!=true) {
				flash.net.registerClassAlias(className, p_class);
				registeredClasses[className] = true;
			}
		}
		
		/**
		 * If STORAGE_SCHEME_SINGLE_ITEM is used for a <code>nodeConfiguration</code>, this is the default <code>itemID</code> used. 
		 * The value may be overriden in your items.
		 */
		public static const SINGLE_ITEM_ID:String = "item";
		
		/**
		 * The name of the Node within a CollectionNode that this item belongs to.
		 * */
		public var nodeName:String;

		/**
		 * The ID for this stored item. Note this must be unique within the node. 
		 * Publishing an item with an existing <code>itemID</code> will overwrite the existing item.
		 * */
		public var itemID:String;

		/**
		 * Value actually being sent within this message.
		 * */
		public var body:*;


		/**
		 * [Read-only] <code>userID</code> of the user who published this item. Depending on <code>nodeConfigurations</code> 
		 * for this message, publishers may not be able to modify stored items they didn't publish 
		 * themselves. Note that this variable is overwritten by the server to prevent spoofing.
		 * */
		public var publisherID:String;
		
		/**
		 * For <code>nodeConfigurations</code> with <code>userDependentItems=true</code> or 
		 * <code class="property">modifyAnyItem=false</code>, this property is used to determine the user associated 
		 * with this item. This is typically the <code class="property">publisherID</code> of the first <code>userID</code> 
		 * to publish the item. Note that owners may also publish items associated with other users.
		 * <code class="property">associatedUserID</code> almost never needs to be explicitly set.
		 * */
		public var associatedUserID:String;
		
		/**
		* For nodes where <code>allowPrivateMessages</code> has been set to true, this field allows 
		* messages to be received by only *one* recipient. Note that for cases where groups of people 
		* are recipients, you should use <code>recipientIDs</code> We do want to avoid the one-to-one private message case devolving 
		* to "one node per user," so recipientID allows this in a much simpler manner.
		*/		
		public var recipientID:String;
		
		/**
		* For nodes where <code>allowPrivateMessages</code> has been set to true, this field allows 
		* messages to be received by multiple recipients. Note that recipients will not receive the entire recipientIDs array,
		* only their own <code>recipientID</code>.
		*/		
		public var recipientIDs:Array;

		/**
		 * [Read-only] The time this message was broadcast and written on the server. 
		 * */
		public var timeStamp:Number = -1;
		
		/**
		 * [Read-only] The name of the CollectionNode this item belongs to. 
		 * */
		public var collectionName:String;

		/**
		 * @private 
		 */
		protected static var registeredClasses:Dictionary = new Dictionary();

		public function MessageItem(p_nodeName:String=null, p_body:*=null, p_itemID:String=null)
		{
			if (p_nodeName!=null){
				nodeName=p_nodeName;
			}
			if (p_body!=null) {
				body = p_body;
			}
			if (p_itemID!=null) {
				itemID = p_itemID;
			}
		}
			
		/**
		 * Takes in a <code>valueObject</code> and structure the MessageItem according to the values therein.
		 * 
		 * @param p_valueObject An Object which represents the non-default values for this MessageItem.
		 */
		public function readValueObject(p_valueObject:Object):void
		{
			if (p_valueObject["timeStampOrder"]!=null) {
				delete p_valueObject["timeStampOrder"];
			}
			for (var i:* in p_valueObject) {
				this[i] = p_valueObject[i];
			}
			if (body is ByteArray) {
			// it might be a serialized typed object
				var success:Boolean = true;
				try {
					// see if we can deserialize it to a typed object
					var newBody:Object = ByteArray(body).readObject();
				} catch (e:Error) {
					success = false;
				}
				if (success && registeredClasses[flash.utils.getQualifiedClassName(newBody)]) {
					// if we registered this type as a messageItem body, use it
					body = newBody;
				}
			}
			if (associatedUserID==null) {
				associatedUserID = publisherID;
			}
		}
		
		/**
		 * Creates a ValueObject representation of this MessageItem.
		 * 
		 * @return An Object which represents the non-default values for this MessageItem, 
		 * suitable for consumption by <code>readValueObject</code>.
		 */	
		public function createValueObject():Object
		{
			var writeObj:Object = new Object();
			if (nodeName!=null) {
				writeObj.nodeName = nodeName;
			}
			if (itemID!=null) {
				writeObj.itemID = itemID;
			}
			if (body!=null) {
				if (registeredClasses[flash.utils.getQualifiedClassName(body)]) {
					var bA:ByteArray = new ByteArray();
					bA.writeObject(body);
					bA.position = 0 ;
					writeObj.body = bA;
				} else {
					writeObj.body = body;
				}
			}
			if (publisherID!=null) {
				writeObj.publisherID = publisherID;
			}
			if (associatedUserID!=null && associatedUserID!=publisherID) {
				writeObj.associatedUserID = associatedUserID;
			}
			if (recipientID!=null) {
				writeObj.recipientID = recipientID;
			}
			if (recipientIDs!=null) {
				writeObj.recipientIDs = recipientIDs;
			}
			if (timeStamp != -1) {
				writeObj.timeStamp = timeStamp;
			}
			
			return writeObj;
		}
		
	}
}
