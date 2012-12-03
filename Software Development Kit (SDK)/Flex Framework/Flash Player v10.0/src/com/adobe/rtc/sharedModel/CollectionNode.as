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
	import com.adobe.rtc.core.messaging_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.NodeDescriptor;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.messaging.errors.MessageNodeError;
	import com.adobe.rtc.messaging.manager.MessageManager;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	
	import flash.events.EventDispatcher;

	use namespace messaging_internal;
	


		/**
		 * Dispatched when <b>the current user's</b> role changes for the <code>
		 * collectionNode</code> as a whole and <b>not</b> nodes within it. This 
		 * event is more frequently useful than its more general counterpart, 
		 * <code>userRoleChange</code>.
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


		/**
		 * Dispatched when the collection <b>or a node within the collection</b>, has 
		 * a change in roles <b>for any user</b>. This event is less frequently used 
		 * than its more useful counterpart, <code>myRoleChange</code>. In general, 
		 * this event is only useful for situations in which the individual nodes have 
		 * roles assigned to them and where the developer cares about the roles of users 
		 * other than the current user for these nodes.
		 * 
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


		/**
		 * Dispatched when a node within the collection has a change in its configuration
		 * (typically, its access-model). 
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="configurationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]


		/**
		 * Dispatched when a node within the collection receives an item.
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="itemReceive", type="com.adobe.rtc.events.CollectionNodeEvent")]

		/**
		 * Dispatched when a node within the collection retracts an item.
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="itemRetract", type="com.adobe.rtc.events.CollectionNodeEvent")]

		/**
		 * Dispatched when a node is created within the collection.
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="nodeCreate", type="com.adobe.rtc.events.CollectionNodeEvent")]


		/**
		 * Dispatched when a node is deleted within the collection. 
		 *
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="nodeDelete", type="com.adobe.rtc.events.CollectionNodeEvent")]


		/**
		 * Dispatched when the collection has fully received all nodes and items stored 
		 * up until the present time thereby becoming synchronized as well as when the 
		 * collection becomes disconnected from (and thus "out of sync" with) the room's 
		 * messaging bus.
		 * 
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
		/**
		 * Dispatched when the collection has been disconnected from the server and is in 
		 * the process of reconnecting and re-subscribing. A typical response to this 
		 * event would be to reinitialize any shared parts of a model which depend on 
		 * this collectionNode as the items will be re-received from the server. 
		 * <code>SYNCHRONIZATION_CHANGE</code> will fire once this process completes.
		 * 
		 * @eventType com.adobe.rtc.events.CollectionNodeEvent
		 */
		[Event(name="reconnect", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * CollectionNode is the foundation class for building shared models requiring publish
	 * and subscribe messaging. All shared classes including the sharedModel, sharedManager, 
	 * and many pods use CollectionNodes in order to manage  messages, permissions, and roles.
	 * <p>
	 * At its core, a room can be logically seen as a group of CollectionNodes. For example, 
	 * one CollectionNode is used in a chat pod, one within UserManager, and so on. CollectionNodes, 
	 * in turn, are made up of nodes which can be thought of as permission-managed channels 
	 * through which MessageItems are sent and received. Each node has its own NodeConfiguration 
	 * which determines the permissions and storage policies sent through it.
	 * </p>
	 * <p>
	 * CollectionNode is the main component class developers will create and interact with in order
	 * accomplish the following: 
	 * <ul>
	 * 	<li>Create message nodes.</li>
	 *  <li>Publish MessageItems to those nodes.</li>
	 *  <li>Subscribe to nodes.</li>
	 *  <li>Configure nodes.</li>
	 *  <li>Manage collection and node user roles.</li>
	 * </ul>
	 * Only users with a role of <code>UserRoles.OWNER</code> may create and configure collectionNodes. 
	 * Users of <code>UserRoles.PUBLISHER</code> can typically publish MessageItems, and 
	 * <code>UserRoles.VIEWER</code> may subscribe and receive messages. As such, it's typically 
	 * the case that an owner set up the required CollectionNodes in a room before publishers may 
	 * publish or viewers may receive MessageItems.
	 * <p>
	 * CollectionNodes do not store the items which pass through them even if they are stored on 
	 * the services. Developers are advised to listen to the <code>ITEM_RECEIVE</code> event and 
	 * store details as needed in their own models.
	 * 
	 * @see LCCS Developer Guide
	 * @see com.adobe.rtc.messaging.NodeConfiguration
	 * @see com.adobe.rtc.messaging.MessageItem
	 * @see com.adobe.rtc.messaging.UserRoles 
	 */	
   public class  CollectionNode extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * When clearing a role at the CollectionNode or the node level, <code>NO_EXPLICIT_ROLE</code> 
		 * is sent to the service to clear that role.
		 */
		public static const NO_EXPLICIT_ROLE:int = -999;
		
		/**
		* @private
		*/
		protected var _sharedID:String;
		/**
		* @private
		*/
		protected var _messageNodes:Object; // table of the types of messages we've seen on this collection
		/**
		* @private
		*/
		protected var _isSynchronized:Boolean=false;

		/**
		* @private
		*/
		protected var _messageManager:MessageManager;
		
		/**
		* @private
		*/
		protected var _userManager:UserManager;
		
		/**
		* @private
		*/		
		protected var _pendingNodes:Object;
		/**
		* @private
		*/		
		protected var _subscribed:Boolean=false;
		
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		
		
		/**
		 * The complete set of roles for this collection described as {userID:role} pairs.
		*/
		public var userRoles:Object;

		/*
	     * Constructor.
	     *
	     * @param p_collectionName A unique collection node name which acts as the address 
		 * of the collection within a room.
	     * 
	     */
		public function CollectionNode()
		{
			
			_messageNodes = new Object();
			userRoles = new Object();			
			_pendingNodes = new Object();
		}

		/**
		 * The <code>sharedID</code> is the logical address of this collection 
		 * within the room and must therefore be unique from all other CollectionNode names. 
		 */
		public function set sharedID(p_collectionName:String):void
		{
			if (_sharedID!=null) {
				throw new MessageNodeError(MessageNodeError.CANNOT_CHANGE_COLLECTIONNAME);
			} else {
				_sharedID=p_collectionName;
			}
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
		 * @private
		 * Disposes all listeners to the network and framework classes. 
		 * Recommended for proper garbage collection of the component.
		 */
		public function close():void
		{
			unsubscribe();
			//NO -OP
		}
		
		
		[Bindable (event="nodeCreate")]
		[Bindable (event="nodeDelete")]
		/**
		 * Returns the names of all the nodes within this collection.
		 *
		 * @return Array
		 */				
		public function get nodeNames():Array
		{
			// TODO : nigel : lazy building is bad!
			var returnArray:Array = new Array();
			for (var i:String in _messageNodes) {
				returnArray.push(i);
			}
			returnArray.sort();
			return returnArray;
		}


		/**
		 * Determines whether or not the collection is "up to state" with all previously 
		 * stored items in its nodes. Once a CollectionNode has successfully connected 
		 * to the service and retrieved all its nodes and messageItems, it is considered 
		 * synchronized. If the connection is lost, it becomes unsynchronized until it 
		 * fully reconnects and re-retrieves its state.
		 * 
		 * @return Boolean 
		 */				
		public function get isSynchronized():Boolean
		{
			return _isSynchronized;
		}
		
		/**
		 * Determines whether or not the collection is empty, that is, having no nodes
		 * @return Boolean
		 */
		public function get isEmpty():Boolean
		{
			//can't use .length
			for(var i:String in _messageNodes) {
				return false;
			}
			return true;		
		}

		/**
		* <code>subscribe()</code> causes the CollectionNode to subscribe to the logical 
		* destination provided by <code>collectionName</code>. If there is no such 
		* destination on the service and the current user has an owner role, a new 
		* CollectionNode is created and stored on the service with the given <code>
		* collectionName</code>.
		* When subscription is successful or a new CollectionNode is created, the collection:
		* <ul>
		* <li>Discovers all the accessible nodes for this collection along with 
		* their configurations and roles.</li>
		* <li>Subscribes to all nodes allowed within the collection.</li>																</li>
		* <li>Retrievs all stored items for all nodes within it and broadcasts <code>
		* ITEM_RECEIVE</code> events for each.</li>
		* <li>Fires a <code>COLLECTION_SYNCHRONIZE</code> event once the collection 
		* has retrieved the data above.</li>
		* </ul>
		*/		
		public function subscribe():void
		{
			if (!_connectSession.userManager) {
				throw new Error("CollectionNode.subscribe - attempt to subscribe before a session is instantiated.");
			}
			_subscribed = true;
			_userManager = _connectSession.userManager;
			_messageManager = _connectSession.sessionInternals.messaging_internal::messageManager;
			_messageManager.subscribeCollection(this);
		}

		/**
		 * Disconnects this CollectionNode from the server. Typically used for garbage collection. 
		 * If a node is subscribed but a network or services glitch causes it to disconnect, 
		 * the CollectionNode will attempt to reconnect automatically.
		 */
		public function unsubscribe():void
		{
			_subscribed = false;
			_isSynchronized = false;
			_messageManager.unsubscribeCollection(this);
		}
				
		/**
		 * Creates a new node in this collection; they are either optionally configured when 
		 * created or accept the default configuration. Note that only users with and owner role 
		 * may create or configure nodes on a CollectionNode.
		 * 
		 * @param p_nodeName The name for the new node which must be unique within the CollectionNode.
		 * @param p_nodeConfiguration Optionally, the configuration for this node. If none is supplied, 
		 * <code>NodeConfiguration.defaultConfiguration</code> is used.
		 */
		public function createNode(p_nodeName:String, p_nodeConfiguration:NodeConfiguration=null):void
		{
			if (!_isSynchronized) {
				//throw an exception, you have to wake until your Collection/Node is synched to push to it
				throw new MessageNodeError(MessageNodeError.NODE_NOT_SYNCHRONIZED);
				return;
			} 

			_pendingNodes[p_nodeName] = true;
			
			// pass this request to the messageManager, and wait for a response
			_messageManager.createNode(sharedID, p_nodeName, p_nodeConfiguration);
		}
		
		/**
		 * Configures a node in this collection and replaces the existing NodeConfiguration. 
		 * Only users with an owner role may change a node's configuration.
		 * 
		 * @param p_nodeName The name of the node to configure.
		 * @param p_nodeConfiguration The new NodeConfiguration for the node.
		 */
		public function setNodeConfiguration(p_nodeName:String, p_nodeConfiguration:NodeConfiguration):void
		{
			// pass this request to the messageManager, and wait for a response
			_messageManager.configureNode(sharedID, p_nodeName, p_nodeConfiguration);
		}
		
		
		/**
		 * Returns the NodeConfiguration options for a given node in this CollectionNode.
		 * 
		 * @param p_nodeName The name of the desired node.
		 */
		public function getNodeConfiguration(p_nodeName:String):NodeConfiguration
		{
			var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
			if (nodeDesc!=null) {
				if (nodeDesc.configuration!=null) {
					return nodeDesc.configuration;
				} else {
					return new NodeConfiguration();
				}
			} else {
				throw new MessageNodeError(MessageNodeError.NO_SUCH_NODE);
				return;
			}
		}
		
		/**
		 * Removes the given node from this collection. Only users with an owner role may
		 * change a node's configuration.
		 * 
		 * @param p_nodeName
		 */		
		public function removeNode(p_nodeName:String):void
		{
			// pass this request to the messageManager, and wait for a response
			_messageManager.removeNode(sharedID, p_nodeName);			
		}
		
		/**
		 * Gives a specific user a specific role level for this entire collection or optionally 
		 * a specified node within it. Roles cascade down from the root level of the room to 
		 * the CollectionNode level and then to the node level. The following override rules apply: 
		 * <ul>
		 * <li>Setting a role on a collection node overrides the role at the root for that collection node.
		 * <li>Setting a role on a node overrides both the role at the root and the collection node for that node.
		 * </ul>
		 * 
		 * @param p_userID The desired user's <code>userID</code>.
		 * @param p_role The users new role.
		 * @param p_nodeName [Optional, defaults to null] The UserRole for the entire CollectionNode
		 */
		public function setUserRole(p_userID:String, p_role:int, p_nodeName:String=null):void
		{
			if (p_nodeName==null) {
				_messageManager.setUserRole(p_userID, p_role, sharedID);
			} else {
				_messageManager.setUserRole(p_userID, p_role, sharedID, p_nodeName);
			}
		}

		/**
		 * Gets the role of a given user for this collection or a node within it. Note that this 
		 * function discovers the implicit or cascading role of the user at this location; that is, 
		 * if no explicit role is specified for a node, the user's role on the parent collection's 
		 * is queried. If the user's role isn't explicitly defined on the collection, the root role 
		 * is queried.
		 * 
		 * @param p_userID The user whose role is being queried.
		 * @param p_nodeName [Optional, defaults to null]. The name of the node to check for roles. 
		 * If null, check the entire CollectionNode.
		 * 
		 * @return the level of role of the specified user
		 * 
		 */
		public function getUserRole(p_userID:String, p_nodeName:String=null):int
		{
			if (!isSynchronized) {
				return -1;
			}
			if (p_nodeName==null) {
				if (userRoles[p_userID]==null) {
					return getRootUserRole(p_userID);
				}
				return userRoles[p_userID];
			} else {
				var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
				if (nodeDesc==null || nodeDesc.userRoles==null || 	nodeDesc.userRoles[p_userID]==null) {
					// no role set at the node level; get the collection level
					return getUserRole(p_userID);
				}
				return nodeDesc.userRoles[p_userID];
			}
		}

		/**
		 * Gets the roles explicitly set for a node within this collection. This only returns the 
		 * explicit roles set on the particular node and doesn't look up the cascading roles from
		 * the root as <code>getUserRole()</code> does.
		 * 
		 * @param p_userID The user whose role is being queried.
		 * @param p_nodeName The name of the node to whose roles are desired. If null, returns the 
		 * set of user roles at the collection node level.
		 * 
		 * @return An object table of <code>{userID:role}</code> tuples.
		 * 
		 */
		public function getExplicitUserRoles(p_nodeName:String=null):Object
		{
			if (p_nodeName==null) {
				return userRoles;
			} else {
				var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
				if (nodeDesc!=null) {
					return nodeDesc.userRoles;
				}
			}
			return null;
		}


		/**
		 * Gets the role of a given user for a node within this collection or the 
		 * collection itself. This only returns the explicit roles set on the 
		 * particular node and doesn't look up the cascading roles from the root 
		 * as <code>getUserRole()</code> does.
		 * 
		 * @param p_userID The user whose role is being queried.
		 * @param p_nodeName The name of the node to whose roles are desired. 
		 * Null for the collection itself.
		 * 
		 * @return The requested role. If the role for the user isn't explicitly 
		 * set, it returns <code>NO_EXPLICIT_ROLE</code>.
		 * 
		 */
		public function getExplicitUserRole(p_userID:String, p_nodeName:String=null):int
		{
			if (p_nodeName==null) {
				if (userRoles[p_userID]!=null) {
					return userRoles[p_userID] as int;
				}
			} else {
				var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
				if (nodeDesc!=null && nodeDesc.userRoles!=null) {
					if (nodeDesc.userRoles[p_userID]!=null) {
						return nodeDesc.userRoles[p_userID] as int;
					}
				}
			}
			return NO_EXPLICIT_ROLE;
		}


		/**
		 * Determines whether a given user is allowed to subscribe to this entire collection 
		 * or a node within it.
		 * 
		 * @param p_userID The ID of the user whose role is being queried.
		 * @param p_nodeName [Optional, null if empty]. The node to check. If null, it 
		 * checks the entire CollectionNode.
		 */
		public function canUserSubscribe(p_userID:String, p_nodeName:String=null):Boolean
		{
			if (p_nodeName==null) {
				return (getUserRole(p_userID)>=UserRoles.VIEWER);
			} else {
				var roleNeededToSubscribe:int = getNodeConfiguration(p_nodeName).accessModel;
				return (getUserRole(p_userID, p_nodeName)>=roleNeededToSubscribe);
			}
		}


		
		/**
		 * Determines whether a given user is allowed to publish to a given node in 
		 * this collection.
		 * 
		 * @param p_userID The ID of the user whose role (and therefore permissions) is being queried.
		 * @param p_nodeName The name of the desired node. 
		 * 
		 * @return 
		 * 
		 */		
		public function canUserPublish(p_userID:String, p_nodeName:String):Boolean
		{
			if (!isNodeDefined(p_nodeName)) {
				return (getUserRole(p_userID, p_nodeName)>=UserRoles.OWNER);
			}
			var roleNeededToPublish:int = getNodeConfiguration(p_nodeName).publishModel;
			return (getUserRole(p_userID, p_nodeName)>=roleNeededToPublish);
		}

		/**
		 * Determines whether a given user is allowed to configue this collection. 
		 * 
		 * @param p_userID The ID of the user whose role (and therefore permissions) is being queried.
		 * @param p_nodeName Optionally, the name of the requested node. Defaults to the collection.
		 *
		 * @return 
		 * 
		 */		
		public function canUserConfigure(p_userID:String, p_nodeName:String=null):Boolean
		{
			if (p_nodeName==null) {
				var a:int = getUserRole(p_userID);
				return (getUserRole(p_userID)>=100);
			} else {
				return (canUserPublish(p_userID, p_nodeName) && getUserRole(p_userID, p_nodeName)>=100);
			}
		}

		/**
		 * Publishes a MessageItem. The MessageItem itself will have a <code>nodeName</code> declared.
		 * <p>
		 * <code>p_overWrite</code> provides users with control over whether edits take 
		 * precedence over delete actions. It is essentially a lock that assures an item can
		 * only be published if it exists. The general rule of thumb is that if you 
		 * want to add a new item, use the <code class="property">p_overWrite</code> default flag of false. 
		 * If you're editing an item that may be retracted, then set the flag according to 
		 * your preference. 
		 * <p>
		 * For example, consider a whiteboard, where each shape is represented by one or more items. 
		 * For a dynamic system like a whiteboard, shapes can be modified and retracted.
		 * <code>p_overwrite</code> makes sure that if you modify a shape but a message race causes 
		 * that item to be deleted before the edit is committed, the delete takes precedence over 
		 * the edit. Since the edit is meaningless on a non-existent item, that action is not 
		 * accepted; otherwise, the edit would cause the shape to exist again.
		 * 
		 * @param p_messageItem The MessageItem to publish.
		 * @param p_overWrite True if this call is overwriting an existing item. False (the default) 
		 * if it is not.
		 */
		public function publishItem(p_messageItem:MessageItem, p_overWrite:Boolean=false):void
		{
			if (!_isSynchronized) {
				//Throw an exception if the collection or node is not synchronized with the server. 
				//The client should wait before pushing the new messageItem.
				throw new MessageNodeError(MessageNodeError.NODE_NOT_SYNCHRONIZED);
				return;
			}
			
			if (!isNodeDefined(p_messageItem.nodeName) && _pendingNodes[p_messageItem.nodeName]==null) {
				// Define the message on the server since it does not yet exist.
				_messageManager.createNode(sharedID, p_messageItem.nodeName);
			}
			p_messageItem.collectionName = sharedID;
			_messageManager.publishItem(sharedID, p_messageItem.nodeName, p_messageItem, p_overWrite);
		}
	
		/**
		 * Retracts the indicated item. This removes the item from storage on the server and 
		 * sends an <code>itemRetract</code> event to all users.
		 * 
		 * @param p_nodeName The <code>nodeName</code> of the <code>messageItem</code> to retract.
		 * @param p_itemID The <code>itemID</code> of the <code>messageItem</code> (stored on the server) 
		 * to retract.
		 * 
		 */
		public function retractItem(p_nodeName:String, p_itemID:String=null):void
		{
			if (!_isSynchronized) {
				//throw an exception, you have to wake until your Collection/Node is synched to push to it
				throw new MessageNodeError(MessageNodeError.NODE_NOT_SYNCHRONIZED);
				return;
			}
			
			_messageManager.retractItem(sharedID, p_nodeName, p_itemID);
		}	
		
		
		/**
		 * Fetches the set of items specified by itemIDs from a given node. This will result in one <code>ITEM_RECEIVE</code> event
		 * per item retrieved, for the current user. Attempts to fetch items which don't exist fails silently.
		 * @param p_nodeName The name of the node from which to fetch the items.
		 * @param p_itemIDs An array of <code>itemID<code>s (Strings) to fetch from the service.
		 * 
		 */
		public function fetchItems(p_nodeName:String, p_itemIDs:Array):void
		{
			if (!_isSynchronized) {
				//throw an exception, you have to wake until your Collection/Node is synched to receive from it
				throw new MessageNodeError(MessageNodeError.NODE_NOT_SYNCHRONIZED);
				return;
			}
			_messageManager.fetchItems(sharedID, p_nodeName, p_itemIDs);
		}
	
		/**
		 * Whether the given node exists in this CollectionNode.
		 * 
		 * @param p_nodeName the name of desired node 
		 * @return 
		 * 
		 */
		public function isNodeDefined(p_nodeName:String):Boolean
		{
			return (_messageNodes[p_nodeName]!=null);
		}

		
		//:::  INTERNAL METHODS for the MessageManager to push to the CollectionNode


		/**
		 * @private
		 * When a collection is completely synced up, the MessageManager lets it know through this method
		 */		
		messaging_internal function setIsSynchronized(p_isSynched:Boolean):void
		{
			if (_isSynchronized != p_isSynched) {
				_isSynchronized = p_isSynched;
				dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.SYNCHRONIZATION_CHANGE));
			}
		}

		/**
		 * @private
		 */
		messaging_internal function receiveReconnect():void
		{
			//clean up
			_messageNodes = new Object();
			userRoles = new Object();			
			_pendingNodes = new Object();
			if (_subscribed) {
				_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, onReconnect);
			}
		}
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:SessionEvent):void
		{
			_connectSession.removeEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, onReconnect);
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.RECONNECT));
			subscribe();
		}
		
		/** 
		 * @private
		 * When a new node in this collection is added, the MessageManager sends it through this method
		 */		
		messaging_internal function receiveNode(p_nodeName:String, p_nodeConfiguration:NodeConfiguration=null):void
		{
			var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] = new NodeDescriptor();
			nodeDesc.name = p_nodeName;
			if (p_nodeConfiguration!=null) {
				nodeDesc.configuration = p_nodeConfiguration;
			}
			delete _pendingNodes[p_nodeName];
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.NODE_CREATE, p_nodeName));
		}
		

		/**
		 * @private
		 * When a node in this collection is configured, the MessageManager sends it through this method
		 */		
		messaging_internal function receiveNodeConfiguration(p_nodeName:String, p_nodeConfiguration:NodeConfiguration):void
		{
			var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
			if (nodeDesc!=null) {
				nodeDesc.configuration = p_nodeConfiguration;
				dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.CONFIGURATION_CHANGE, p_nodeName));
			} else {
				throw new MessageNodeError(MessageNodeError.NO_SUCH_NODE);
			}
		}
		
		/**
		 * @private
		 * When a node in this collection is deleted, the MessageManager sends it through this method
		 */		
		messaging_internal function receiveNodeDeletion(p_nodeName:String):void
		{
			delete _messageNodes[p_nodeName];
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.NODE_DELETE, p_nodeName));
		}
		
		/**
		 * @private
		 * When an item is received from a node in this collection, the MessageManager sends it through this method
		 */
		messaging_internal function receiveItem(p_item:MessageItem):void
		{
			var evt:CollectionNodeEvent = new CollectionNodeEvent(CollectionNodeEvent.ITEM_RECEIVE, p_item.nodeName);
			evt.item = p_item;
			dispatchEvent(evt);
		}
		
		/**
		 * @private
		 * When an item is retracted from a node in this collection, the MessageManager sends it through this method
		 */
		messaging_internal function receiveItemRetraction(p_nodeName:String, p_itemVO:Object):void
		{
			var evt:CollectionNodeEvent = new CollectionNodeEvent(CollectionNodeEvent.ITEM_RETRACT, p_nodeName);
			var item:MessageItem = new MessageItem();
			item.readValueObject(p_itemVO);
			evt.item = item;
			dispatchEvent(evt);
		}
		
		/**
		 * @private
		 * When an role change occurs explicitly for the collection or a node within it, 
		 * the MessageManager sends it through this method. 
		 */
		messaging_internal function receiveUserRole(p_userID:String, p_role:int, p_nodeName:String=null):void
		{
			var evt:CollectionNodeEvent;
			if (p_nodeName==null) {
				
				if (p_role==CollectionNode.NO_EXPLICIT_ROLE) {
					delete userRoles[p_userID];
				} else {
					//the role of the collectionNode as a whole has been explicitly set
					userRoles[p_userID] = p_role;
				}
				receiveCascadingUserRole(p_userID);
				
			} else {
				var nodeDesc:NodeDescriptor = _messageNodes[p_nodeName] as NodeDescriptor;
				if (nodeDesc.userRoles==null) {
					nodeDesc.userRoles = new Object();
				}
				if (p_role==CollectionNode.NO_EXPLICIT_ROLE) {
					delete nodeDesc.userRoles[p_userID];
				} else {
					nodeDesc.userRoles[p_userID] = p_role;
				}
				evt = new CollectionNodeEvent(CollectionNodeEvent.USER_ROLE_CHANGE, p_nodeName);
				evt.userID = p_userID;
				dispatchEvent(evt);
			}
		}


		/**
		 * @private
		 * When a role change happens at the collection node level or higher, the change 
		 * cascades to its sub-nodes. Depending on the user and the nature of the role change, 
		 * the following occurs: 
		 * <ul>
		 *   <li>Firing a role change event for the collectionNode.</li>
		 *   <li>Firing a <code>myRoleChange</code> event if the user with the changing role is the current user. </li>
		 *   <li>Firing a role change event for each non-explicitly roled sub-node.</li> 
		 *   <li>If the role has changed such that the current user can't even see the node any longer, removing the nodes.</li>
		 * </ul>
		 * Note that the actual role change bookkeeping should have already occurred somewhere 
		 * up the cascade chain before this method is called.
		 * 
		 * @param p_userID The ID of the user whose role is changing.
		 */
		messaging_internal function receiveCascadingUserRole(p_userID:String):void
		{
			var evt:CollectionNodeEvent = new CollectionNodeEvent(CollectionNodeEvent.USER_ROLE_CHANGE);
			evt.userID = p_userID;
			dispatchEvent(evt);
			
			if (p_userID==_userManager.myUserID) {
				dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.MY_ROLE_CHANGE));
			}
			
			var names:Array = nodeNames;
			var l:int = names.length;
			var nodeName:String;
			for (var i:int=0; i < l; i++) {
				nodeName = names[i] as String;
				if (getExplicitUserRole(p_userID, nodeName)==CollectionNode.NO_EXPLICIT_ROLE) {
					// this node had no explicit role of its own, meaning it will inherit from the collectionNode. since that changed, they need to fire change events
					evt = new CollectionNodeEvent(CollectionNodeEvent.USER_ROLE_CHANGE);
					evt.userID = p_userID;
					evt.nodeName = nodeName;
					dispatchEvent(evt);

					if (p_userID==_userManager.myUserID) {
						// the current user might not be able to see some nodes anymore
						if (!canUserPublish(_userManager.myUserID, nodeName) && !canUserSubscribe(_userManager.myUserID, nodeName)) {
							receiveNodeDeletion(nodeName);
						}
					}
				}
			}
		}


		/**
		 * @private
		 * Finds the room-level userRole for a user
		 */
		protected function getRootUserRole(p_userID:String):int
		{
			return _messageManager.getRootUserRole(p_userID);
		}


		
	}
}