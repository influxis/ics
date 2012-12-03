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
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.core.IUID;

	/**
	 * Dispatched when the SharedCollection goes in and out of sync with the service.
	 * 
	 *  @eventType com.adobe.rtc.events.CollectionNodeEvent
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 *  Dispatched when the ICollectionView has been updated in some way.
	 *
	 *  @eventType mx.events.CollectionEvent.COLLECTION_CHANGE
	 */
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	/**
	 *  The type of event emitted when the CollectionNode is about to reconnect to the server. 
	 * This typically happens automatically if the SharedCollection is still subscribed. 
	 * The typical response to this event is to re-initialize any 
	 *  shared parts of a model from scratch since they are about to be re-received from the server.
	 *
	 *  @eventType mx.events.CollectionEvent.RECONNECT
	 */
	[Event(name="reconnect", type="mx.events.CollectionEvent")]

	/**
	 * SharedCollection is a simple ListCollectionView which is shared across the LCCS services. Useful for sharing the contents
	 * of a List or Datagrid (or any other component with a dataProvider), it supports the general addItem, setItemAt, removeItemAt,
	 * and removeAll methods for updating the collection. Any changes through these APIs are shared with other users subscribed to 
	 * the collection. Note, however, that changing a collection's object properties without calling setItemAt to update them results
	 * in those properties not being shared.
	 * <p>
	 * The collection does not share sort order: Any sorting desired should be performed on each respective client. As such,
	 * addItemAt isn't supported, although addItem is. The collection makes update decisions on items based on a unique ID.
	 * Items added to the collection should either implement the IUID interface or provide a field which is guaranteed to be unique 
	 * for this collection. The SharedCollection exposes an <code class="property">idField</code> property to specify which 
	 * field to use as unique ID; in the case the items do not implement IUID.
	 * <p>
	 * Use MessageItem.registerBodyClass to preserve class types when sending and receiving from the service. 
	 * Doing so automatically creates instances of the appropriate class and transfers any properties from the 
	 * received item to the typed objects.
	 * <p>
	 * The SharedCollection exposes the ability to set NodeConfiguration options for the node upon which the items are sent. In this way
	 * the collection can have its access and publish rights assigned as well as the other settings allowed by NodeConfiguration.
	 * Note that this component supports "piggybacking" on existing CollectionNodes through its <code class="property">collectionNode</code> property
	 * and its subscribe method. Developers can avoid CollectionNode proliferation in their applications by pre-supplying a CollectionNode 
	 * to the <code class="property">collectionNode</code> property and a <code class="property">nodeName</code> (in the subscribe method) 
	 * for the SharedCollection to use. If none is supplied, the SharedCollection will create its own collectionNode named for the 
	 * <code class="property">uniqueID</code> supplied in subscribe()for sending and receiving messages.
	 * 
	 * @see com.adobe.rtc.messaging.NodeConfiguration
	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 * @see mx.core.IUID
 	 * 
	 */
   public class  SharedCollection extends ListCollectionView implements ISessionSubscriber
	{
		
		/**
		 * @private
		 */
		protected var _sharedID:String = "_SharedCollection" ;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		/**
		 * The SharedCollection constructor
		 * @param p_list The IList this SharedCollection is meant to wrap.
		 * 
		 */
		public function SharedCollection(p_list:IList=null)
		{
			if (!p_list) {
				p_list = new ArrayCollection();
			}
			
			super(p_list);
		}

		
		/**
		 * Specifies an existing collectionNode to use in case a developer wishes to supply their own, and avoid having the 
		 * sharedCollection create a new one.
		 */
		public var collectionNode:CollectionNode;

		/**
 		 * @private
		 */
		protected static const ITEM_NODE:String = "itemNode";
		/**
 		 * @private
		 */
		protected var _nodeConfig:NodeConfiguration;
		/**
 		 * @private
		 */
		protected var _nodeName:String = ITEM_NODE;
		/**
 		 * @private
		 */
		protected var _myUserID:String;
		
		/**
		 * If each item doesn't implement IUID, specifies a field within the item to use as a unique ID.
		 */
		public var idField:String;
		/**
		 * Specifies the class to use in deserializing any items which arrive from the service.
		 */
		public var itemClass:Class;

		[Bindable("synchronizationChange")]		
		/**
		 * Returns whether or not the sharedCollection has retrieved any information previously stored on the service, and 
		 * is currently connected to the service. 
		 */
		public function get isSynchronized():Boolean
		{
			if (collectionNode) {
				return collectionNode.isSynchronized;
			} else {
				return false;
			}
		}
		
		/**
		 * Sets the node configuration.
		 * @param p_nodeConfig The node configuration..
		 */
		public function setNodeConfiguration(p_nodeConfig:NodeConfiguration):void
		{
			_nodeConfig = p_nodeConfig ;
			
			if ( isSynchronized ) {
				collectionNode.setNodeConfiguration(_nodeName,_nodeConfig);
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
		 * Sets the Node name for the node being create
		 * @param p_nodeConfig The node configuration.
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
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{	
			collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			collectionNode.removeEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
			collectionNode.unsubscribe();
			collectionNode = null;
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
			
			if (collectionNode==null) {
				collectionNode = new CollectionNode();
				collectionNode.sharedID = sharedID ;
				collectionNode.connectSession = _connectSession ;
				collectionNode.subscribe();
			} else {
			}
			collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			collectionNode.addEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
		}
		
		
		/**
		 * Defines the logical location of the component on the service. Typically this assigns the <code class="property">sharedID</code> of the collectionNode
		 * used by the component. <code class="property">sharedIDs</code> should be unique within a room if they're expressing 2 unique locations. Note that
		 * this can only be assigned once before <code>subscribe()</code> is called. For components with an <code class="property">id</code> property, 
		 * <code class="property">sharedID</code> defaults to that value.
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
		 * Replaces the item at the specified index.
		 * @param The new item to set.
		 * @param The index of the item to replace. Note that this index is local-only; on remote collections, it's the unique ID
		 * of the item which is used to locate and replace the item. 
		 * @return The item previously at this location.
		 */
		override public function setItemAt(p_item:Object, p_index:int):Object
		{
			var oldItem:Object = getItemAt(p_index);
			var msg:MessageItem = new MessageItem(_nodeName, p_item, getItemID(oldItem));
			collectionNode.publishItem(msg, true);
			
			return oldItem;
		}

		/**
		 * Adds the specified item to the end of the list. 
		 * @param p_item The item to add.
		 */
		override public function addItem(p_item:Object):void
		{
			var msg:MessageItem = new MessageItem(_nodeName, p_item, getItemID(p_item));
			collectionNode.publishItem(msg);
		}

		/**
		 * Removes the item at the specified index.
		 * @param p_index The index of the item to remove. Note that this index is local-only; on remote collections, it's the 
		 * unique ID of the item which is used to locate and remove the item.
		 * @return The item preivously at this location.
		 * 
		 */		
		override public function removeItemAt(p_index:int):Object
		{
			var oldItem:Object = getItemAt(p_index);
			collectionNode.retractItem(_nodeName, getItemID(oldItem));
			return oldItem;
		}

		/**
		 * Removes all items in the collection.
		 */		
		override public function removeAll():void
		{
			var l:int = length;
			for (var i:int=l-1; i>=0; i--) {
				removeItemAt(i);
			}
			
		}

		/**
		 * @private
		 */
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{
			if ( collectionNode.isSynchronized ) {
				_myUserID = _connectSession.userManager.myUserID;
				if (!collectionNode.isNodeDefined(_nodeName) && collectionNode.canUserConfigure(_myUserID, _nodeName)) {
					// this collectionNode has never been built, and I can add it...
					collectionNode.createNode(_nodeName, _nodeConfig);
				}
			}
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:CollectionNodeEvent):void
		{
			super.removeAll() ;
			dispatchEvent(p_evt);
		}
		
		
		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var newItem:Object = p_evt.item.body;
			var itemID:String = (idField) ? newItem[idField] : newItem.uid;
			var oldItem:Object;
			var i:String;
			// yes, this is ugly. Improve later
			var l:int = length;
			for (var idx:int=0; idx<l; idx++) {
				if (itemID==getItemID(getItemAt(idx))) {
					oldItem = getItemAt(idx);
					break;
				}
			}
			if (oldItem) {
				// it's an item update
				for (i in newItem) {
					if (newItem[i]!=oldItem[i]) {
						var tmpOldValue:Object = oldItem[i];
						oldItem[i] = newItem[i];
						itemUpdated(oldItem, i, tmpOldValue, oldItem[i]);
					}
				}
				super.setItemAt(oldItem, idx);
			} else {
				// it's a brand new item
				if (itemClass) {
					// yeah, this wouldn't work if there are constructor args
					var newItemTyped:Object = new itemClass();
					for (i in newItem) {
						newItemTyped[i] = newItem[i];
					}
					super.addItem(newItemTyped);
				} else {
					super.addItem(newItem);
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName!=_nodeName) {
				return;
			}
			var newItem:Object = p_evt.item.body;
			var itemID:String = (idField) ? newItem[idField] : newItem.uid;
			
			var oldItem:Object;
			// yes, this is ugly. Improve later
			var l:int = length;
			for (var idx:int=0; idx<l; idx++) {
				if (itemID==getItemID(getItemAt(idx))) {
					oldItem = getItemAt(idx);
					break;
				}
			}
			if (oldItem) {
				super.removeItemAt(idx);
			}
		}
		
		/**
		 * @private
		 */
		protected function getItemID(p_item:Object):String
		{
			var testID:String = (p_item is IUID) ? IUID(p_item).uid : p_item[idField] as String;
			if (testID==null) {
				throw new Error("Each item in a sharedCollection requires a unique ID. Please have your items either implement mx.core.IUID, or " + 
						"specify 'sharedCollection.idField' so that the collection knows which field of your item is unique."); 
			} else {
				return testID;
			}
		}
		
	}
}
