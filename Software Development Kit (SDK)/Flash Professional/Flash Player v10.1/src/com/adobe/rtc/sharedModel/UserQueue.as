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
	import com.adobe.rtc.events.UserQueueEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedModel.userQueueClasses.UserQueueItem;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	/**
	 * Dispatched when the component goes in and out of sync.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when a <code>UserQueueItem</code> is added or handled.
	 */
	[Event(name="queueItemUpdate", type="com.adobe.rtc.events.UserQueueEvent")]

	/**
	 * Dispatched when the queue is cleared.
	 */
	[Event(name="queueClear", type="com.adobe.rtc.events.UserQueueEvent")]
	
	/**
	* @private
	*/
	[Event(name="log", type="com.adobe.rtc.events.UserQueueEvent")]
	
	/**
	 * Dispatched when an item in the queue is accepted.
	 */
	[Event(name="accepted", type="com.adobe.rtc.events.UserQueueEvent")]
	
	/**
	 * Dispatched when an item in the queue is cancelled.
	 */
	[Event(name="cancel", type="com.adobe.rtc.events.UserQueueEvent")]
	
	/**
	 * Dispatched when an item in the queue is denied.
	 */
	[Event(name="deny", type="com.adobe.rtc.events.UserQueueEvent")]


	/**
	 * UserQueue is a model class that can be used to create and manage queues of users 
	 * who are making requests. Examples of such queues include groups of users who are:
	 * <ul>
	 * <li>Knocking to be allowed in a private meeting room.</li>
	 * <li>Raising their hand to answer a host's question.</li>
	 * <li>Requesting control of the shared screen.</li>
	 * </ul>
	 * 
	 * There are two classes of users for this class: queue managers and queue users
	 * (queue managers are also queue users): 
	 * <ul>
	 * <li><strong>Queue managers</strong>: Managers can see who's in the queue, accept, deny, 
	 * or cancel any and all of the requests. They may also optionally send a response to users 
	 * explaining their decision.</li>
	 * 
	 * <li><strong>Queue users</strong>: Users can request to add themselvels to the queue 
	 * or cancel their requests. They may also send an optional message to the queue managers.</li>
	 * </ul>
	 * Each of these two classes of users are defined by specifying the role levels of each class 
	 * in the constructor.
	 * <p>
	 * User requests are either pending, accepted, denied, or canceled. A <code>UserQueueItem</code> 
	 * is used to store each request.
	 * <p>
 	 * Note that this component supports "piggybacking" on existing CollectionNodes through 
	 * its constructor. Developers can avoid CollectionNode proliferation in their apps by 
	 * pre-supplying a CollectionNode and a nodeName for the UserQueue to use. If none is 
	 * supplied, the UserQueue will create its own collectionNode for sending and receiving 
	 * messages.
	 * 
	 * @inheritDocs flash.events.EventDispatcher
	 * @see com.adobe.rtc.sharedModel.userQueueClasses.UserQueueItem
	 * @see com.adobe.rtc.events.UserQueueEvent UserQueueEvent
	 */
   public class  UserQueue extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		protected static var NODENAME_QUEUE:String = "queue";

		/**
		 * @private
		 */
		protected static var NODENAME_NOTIFICATIONS:String = "notifications";

		/**
		 * @private
		 */
		protected var _id:String;
		
		/**
		 * @private
		 */
		protected var _roleForRequesting:int=UserRoles.VIEWER;
		
		/**
		 * @private
		 */
		protected var _roleForManaging:int=UserRoles.OWNER;

		/**
		 * @private
		 */
		protected var _sharedID:String = "_UserQueue";
		
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * @private
		 */
		protected var _isSynchronized:Boolean = false;

		/**
		 * @private
		 */
		protected var _userManager:UserManager;
				
		/**
		 * @private
		 */
		 //for queue users, it will just contain one item for our own pending request
		 //for queue managers, it will store one item per userID
		protected var _userQueueItems:Dictionary;
		
		/**
		 * @private
		 */
		protected var _nodeConfigurationForQueue:NodeConfiguration;	
		
		/**
		 * @private
		 */
		protected var _nodeConfigurationForNotifications:NodeConfiguration;	
		 	/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		/**
		 * Constructor.
		 * 
		 * @param p_id The unique identifier for this UserQueue. As a best practice, use the same ID 
		 * as the collaboration component that hosts it.
		 * @param p_collectionNode If you'd like to "bring your own" collection node, pass it here.
		 * @param p_nodeNameQueue If you'd like to specify the node name to use for the queue items, pass it here.
		 * @param p_nodeNameNotification If you'd like to specify the node name to use for the queue 
		 * notifications, pass it here.
 		 * @param p_roleForRequesting The role users need to add and remove themselves from the queue.
		 * @param p_roleForManaging The role users need to view and manage the queue. In some instances, 
		 * you may want only owners to be able to see the queue. In other instances, it's OK if everyone 
		 * sees who's in the queue and what position they're in.
		 * @param p_userDependentQueueItems Whether or not queue requests are cleared if the requesting 
		 * user leaves the room.
		 * @param p_sessionDependentQueueItems Whether or not all queue requests are cleared if the session ends.
 		 * 
		 */
		public function UserQueue()
		{		
							
			_userQueueItems = new Dictionary();
			
			_nodeConfigurationForQueue = new NodeConfiguration();
			_nodeConfigurationForQueue.accessModel = UserRoles.OWNER;
			_nodeConfigurationForQueue.publishModel = UserRoles.VIEWER;
			_nodeConfigurationForQueue.modifyAnyItem = false;
			_nodeConfigurationForQueue.userDependentItems = false;
			_nodeConfigurationForQueue.sessionDependentItems = false;
			_nodeConfigurationForQueue.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_QUEUE;
			
			_nodeConfigurationForNotifications = new NodeConfiguration();
			_nodeConfigurationForNotifications.accessModel = UserRoles.VIEWER ;
			_nodeConfigurationForNotifications.publishModel = UserRoles.VIEWER ;
			_nodeConfigurationForNotifications.persistItems = false;
//			_nodeConfigurationForNotifications.modifyAnyItem = true;
//			_nodeConfigurationForNotifications.userDependentItems = false;
//			_nodeConfigurationForNotifications.sessionDependentItems = p_sessionDependentQueueItems;
			_nodeConfigurationForNotifications.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_SINGLE_ITEM;
			
			
			// If they brought their own collection node, use it; otherwise create one afresh.
			
			// Override the default node names.
			
			
			//myTrace("constructor: affForReq:"+_roleForRequesting+", affForMan:"+_roleForManaging);
		}
		
		
		
		/**
		 * The role users need to add and remove themselves from the queue.
		 * @param p_roleForRequesting the role value
		 */
		public function set roleForRequesting(p_roleForRequesting:int):void
		{
			_roleForRequesting = p_roleForRequesting ;
			_nodeConfigurationForNotifications.accessModel = _roleForRequesting;
			_nodeConfigurationForNotifications.publishModel = _roleForRequesting ;
			_nodeConfigurationForQueue.publishModel = _roleForRequesting;
		}
		
		
		/**
		 * The role users need to view and manage the queue. In some instances, 
		 * you may want only owners to be able to see the queue. In other instances, it's OK if everyone 
		 * sees who's in the queue and what position they're in.
		 * @param p_roleForManaging 
		 */
		public function set roleForManaging(p_roleForManaging:int):void
		{
			_roleForManaging = p_roleForManaging;
			_nodeConfigurationForQueue.accessModel = _roleForManaging;
		}
		
		
		/**
		 * Sets the Collection Node to which the shared property subscribes/publishes
		 * @param p_collectionNode the CollectionNode
		 */
		public function set collectionNode(p_collectionNode:CollectionNode ):void
		{
			if ( p_collectionNode != null ) {
				_collectionNode = p_collectionNode ;
			}
		}
		
		
		/**
		 * @private
		 */
		public function get collectionNode():CollectionNode
		{
			return _collectionNode ;
		}
		
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);				
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			
			_collectionNode.unsubscribe();
			_collectionNode = null ;
		}
		
		
		/**
		 * Sets true or false whether the queue items are user dependent or not..
		 * @param p_userDependentQueueItems Boolean value
		 */
		public function set userDependentQueueItems(p_userDependentQueueItems:Boolean ):void
		{
			_nodeConfigurationForQueue.userDependentItems = p_userDependentQueueItems ;
		}
		
		
		/**
		 * @private
		 */
		public function get userDependentQueueItems():Boolean
		{
			return _nodeConfigurationForQueue.userDependentItems ;
		}
		
		/**
		 * Sets true or false whether the queue items are session dependent or not..
		 * @param p_sessionDependentQueueItems Boolean value
		 */
		public function set sessionDependentQueueItems(p_sessionDependentQueueItems:Boolean ):void
		{
			_nodeConfigurationForQueue.sessionDependentItems = p_sessionDependentQueueItems ;
		}
		
		
		/**
		 * @private
		 */
		public function get sessionDependentQueueItems():Boolean
		{
			return _nodeConfigurationForQueue.sessionDependentItems ;
		}
		
		
		/**
		 * Sets the Node Name for the notification node
		 * @param p_nodeName The name of the node
		 */
		public function set nodeNameNotification(p_nodeNameNotification:String):void
		{
			if(p_nodeNameNotification) {
				NODENAME_NOTIFICATIONS = p_nodeNameNotification;
			}
		}
		
		/**
		 * @private
		 */
		public function get nodeNameNotification():String
		{
			return NODENAME_NOTIFICATIONS ;
		}
		
		/**
		 * Sets the Node Name for the Queue Node
		 * @param p_nodeName The name of the node
		 */
		public function set nodeNameQueue(p_nodeNameQueue:String):void
		{
			if(p_nodeNameQueue) {
				NODENAME_QUEUE = p_nodeNameQueue;
			}
		}
		
		/**
		 * @private
		 */
		public function get nodeNameQueue():String
		{
			return NODENAME_QUEUE ;
		}
		
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			_userManager = _connectSession.userManager;
			
			if(!_collectionNode) {
				_collectionNode = new CollectionNode();
				_collectionNode.sharedID = sharedID ;
				_collectionNode.connectSession = _connectSession ;
				_collectionNode.subscribe();
			}
			else {
				if (_collectionNode.isSynchronized) {
					onSynchronizationChange(new CollectionNodeEvent(CollectionNodeEvent.SYNCHRONIZATION_CHANGE));
				}
			}
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);				
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			
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
		
		
		//[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the <code>UserQueue</code> is connected and fully synchronized with 
		 * the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _isSynchronized;
		}

		/**
		 * Determines the role needed for managing this queue.
		 */
		public function get roleForManaging():int
		{
			return _roleForManaging;
		}


		/**
		 * Determines the role needed for using this queue.
		 */
		public function get roleForRequesting():int
		{
			return _roleForRequesting;
		}
		
		/**
		 * @private
		 */
		public function getUserRole(p_userID:String,p_nodeName:String=null):int
		{
			return _collectionNode.getUserRole(p_userID,p_nodeName);
		}
		 
		/*
		 * Returns an array of <code>UserQueueItems</code>, sorted in order of requests, including items 
		 * that were denied or canceled.
		 * 
		 * @return An empty array if called by a non-queue-manager.
		 */
		public function get queue():Array
		{
			if ( getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return [];
			}
			
			var res:Array = new Array();
			for each (var u:UserQueueItem in _userQueueItems) {
				res.push(u);
			}
			res.sortOn("position");			
			return res;
		}
		
		/**
		 * Returns an array of <code>UserQueueItems</code> containing only items that 
		 * have status of <code>STATUS_PENDING</code>. 
		 */
		public function get pendingQueue():Array
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return [];
			}

			var res:Array = new Array();
			for each (var u:UserQueueItem in _userQueueItems) {
				if (u.status == UserQueueItem.STATUS_PENDING) {
					res.push(u);
				}
			}
			res.sortOn("position");			
			return res;
		}
		
		/**
		 * Returns the <code>UserQueueItem</code> for a specific user.
		 * If it is called by a non-queue-manager, then it returns null.
		 * 
		 * @param p_userID The ID of the user associated with this queue item.
		 */
		public function getUserItem(p_userID:String):UserQueueItem
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return null;
			}
			return _userQueueItems[p_userID];
		}

		/**
		 * Accepts the first pending item in the queue and sends an optional response;
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function acceptFirstPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var pq:Array = pendingQueue;
			if (pq.length > 0) {
				var userItem:UserQueueItem = pq[0];
				acceptUser(userItem.userID, p_response);
			}
		}

		/**
		 * Denies the first pending item in the queue but does nothing if 
		 * called by a non-queue-manager.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function denyFirstPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var pq:Array = pendingQueue;
			if (pq.length > 0) {
				var userItem:UserQueueItem = pq[0];
				denyUser(userItem.userID, p_response);			
			}
		}
		
		/**
		 * Cancels the first pending item in the queue and sends an optional response;
		 * it does nothing if called by a non-queue-manager. Non-queue-managers
		 * may call <code>cancel()</code> to cancel their own requests.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function cancelFirstPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var pq:Array = pendingQueue;
			if (pq.length > 0) {
				var userItem:UserQueueItem = pq[0];
				cancelUser(userItem.userID, p_response);			
			}
		}
		
		/**
		 * Accepts the request of user with the p_userID and sends an optional response;
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_userID The <code>userID</code> of the user to accept. 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function acceptUser(p_userID:String, p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var userQueueItem:UserQueueItem = _userQueueItems[p_userID];
			
			if (userQueueItem == null) {
				return;
			}
			
			var itemID:int = userQueueItem.position;
			
			//retract item from queue
			_collectionNode.retractItem(NODENAME_QUEUE, itemID.toString());
			
			//publish to NODENAME_NOTIFICATIONS that it was canceled
			userQueueItem.response = p_response;
			userQueueItem.status = UserQueueItem.STATUS_ACCEPTED;

			var messageItem:MessageItem = new MessageItem(NODENAME_NOTIFICATIONS, userQueueItem);
			_collectionNode.publishItem(messageItem);
		}

		/**
		 * Denies the request of user with a specific p_userID and sends an optional response;
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_userID The <code>userID</code> of the user to deny. 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function denyUser(p_userID:String, p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var userQueueItem:UserQueueItem = _userQueueItems[p_userID];
			
			if (userQueueItem == null) {
				myTrace("error, user not pending");
				return;
			}
			
			var itemID:int = userQueueItem.position;
			
			//retract item from queue
			_collectionNode.retractItem(NODENAME_QUEUE, itemID.toString());
			
			//publish to NODENAME_NOTIFICATIONS that it was canceled
			userQueueItem.response = p_response;
			userQueueItem.status = UserQueueItem.STATUS_DENIED;

			var messageItem:MessageItem = new MessageItem(NODENAME_NOTIFICATIONS, userQueueItem);
			_collectionNode.publishItem(messageItem);
		}

		/**
		 * Cancels the request of user with the p_userID and sends an optional response; it does
		 * nothing if called by a non-queue-manager.
		 * 
		 * @param p_userID The <code>userID</code> of the user to cancel. 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function cancelUser(p_userID:String, p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			var userQueueItem:UserQueueItem = _userQueueItems[p_userID];
			
			if (userQueueItem == null) {
				myTrace("error, user not pending");
				return;
			}
			
			var itemID:int = userQueueItem.position;
			
			//retract item from queue
			_collectionNode.retractItem(NODENAME_QUEUE, itemID.toString());
			
			//publish to NODENAME_NOTIFICATIONS that it was canceled
			userQueueItem.response = p_response;
			userQueueItem.status = UserQueueItem.STATUS_CANCELED;

			var messageItem:MessageItem = new MessageItem(NODENAME_NOTIFICATIONS, userQueueItem);
			_collectionNode.publishItem(messageItem);
		}

		/**
		 * Accepts all pending requests and sends an optional response;
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function acceptAllPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			for each (var u:UserQueueItem in _userQueueItems) {
				if (u.status == UserQueueItem.STATUS_PENDING) {
					var userID:String = u.userID;
					acceptUser(userID, p_response);
				}
			}
		}

		/**
		 * Denies all pending requests and sends an optional response; 
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function denyAllPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			for each (var u:UserQueueItem in _userQueueItems) {
				if (u.status == UserQueueItem.STATUS_PENDING) {
					var userID:String = u.userID;
					denyUser(userID, p_response);
				}
			}
		}

		/**
		 * Cancels all pending requests and sends an optional response; 
		 * it does nothing if called by a non-queue-manager.
		 * 
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function cancelAllPending(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}

			for each (var u:UserQueueItem in _userQueueItems) {
				if (u.status == UserQueueItem.STATUS_PENDING) {
					var userID:String = u.userID;
					cancelUser(userID, p_response);
				}
			}
		}

		/**
		 * Clears the pending queue as well as all of the requests that have been 
		 * previously dealt with and sends an optional reason for clearing which 
		 * is passed to the <code>CLEAR</code> event; it does nothing if called 
		 * by a non-queue-manager.
		 * 
		 * @param p_reason [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to those waiting in the queue. 
		 */
		public function clear(p_reason:String):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForManaging) {
				myTrace("You do not have permission to manage the queue.");
				return;
			}	
			
			//delete the node an recreate it to clear all items
			_collectionNode.removeNode(NODENAME_QUEUE);
			_collectionNode.createNode(NODENAME_QUEUE, _nodeConfigurationForQueue);
			_collectionNode.removeNode(NODENAME_NOTIFICATIONS);
			_collectionNode.createNode(NODENAME_NOTIFICATIONS, _nodeConfigurationForNotifications);
		}
		
		
		/**
		 * Makes a user request to be added to the queue and an optional reason  
		 * which could indicate the reason they want to be added. 
		 * 
		 * @param p_message [Optional] A message string sent from the requester to 
		 * the queue manager.
		 * @param  p_descriptor [Optional] An object that describes information about UserQueueItem
		 */
		public function request(p_message:String="",p_descriptor:Object=null):void
		{
			if ( getUserRole(_userManager.myUserID)<_roleForRequesting) {
				myTrace("you don't have permission to use the queue ("+getUserRole(_userManager.myUserID)+"/"+_roleForRequesting+")");
				return;
			}
			
			var userQueueItem:UserQueueItem = new UserQueueItem();
			userQueueItem.message = p_message ;
			if ( p_descriptor != null ) 
				userQueueItem.descriptor = p_descriptor ;

			var messageItem:MessageItem = new MessageItem(NODENAME_QUEUE, userQueueItem.createValueObject());
			_collectionNode.publishItem(messageItem);
		}

		/**
		 * Makes a user request to cancel one of their previous requests.
		 *
		 * @param p_response [Optional. Defaults to null] On this function's 
		 * action, a message sent from the queue manager to someone waiting in the queue. 
		 */
		public function cancel(p_response:String=null):void
		{
			if (getUserRole(_userManager.myUserID) < _roleForRequesting) {
				myTrace("you don't have permission to use the queue ("+getUserRole(_userManager.myUserID)+"/"+_roleForRequesting+")");
				return;
			}
			
			var userQueueItem:UserQueueItem = _userQueueItems[_userManager.myUserID];

			if (userQueueItem == null) {
				myTrace("error, user not pending");
				//TODO: This could happen because we're still round-tripping the request!
				return;
			}

			var itemID:int = userQueueItem.position;
			
			//retract item from queue
			_collectionNode.retractItem(NODENAME_QUEUE, itemID.toString());
			
			//publish to NODENAME_NOTIFICATIONS that it was canceled
			userQueueItem.response = p_response;
			userQueueItem.status = UserQueueItem.STATUS_CANCELED;

			var messageItem:MessageItem = new MessageItem(NODENAME_NOTIFICATIONS, userQueueItem);
			_collectionNode.publishItem(messageItem);
		}






//PRIVATE METHODS

		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
						
			_isSynchronized = _collectionNode.isSynchronized;
			
			if (_isSynchronized && (getUserRole(_userManager.myUserID) >= _roleForManaging) )
			{
				//we're the first ones here
				
				//this node is in the template
				if (!_collectionNode.isNodeDefined(NODENAME_QUEUE)) {
					_collectionNode.createNode(NODENAME_QUEUE, _nodeConfigurationForQueue);
				}
				
				//this one isn't
				if (!_collectionNode.isNodeDefined(NODENAME_NOTIFICATIONS)) {
					_collectionNode.createNode(NODENAME_NOTIFICATIONS, _nodeConfigurationForNotifications);
				}
			}
			dispatchEvent(p_evt);	//bubble it up
		}

		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			var theItem:MessageItem = p_evt.item;

			if (p_evt.nodeName != NODENAME_QUEUE && p_evt.nodeName != NODENAME_NOTIFICATIONS) {
				//ignore, not for me
				return;
			}

			var userQueueItem:UserQueueItem = new UserQueueItem();
			userQueueItem.readValueObject(theItem.body);
			userQueueItem.position = parseInt(theItem.itemID);

			var publisherID:String = theItem.publisherID;
			
			if (p_evt.nodeName == NODENAME_QUEUE) {
				
				//for queue users, this only happens for your own ID

				userQueueItem.userID = publisherID;
				
				if (_userQueueItems[publisherID] == undefined) {
					//this is the first time we see a request from this user
					_userQueueItems[publisherID] = userQueueItem;	//save it!				
				} else {
					//this is a user that was dealt with before asking again
					_userQueueItems[publisherID] = userQueueItem;	//save it!				
				}
			} else if (p_evt.nodeName == NODENAME_NOTIFICATIONS) {
				userQueueItem.dealtBy = publisherID;
				
				// If this event pertains to me, dispatch a message
				if (userQueueItem.userID == _userManager.myUserID) {
					//throw my event
					if (userQueueItem.status == UserQueueItem.STATUS_ACCEPTED) {
						dispatchEvent(new UserQueueEvent(UserQueueEvent.ACCEPT, userQueueItem.userID));
					} else if (userQueueItem.status == UserQueueItem.STATUS_DENIED) {
						dispatchEvent(new UserQueueEvent(UserQueueEvent.DENY, userQueueItem.userID));
					} else if (userQueueItem.status == UserQueueItem.STATUS_CANCELED) {
						var newEvent:UserQueueEvent = new UserQueueEvent(UserQueueEvent.CANCEL, userQueueItem.userID);
						newEvent.reason = userQueueItem.response;
						dispatchEvent(newEvent);
					}
				}

				//the descriptor could be empty if I was kicked out before publishing it
				if (_userManager.getUserDescriptor(_userManager.myUserID) != null && getUserRole(_userManager.myUserID) >= _roleForManaging) {
					//a queue manager builds out _userQueueItems from here
					var prevItem:UserQueueItem = _userQueueItems[userQueueItem.userID];
					
					if (prevItem != null) {
						userQueueItem.position = prevItem.position;
						userQueueItem.userID = prevItem.userID;
					}
					_userQueueItems[userQueueItem.userID] = userQueueItem;	//save it!				
				}
			} // else ignore
			
			dispatchEvent(new UserQueueEvent(UserQueueEvent.ITEM_UPDATE, userQueueItem.userID));
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			var theItem:MessageItem = p_evt.item;
			
			if (p_evt.nodeName == NODENAME_QUEUE) {
				//a user left, delete it from the table
				delete _userQueueItems[theItem.publisherID];
				dispatchEvent(new UserQueueEvent(UserQueueEvent.ITEM_UPDATE, theItem.publisherID));
			}
		}
		
		/**
		 * @private
		 */
		protected function onNodeDelete(p_evt:CollectionNodeEvent):void
		{
			//clear local model
			_userQueueItems = new Dictionary();
			
			var e:UserQueueEvent = new UserQueueEvent(UserQueueEvent.CLEAR);
			e.reason = "TODO";	//TODO: add reason
			dispatchEvent(e);
		}

		/**
		 * @private
		 */
		protected function myTrace(p_msg:String):void
		{
			var e:UserQueueEvent = new UserQueueEvent(UserQueueEvent.LOG);
			e.reason = p_msg;
			dispatchEvent(e);
			DebugUtil.debugTrace("#UserQueue "+ sharedID+"# "+p_msg);
		}
		
		
		/**
		 * @private
		 * The name of the collectionNode used by this UserQueue.
		 */
		public function get nodeCollectionName():String
		{
			return sharedID + "_UserQueue";
		}
		
		
		/**
		 * @private
		 * Cleans up the user Queue Items from dictionary
		 */
		public function cleanAllQueueItems():void
		{
			_userQueueItems = null ;
			_userQueueItems = new Dictionary();
		}
		

	}
}
