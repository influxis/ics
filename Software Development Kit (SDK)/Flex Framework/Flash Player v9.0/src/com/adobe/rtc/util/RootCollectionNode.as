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
package com.adobe.rtc.util
{
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.core.messaging_internal;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.messaging.errors.MessageNodeError;
	import mx.collections.ArrayCollection;

	use namespace messaging_internal;

	/**
	 * Dispatched when a new CollectionNode is added to the room.
	 */
	[Event(name="nodeCreate", type="com.adobe.rtc.events.CollectionNodeEvent")]
	
	/**
	 * Dispatched when a CollectionNode is removed from the room.
	 */
	[Event(name="nodeDelete", type="com.adobe.rtc.events.CollectionNodeEvent")]
	
	/**
	 * Dispatched when a user's role on the room root changes.
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


	/**
	 * RootCollectionNode is a simple class which allows developers to inspect 
	 * the state of a room's root. At its root, a room consists of and
	 * is organized into a set of CollectionNodes. RootCollectionNode allows the 
	 * developer to determine this set, using collectionNames, as well as the 
	 * <code>NODE_CREATE</code> and <code>NODE_DELETE</code> events. 
	 * <p>
	 * Note that only one RootCollectionNode may be present in an application, 
	 * and that <code>subscribe()</code> must be called on the RootCollectionNode 
	 * before use.
	 */
   public class  RootCollectionNode extends CollectionNode
	{
		/**
		 * @private
		 */
		protected var _collectionNames:ArrayCollection = new ArrayCollection();
		
		public function RootCollectionNode()
		{
		}

		/**
		 * Connects the RootCollectionNode to the service; it is required before using 
		 * the component.
		 */
		override public function subscribe():void
		{
			_messageManager = connectSession.sessionInternals.messaging_internal::messageManager;
			_messageManager.createRootCollection(this);
		}
		
		/**
		 * Returns a set of names for all the CollectionNodes in the room.
		 */
		public function get collectionNames():ArrayCollection
		{
			return _collectionNames;
		}

		/**
		 * @private
		 * Removes the given CollectionNode.
		 * 
		 * @param p_nodeName
		 * 
		 */		
		override public function removeNode(p_nodeName:String):void
		{
			//in this case we want to remove the collection
			_messageManager.removeNode(p_nodeName);
		}
				
		/**
		 * @private
		 * Creates a new collection.
		 * 
		 * @param p_nodeName
		 * @param p_nodeConfiguration
		 */
		override public function createNode(p_nodeName:String, p_nodeConfiguration:NodeConfiguration=null):void
		{
			if (!_isSynchronized) {
				//throw an exception, you have to wake until your Collection/Node is synched to push to it
				throw new MessageNodeError(MessageNodeError.NODE_NOT_SYNCHRONIZED);
				return;
			}
			
			_messageManager.createNode(p_nodeName);
		}
		
		/**
		 * @private
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		override public function close():void
		{
			_collectionNames.removeAll();
		}
		
		/** 
		 * @private
		 * This is how we get the collection names from the MessageManager.
		 */		
		override messaging_internal function receiveNode(p_collectionName:String, p_nodeConfiguration:NodeConfiguration=null):void
		{
			_collectionNames.addItem(p_collectionName);
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.NODE_CREATE, p_collectionName));
		}		

		/** 
		 * @private
		 * This is how MessageManager tells us a collection goes away.
		 */		
		override messaging_internal function receiveNodeDeletion(p_collectionName:String):void
		{
			var l:int = _collectionNames.length;
			for (var i:int=0; i < l; i++) {
				if (_collectionNames.getItemAt(i)==p_collectionName) {
					_collectionNames.removeItemAt(i);
					break ;
				}
			}
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.NODE_DELETE, p_collectionName));
		}

		/** 
		 * @private
		 * This is how MessageManager tells us a collection goes away.
		 */		
		override messaging_internal function receiveUserRole(p_userID:String, p_role:int, p_nodeName:String=null):void
		{
			var evt:CollectionNodeEvent;
			evt = new CollectionNodeEvent(CollectionNodeEvent.USER_ROLE_CHANGE);
			evt.userID = p_userID;
			dispatchEvent(evt);
		}
		
	}
}