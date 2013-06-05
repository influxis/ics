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
	
	/**
	 * NodeConfiguration is a "descriptor" for describing the properties of a node's configuration. 
	 * 
	 * See Example 129 of XEP-60's pubsub functionality. <a href="http://www.xmpp.org/extensions/xep-0060.html#owner-configure">http://www.xmpp.org/extensions/xep-0060.html</a><br>
	 * This class describes the subset of and additions to the set of configuration options supported in LCCS. 
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
	
   public class  NodeConfiguration implements IValueObjectEncodable
	{ 

		/**
		 * The storage scheme if a node is to only store and update one MessageItem. 
		 * The item will be given the <code>itemID</code> "item" by default. 
		 * */
		public static const STORAGE_SCHEME_SINGLE_ITEM:uint = 0;

		/**
		 * The storage scheme to enable storage of a queue of MessageItems. 
		 * Items will have their <code>itemIDs</code> start at 0 and continue to auto-increment. 
		 * */
		public static const STORAGE_SCHEME_QUEUE:uint = 1;

		/**
		 * The storage scheme to enable manual management of <code>itemIDs</code> for each MessageItem. 
		 * It allows the node to behave as if it were a hash table. 
		 * */
		public static const STORAGE_SCHEME_MANUAL:uint = 2;

		
		/**
		 * A constant for storing the default configuration of a node.
		 */
		public static const DEFAULT_CONFIGURATION:NodeConfiguration = new NodeConfiguration();
		
		/**
		 * The minimum role value required to subscribe to the node and receive MessageItems. 
		 *  
		 * @see com.adobe.rtc.messaging.UserRoles
		 * */
		public var accessModel:int; // one of the above constants

		/**
		 * The minimum role value required to publish MessageItems to the node.
		 * @see com.adobe.rtc.messaging.UserRoles
		 * */
		public var publishModel:int; // one of the above constants
				
		/**
		 * Whether or not MessageItems should be stored and forwarded to users arriving later (true) 
		 * or not stored at all (false). 
        * 
        * @default true
		 * 
        */
		public var persistItems:Boolean;

		/**
		 * Whether or not publishers may modify other users' stored items on the node (true) or only 
		 * MessageItems they have published (false).
        * 
        * @default true
		 * */
		public var modifyAnyItem:Boolean;

		/**
		 * Whether or not stored MessageItems should be retracted from the server when their sender 
		 * leaves the room (true) or left until manually retracted (false).
		 * */
		public var userDependentItems:Boolean;

		/**
		 * Whether or not stored MessageItems should be retracted from the server when meeting session 
		 * ends (true) or left until manually retracted (false).
        * 
        * @default false
		 * 
        */
		public var sessionDependentItems:Boolean;
		
		/**
		 * Storage scheme for the MessageItems sent over this node. It is one of the STORAGE_SCHEME constants listed.
		 * */
		public var itemStorageScheme	:int;
		
		/**
		 * Whether or not private messages are allowed.
        * 
        * @default false
		 */
		public var allowPrivateMessages:Boolean;
		
		/**
		 * Whether or not the subscription to this node is "lazy" - that is, it doesn't receive items automatically.
		 * For fetching items from a node with <code>lazySubscription</code>, use <code>collectionNode.fetchItems()</code>
		 */
		public var lazySubscription:Boolean;
		/**
		 * Whether or not peer-to-peer data messaging should be used for this node. Note that this means no storage is allowed - all messages are transient
		 * and order of delivery is not guaranteed. Flash Player 10.1 is required to allow this feature.
		 */
		public var p2pDataMessaging:Boolean = false;
		
		/**
		 * For use when the item storage scheme is Queue, specifies how many items to remember on the service. Once the number of items sent passes this number,
		 * the oldest item is forgotten for every subsequent item published.
		 */
		public var maxQueuedItems:int = -1;

		public function NodeConfiguration(p_accessModel:int=10, 
										  p_publishModel:int=50,
										  p_persistItems:Boolean=true, 
										  p_modifyAnyItem:Boolean=true, 
										  p_userDependentItems:Boolean=false, 
										  p_sessionDependentItems:Boolean=false,
										  p_storageScheme:int=STORAGE_SCHEME_SINGLE_ITEM,
										  p_allowPrivateMessages:Boolean=false,
										  p_lazySubscription:Boolean=false,
										  p_p2pDataMessaging:Boolean=false,
										  p_maxQueuedItems:int = -1)
		{
			accessModel = p_accessModel;
			publishModel = p_publishModel;
			persistItems = p_persistItems;
			modifyAnyItem = p_modifyAnyItem;
			userDependentItems = p_userDependentItems;
			sessionDependentItems = p_sessionDependentItems;
			itemStorageScheme = p_storageScheme;
			allowPrivateMessages = p_allowPrivateMessages;
			lazySubscription = p_lazySubscription;
			maxQueuedItems = p_maxQueuedItems;
		}

		/**
		 * Takes in a <code>valueObject</code> and structure the NodeConfiguration according to the values therein.
		 * 
		 * @param p_valueObject An Object which represents the non-default values for this NodeConfiguration.
		 */
		public function readValueObject(p_valueObject:Object):void
		{
			for (var i:* in p_valueObject) {
				this[i] = p_valueObject[i];
			}
		}
		
		/**
		 * Creates a ValueObject representation of this NodeConfiguration.
		 *
		 * @return An Object which represents the non-default values for this NodeConfiguration 
		 * suitable for consumption by <code>readValueObject</code>.
		 */	
		public function createValueObject():Object
		{
			var valueObject:Object = new Object();
			if (accessModel!=DEFAULT_CONFIGURATION.accessModel) {
				valueObject.accessModel = accessModel;
			}
			if (publishModel!=DEFAULT_CONFIGURATION.publishModel) {
				valueObject.publishModel = publishModel;
			}
			if (persistItems!=DEFAULT_CONFIGURATION.persistItems) {
				valueObject.persistItems = persistItems;
			}
			if (modifyAnyItem!=DEFAULT_CONFIGURATION.modifyAnyItem) {
				valueObject.modifyAnyItem = modifyAnyItem;
			}
			if (userDependentItems!=DEFAULT_CONFIGURATION.userDependentItems) {
				valueObject.userDependentItems = userDependentItems;
			}
			if (sessionDependentItems!=DEFAULT_CONFIGURATION.sessionDependentItems) {
				valueObject.sessionDependentItems = sessionDependentItems;
			}
			if (itemStorageScheme!=DEFAULT_CONFIGURATION.itemStorageScheme) {
				valueObject.itemStorageScheme = itemStorageScheme;
			}
			if (allowPrivateMessages!=DEFAULT_CONFIGURATION.allowPrivateMessages) {
				valueObject.allowPrivateMessages = allowPrivateMessages;
			}
			if (lazySubscription!=DEFAULT_CONFIGURATION.lazySubscription) {
				valueObject.lazySubscription = lazySubscription;
			}
			
			if (p2pDataMessaging!=DEFAULT_CONFIGURATION.p2pDataMessaging) {
				valueObject.p2pDataMessaging = p2pDataMessaging;
			}
			if (maxQueuedItems!=DEFAULT_CONFIGURATION.maxQueuedItems) {
				valueObject.maxQueuedItems = maxQueuedItems;
			}			
			
			
			return valueObject;
		}
		
		
		public function clone():NodeConfiguration
		{
			var nodeConf:NodeConfiguration = new NodeConfiguration();
			nodeConf.accessModel = accessModel ;
			nodeConf.publishModel = publishModel ;
			nodeConf.persistItems = persistItems ;
			nodeConf.modifyAnyItem = modifyAnyItem ;
			nodeConf.userDependentItems = userDependentItems ;
			nodeConf.sessionDependentItems = sessionDependentItems ;
			nodeConf.itemStorageScheme = itemStorageScheme ;
			nodeConf.allowPrivateMessages = allowPrivateMessages ;
			nodeConf.lazySubscription = lazySubscription;	
			nodeConf.p2pDataMessaging = p2pDataMessaging ;
			nodeConf.maxQueuedItems = maxQueuedItems;
			return nodeConf ;
		}
		
		/**
		 * @private
		 * @return 
		 * 
		 */
		public function toString():String
		{
			return "accessModel:"+accessModel+", publishModel:"+publishModel+", persistItems:"+persistItems+", modifyAnyItem:"+modifyAnyItem+", userDependentItems:"+userDependentItems+", itemStorageScheme:"+itemStorageScheme;
		}
	}
}