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
package com.adobe.rtc.sharedModel
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SharedObjectEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	
	import flash.events.EventDispatcher;

	/**
	 * Dispatched when the SharedObject goes in and out of sync with the service.
	 * 
	 *  @eventType com.adobe.rtc.events.CollectionNodeEvent
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 *  Dispatched when the SharedObject has been updated in some way.
	 *
	 *  @eventType com.adobe.rtc.events.SharedObjectEvent
	 */
	[Event(name="propertyChange", type="com.adobe.rtc.events.SharedObjectEvent")]
	/**
	 *  Dispatched when an item to SharedObject is added.
	 *
	 *  @eventType com.adobe.rtc.events.SharedObjectEvent
	 */
	[Event(name="propertyAdd", type="com.adobe.rtc.events.SharedObjectEvent")]
	/**
	 *  Dispatched when an item from SharedObject is removed. 
	 *
	 *  @eventType com.adobe.rtc.events.SharedObjectEvent
	 */
	[Event(name="propertyRetracted", type="com.adobe.rtc.events.SharedObjectEvent")]


	/**
	 *  The type of event emitted when the CollectionNode is about to reconnect to the server. 
	 *  This typically happens automatically if the SharedObject is still subscribed. 
	 *  The typical response to this event is to re-initialize any 
	 *  shared parts of a model from scratch since they are about to be re-received from the server.
	 *
	 *  @eventType com.adobe.rtc.events.CollectionNodeEvent
	 */
	[Event(name="reconnect", type="com.adobe.rtc.events.CollectionNodeEvent")]
	
	
	/**
	 * SharedObject is used to store data in an unordered hash (key-value) across the LCCS services; elements can only be accessed using its key.
	 * <p>
	 * A SharedObject can be used in situations where you need to access a property using its key value as opposed to
	 * index. Similar to SharedCollection and SharedProperty,this component supports "piggybacking" on existing CollectionNodes,
	 * through its <code class="property">collectionNode</code> property and its subscribe method. Developers can avoid CollectionNode
	 * proliferation in their applications by pre-supplying a CollectionNode (to the <code class="property">collectionNode</code> property)
	 * and a nodeName (in the subscribe method) for the SharedObject to use. If none is supplied, the SharedObject will create its own 
	 * collectionNode (named for the uniqueID supplied in subscribe()) for sending and receiving messages.
	 * 
	 *
	 * <h6>Using shared objects</h6>
	 * <listing>	  
	 *	protected var _collectionNode:CollectionNode;
	 *	protected var _sharedObject:com.adobe.rtc.sharedModel.SharedObject;
	 * 
	 *	protected function initializeSharedObject():void
	 *	{
	 *		_collectionNode=new CollectionNode();
	 *		_collectionNode.connectSession="YOUR APPS CONNECT SESSION";
	 *		_collectionNode.sharedID="tmpCollectionNode";
	 *		_sharedObject=new com.adobe.rtc.sharedModel.SharedObject();
	 *		_sharedObject.collectionNode=_collectionNode;
	 *		_sharedObject.connectSession=sess;
	 *		_sharedObject.nodeName="sharedHash";
	 *		_sharedObject.sharedID="tmpCollectionNode";
	 *		//Subscribe to your collection nodes that does the magic :)
	 *		_collectionNode.subscribe();
	 *  		_sharedObject.subscribe();
	 *		_sharedObject.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSharedObjSync);
	 *		_sharedObject.addEventListener(SharedObjectEvent.PROPERTY_REMOVE,onSharedObjChange);
	 *		_sharedObject.addEventListener(SharedObjectEvent.PROPERTY_ADD,onSharedObjChange);
	 *		_sharedObject.addEventListener(SharedObjectEvent.PROPERTY_CHANGE,onSharedObjChange);
	 *	}
	 *	
	 *	protected function onSharedObjSync(p_evt:CollectionNodeEvent):void
	 *	{
	 *		if (_sharedObject.isSynchronized) {
	 *			_sharedObject.setProperty("key1", "demo1");
	 *			_sharedObject.setProperty("key2", 2);
	 *			// Modifying the property "key1"
	 *			_sharedObject.setProperty("key1", "key1 Mutated");
	 *			// Removing the demo1 property from SharedObject
	 *			_sharedObject.removeProperty("key2");
	 *			// Removing all the properties from the SharedObject
	 *			_sharedObject.removeAll();
	 *		}
	 *	}
	 *	
	 *	protected function onSharedObjChange(p_evt:SharedObjectEvent):void
	 *	{
	 *		if (_sharedObject.isSynchronized) {
	 *			var key:String = p_evt.propertyName;
	 *			// Example of SharedObject.getProperty
	 *			// Check if the SharedObject is empty
	 *		}
	 *	}</listing>
	 * @see com.adobe.rtc.sharedModel.SharedCollection
	 * @see com.adobe.rtc.sharedModel.SharedProperty 
	 */ 
   public class  SharedObject extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected var _sharedID:String = "_SharedObject" ;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * @private 
		 */	
		protected var _collectionNode:CollectionNode;
		/**
 		 * @private
		 */
		protected var _nodeConfig:NodeConfiguration;
		/**
 		 * @private
		 */
		protected var _nodeName:String = "sharedObjectNode";
		
		/**
 		 * @private
		 */
		protected var _myUserID:String;
		
		/**
 		 * @private
		 */
		protected var _sharedObject:Object = new Object();

		/**
		 * The SharedObject constructor
		 */		 
		public function SharedObject()
		{
		}
		
		/**
		 * Defines the logical location of the component on the service - typically this assigns the sharedID of the collectionNode
		 * used by the component. sharedIDs should be unique within a room (if they're expressing 2 unique locations). Note that
		 * this can only be assigned once (before <code>subscribe()</code> is called). For components with an <code class="property">id</code> property, 
		 * sharedID defaults to that value.
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
		}
		
		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}

		
		
		/**
		 * The IConnectSession with which this component is associated. Note that this may only be set once before <code>subscribe</code>
		 * is called; re-sessioning of components is not supported. Defaults to the first IConnectSession created in the application.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * Specifies an existing collectionNode to use in case a developer wishes to supply their own, and avoid having the 
		 * sharedObject create a new one.
		 */
		public function get collectionNode():CollectionNode
		{
			return _collectionNode;
		}
		
		public function set collectionNode(p_collectionNode:CollectionNode):void
		{
			_collectionNode = p_collectionNode;
		}
		
		//[Bindable("synchronizationChange")]		
		/**
		 * Returns whether or not the SharedObject has retrieved any information previously stored on the service, and 
		 * is currently connected to the service. 
		 */
		public function get isSynchronized():Boolean
		{
			if (_collectionNode) {
				return _collectionNode.isSynchronized;
			} else {
				return false;
			}
		}
		
		/**
		 * Sets the Node Configuration on a already defined node that holds the sharedObject
		 * @param p_nodeConfig The Node Configuration
		 */
		public function setNodeConfiguration(p_nodeConfig:NodeConfiguration):void
		{
			_nodeConfig = p_nodeConfig ;
			
			if ( isSynchronized ) {
				_collectionNode.setNodeConfiguration(_nodeName,_nodeConfig);
			}
		}
		
		/**
		 * @private
		 */
		public function getNodeConfiguration():NodeConfiguration
		{
			return _nodeConfig.clone() ;
		}
		
		/**
		 * Sets the Node name for the node being created
		 * 
		 * @param p_nodeName The Node Name in which the sharedObject will be residing.
		 */
		public function set nodeName(p_nodeName:String):void
		{
			_nodeName = p_nodeName ;
		}
		
		/**
		 * @private
		 */
		public function get nodeName():String
		{
			return _nodeName ;
		}
		
		/**
		 *  Sets the role of a given user for the SharedObject.
		 * 
		 * @param p_userRole The role value to set on the specified user.
		 * @param p_userID The ID of the user whose role should be set.
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) {
				return ;
			}
			
			_collectionNode.setUserRole(p_userID,p_userRole);
		}
		
		
		/**
		 *  Returns the role of a given user for the SharedObject.
		 * 
		 * @param p_userID The user ID for the user being queried.
		 */
		public function getUserRole(p_userID:String):int
		{
			if ( p_userID == null ) {
				throw new Error("Note: The user ID can't be null");
			}
			
			return _collectionNode.getUserRole(p_userID);
		}

		


		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( _nodeConfig == null ) {
				_nodeConfig = new NodeConfiguration();
			}
			
			_nodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
			
			if (_collectionNode==null) {
				_collectionNode = new CollectionNode();
				_collectionNode.sharedID = sharedID ;
				_collectionNode.connectSession = _connectSession ;
				_collectionNode.subscribe();
			} 
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
		}

		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{	
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.removeEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
			_collectionNode.unsubscribe();
			_collectionNode = null;
		}
		
		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if ( _collectionNode.isSynchronized ) {
				_myUserID = _connectSession.userManager.myUserID;
				if (!_collectionNode.isNodeDefined(_nodeName) && _collectionNode.canUserConfigure(_myUserID, _nodeName)) {
					// this collectionNode has never been built, and I can add it...
					_collectionNode.createNode(_nodeName, _nodeConfig);
				}
			}
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:CollectionNodeEvent):void
		{
			_sharedObject = new Object();
			dispatchEvent(p_evt);
		}
		
		
		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			//update the Object
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var newItemToAdd:MessageItem = p_evt.item;
			var evt:SharedObjectEvent;
			
			var eventType:String = (_sharedObject.hasOwnProperty(newItemToAdd.itemID)) ? SharedObjectEvent.PROPERTY_CHANGE : SharedObjectEvent.PROPERTY_ADD;
			evt = new SharedObjectEvent(eventType,newItemToAdd.itemID, newItemToAdd.body, newItemToAdd.publisherID);
			
			_sharedObject[newItemToAdd.itemID] = newItemToAdd.body;
			dispatchEvent(evt);
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			//Update the Object
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var retractedItem:MessageItem = p_evt.item;
			delete _sharedObject[retractedItem.itemID];
			var evt:SharedObjectEvent = new SharedObjectEvent(SharedObjectEvent.PROPERTY_REMOVE,retractedItem.itemID, retractedItem.body);
			dispatchEvent(evt);
		}
		
		/**
		 * Add or Update the value of a given property name in a shared object
		 * @param p_propertyName The key of the Property being added
		 * @param p_value The value of the property, defaults to null
		 */ 
		public function setProperty(p_propertyName:String, p_value:Object = null):void
		{
			var msg:MessageItem = new MessageItem(_nodeName, p_value, p_propertyName);
			_collectionNode.publishItem(msg);
		}
		
		/**
		 * Returns the value of the given property name
		 * @param p_propertyName The key of the Property whose value is requested.
		 */ 
		public function getProperty(p_propertyName:String):*
		{
			return _sharedObject[p_propertyName];
		}
		
		/**
		 * Returns whether the given property exists or not in the shared object
		 * @param p_propertyName The key of the Property whose presence is verified
		 */ 
		public function hasProperty(p_propertyName:String):Boolean
		{
			return _sharedObject.hasOwnProperty(p_propertyName);
		}
		
		/**
		 * Remove the property from the shared object
		 * @param p_propertyName The key of the Property that needs to be retracted from the sharedObject
		 */ 
		public function removeProperty(p_propertyName:String):void
		{
			_collectionNode.retractItem(_nodeName, p_propertyName);
		}
		
		/**
		 * Return all the items in the shared object as one big hashMap (Object)
		 */ 
		public function get values():Object
		{
			return _sharedObject;
		}
		
		/**
		 * Remove all the items in the shared object.
		 */ 
 		public function removeAll():void
		{
			for (var propertyName:String in _sharedObject) {
				removeProperty(propertyName);
			}
		}
		
		/**
		 * Check if the shared object is empty
		 */ 
		public function isEmpty():Boolean
		{
			for (var propertyName:String in _sharedObject) {
				return false;
			}
			return true;
		} 
		
	}
}