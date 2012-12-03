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
package com.adobe.rtc.messaging.manager
{
	import com.adobe.rtc.core.messaging_internal;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.messaging.errors.MessageNodeError;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.managers.SessionManagerBase;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.On2ParametersDescriptor;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.util.RootCollectionNode;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.*;
	
	use namespace messaging_internal;

	/**
	 * @private
	 * MessageManager is an implementation of the set of messaging primitives required for the foundations of a LCCS app. 
	 * 
	 * MessageManager is a singleton whose job is to manage the set of CollectionNode components which are instantiated throughout a LCCS
	 * application. Its messaging_internal methods accept commands from these CollectionNodes, and pass them along to the SessionManager. Its
	 * session_internal methods accept callbacks from the SessionManager. It has very little other outside communication; devs shouldn't need
	 * to interact with it.
	 *
	 * @see com.adobe.rtc.messaging.CollectionNode CollectionNode
	 * @see com.adobe.rtc.session.managers.SessionManagerBase SessionManagerBase
	 */
   public class  MessageManager extends EventDispatcher implements ISessionSubscriber
	{
		/**
		* @private - Book-keeping Object table, hashed by {collectionName:collectionReference}.
		*/		
		protected var _collectionNodes:Object;

		/**
		* @private - Book-keeping Object for the set of collectionNames.
		*/
		protected var _collectionNames:Object;

		/**
		 * @private
		 */
		protected var _rootCollectionNode:RootCollectionNode;
		
		/**
		* @private
		* A reference to the userManager, to allow the manager to validate calls against the current user.
		*/
		protected var _userManager:UserManager;

		/**
		* @private
		* An reference to the sessionManager, which the MessageManager will pass RPCs through.
		*/
		protected var _sessionManager:SessionManagerBase;
		
		/**
		 * @private 
		 */		
		protected var _pendingSubscriptions:Array = new Array();

		/**
		* @private
		* Table used to bookkeep redundant nodeReceive messages from the server
		*/
		protected var _nodesAlreadyHere:Object;
		
		/**
		* @private - the roles of every user, at the root
		*/
		protected var _rootUserRoles:Object;

		/**
		 * @private - the connectSession to which this manager belongs 
		 */
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		/**
		 * @private
		 */
		protected var _waitingUserDescriptorList:Object = new Object();


		public function MessageManager()
		{
			_collectionNodes = new Object();
			_rootUserRoles = new Object();
		}
		
		public function get sharedID():String
		{
			return "MessageManager";
		}
		
		public function set sharedID(p_id:String):void
		{
			// no-op
		}
		
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		public function set connectSession(p_connectSession:IConnectSession):void
		{
			_connectSession = p_connectSession;
		}
		
		/**
		 * Returns true/ false if not synchronized...
		 */
		public function get isSynchronized():Boolean
		{
			if ( !_connectSession ) {
				return false ;
			}
			
			return _connectSession.isSynchronized ;
		}
		
		
		public function close():void
		{
			if (_rootCollectionNode) {
				_rootCollectionNode.messaging_internal::setIsSynchronized(false);
			}
			
			//notify all collections
			for each (var collectionNode:CollectionNode in _collectionNodes) {
				collectionNode.messaging_internal::setIsSynchronized(false);
			}				
			_collectionNodes = new Object();
			_rootUserRoles = new Object();
			_pendingSubscriptions = new Array();
			if (_rootCollectionNode) {
				_rootCollectionNode.close();
			}
		}
		
		/**
		* @private - causes the messageManager to fetch the root level messaging details for this room - 
		* namely root user roles, and collectionNode names. Also causes the manager to be added to the subscriber 
		* list for these root details changing.
		*/		
		public function subscribe():void
		{
			if (_sessionManager)	//this is a reconnect, must clean up local storage
			{
				//clean up
				_sessionManager.removeEventListener(SessionEvent.DISCONNECT, onDisconnect);
				_userManager.removeEventListener(UserEvent.USER_REMOVE, onUserRemove);
				_userManager.removeEventListener(UserEvent.USER_CREATE,onUserCreate);
				
				for each (var cNode:CollectionNode in _collectionNodes) {
					cNode.messaging_internal::receiveReconnect();	
				}
				_collectionNodes = new Object();
				_rootUserRoles = new Object();				
			}
			_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, flushPendingSubscriptions);
			_userManager = _connectSession.userManager;
			_userManager.addEventListener(UserEvent.USER_REMOVE, onUserRemove);
			_userManager.addEventListener(UserEvent.USER_CREATE,onUserCreate);
			_sessionManager = _connectSession.sessionInternals.session_internal::sessionManager;
			_sessionManager.addEventListener(SessionEvent.DISCONNECT, onDisconnect);
			_sessionManager.session_internal::subscribeCollection();
		}
		
		/**
		 * 
		 * @private
		 * A CollectionNode's internal method for registering itself to the Manager, and 
		 * kicking off discovery of nodes, configurations, roles, and stored items. Once this process ends,
		 * we tell the collectionNode it's synchronized.
		 */		
		messaging_internal function subscribeCollection(p_collectionNode:CollectionNode, p_nodeNames:Array=null):void
		{
			if (_sessionManager) {
				if (_userManager.myUserRole<UserRoles.OWNER) {
					// I might be attempting to create a new node
					if (_collectionNames[p_collectionNode.sharedID]!=true) {
						// you are, but shouldn't be able to 
						throw new Error("Error - insufficient permissions to create a new CollectionNode. You must be an OWNER of " + 
								"the room to add new multi-user features to it. Log in with developer credentials in order to do so.");
						return;
					}
				}
				_collectionNodes[p_collectionNode.sharedID] = p_collectionNode;
				
				_sessionManager.session_internal::subscribeCollection(p_collectionNode.sharedID, p_nodeNames);
			} else {
				_pendingSubscriptions.push({collectionNode:p_collectionNode, nodeNames:p_nodeNames});
			}
		}

		/**
		 * 
		 * @private
		 * A CollectionNode's internal method for registering itself to the Manager, and 
		 * kicking off discovery of nodes, configurations, roles, and stored items. Once this process ends,
		 * we tell the collectionNode it's synchronized.
		 */		
		messaging_internal function unsubscribeCollection(p_collectionNode:CollectionNode):void
		{
			if (_sessionManager.session_internal::isSynchronized) {
				_sessionManager.session_internal::unsubscribeCollection(p_collectionNode.sharedID);
			}
			delete _collectionNodes[p_collectionNode.sharedID];
		}
		
		/**
		* @private
		* assigns a rootCollection (a proxy for receiving root-level events, used in messageExplorer)
		*/
		messaging_internal function createRootCollection(p_rootCollection:RootCollectionNode):void
		{
			_rootCollectionNode = p_rootCollection;
			for (var collectionName:String in _collectionNames) {
				// if a _rootCollectionNode is hooked up, let it know
				_rootCollectionNode.receiveNode(collectionName);
			}
			_rootCollectionNode.setIsSynchronized(isSynchronized);
		}
		
		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function createNode(p_collectionName:String, p_nodeName:String=null, p_nodeConfiguration:NodeConfiguration=null):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (collectionNode == null) {
				//trying to create a collection
				if (_rootCollectionNode && !_rootCollectionNode.canUserConfigure(_userManager.myUserID)) {
					throw new Error("MessageManager.createNode : insufficient permissions to create node");
					return;
				}
			} else if (!collectionNode.canUserConfigure(_userManager.myUserID)) {
				throw new Error("MessageManager.createNode : insufficient permissions to create node");
				return;
			}
			var nodeConfigVO:Object;
			if (p_nodeConfiguration!=null) {
				nodeConfigVO = p_nodeConfiguration.createValueObject();
			}
			_sessionManager.session_internal::createNode(p_collectionName, p_nodeName, nodeConfigVO);
		}

		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function configureNode(p_collectionName:String, p_nodeName:String, p_nodeConfiguration:NodeConfiguration):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (!collectionNode.canUserConfigure(_userManager.myUserID, p_nodeName)) {
				throw new Error("MessageManager.configureNode : insufficient permissions to configure node");
				return;
			}
			_sessionManager.session_internal::configureNode(p_collectionName, p_nodeName, p_nodeConfiguration.createValueObject());
		}
		
		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function removeNode(p_collectionName:String, p_nodeName:String=null):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (collectionNode==null) {
				if (!_rootCollectionNode || _userManager.myUserRole!=UserRoles.OWNER) {
					// if we've never seen the collection, only hosts can try to delete it, and only with a rootCollectionNode
					throw new Error("MessageManager.removeNode : insufficient permissions to remove node");
					return;
				}
			} else if (!collectionNode.canUserConfigure(_userManager.myUserID)) {
				throw new Error("MessageManager.removeNode : insufficient permissions to remove node");
				return;
			}
			_sessionManager.session_internal::removeNode(p_collectionName, p_nodeName);
		}

		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function publishItem(p_collectionName:String, p_nodeName:String, p_item:MessageItem, p_overWrite:Boolean=false):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			var cNode:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			
			if (cNode.isNodeDefined(p_nodeName)) {
				var nodeConf:NodeConfiguration = cNode.getNodeConfiguration(p_nodeName);				
				if (!cNode.canUserPublish(_userManager.myUserID, p_nodeName)) {
					throw new Error("MessageManager.publishItem : insufficient permissions to publish to node " + p_nodeName);
					return;
				}
				
				if (p_item.associatedUserID!=null && p_item.associatedUserID != _userManager.myUserID && !cNode.canUserConfigure(_userManager.myUserID)) {
					throw new Error("MessageManager.publishItem : insufficient permissions to publish an item associated with someone else");
					return;
				}

				if ((p_item.recipientID!=null || p_item.recipientIDs!=null) && !nodeConf.allowPrivateMessages) {
					throw new Error("MessageManager.publishItem : cannot publish private messages on a node unless it is configured to allowPrivateMessages");
					return;
				}
				if (nodeConf.itemStorageScheme == NodeConfiguration.STORAGE_SCHEME_SINGLE_ITEM) {
					if (p_item.itemID == null) {
						p_item.itemID = MessageItem.SINGLE_ITEM_ID;
					}
				}
				if (p_item.associatedUserID != null && _userManager.getUserDescriptor(p_item.associatedUserID) == null) {
					if (!_userManager.anonymousPresence) {
						throw new MessageNodeError(MessageNodeError.ASSOCIATEDUSERID_MUST_BE_CONNECTED);
						return;
					} else {
						//Lazysubscription might have been set. So call the function again after 
						//the UserManager fetches the UserDescriptor
						var userObject:Object = new Object();
						userObject.collectionName = p_collectionName;
						userObject.nodeName = p_nodeName;
						userObject.itemObject = p_item.createValueObject();
						userObject.overWrite = p_overWrite;
						_waitingUserDescriptorList[p_item.associatedUserID] = userObject;
						return;
					}
				}
			} else {
				// if you're publishing to a non-existant node, we let you do it only if you're a host.
				// you're only getting the default node config though.
				if (cNode.canUserConfigure(_userManager.myUserID, p_nodeName)) {
					//you're good, the createNode request will have already gone through before publishItem is called
					if (p_item.itemID==null) {
						p_item.itemID = MessageItem.SINGLE_ITEM_ID;
					}
				} else {
					throw new MessageNodeError(MessageNodeError.CANNOT_CREATE_NODE);
					return;
				}
			}
			_sessionManager.session_internal::publishItem(p_collectionName, p_nodeName, p_item.createValueObject(), p_overWrite);
		}
		
		
		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function retractItem(p_collectionName:String, p_nodeName:String, p_itemID:String=null):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (p_itemID==null) {
				if (collectionNode.getNodeConfiguration(p_nodeName).itemStorageScheme==NodeConfiguration.STORAGE_SCHEME_SINGLE_ITEM) {
					// it's ok, lccs chooses for you
					p_itemID = MessageItem.SINGLE_ITEM_ID;
				} else {
					throw new Error("MessageManager.retractItem : must supply an itemID with storage schemes other than STORAGE_SCHEME_SINGLE_ITEM");
					return;
				}
			}
			if (!collectionNode.isNodeDefined(p_nodeName)) {
				throw new Error("MessageManager.retractItem : no such node");
			}
			if (!collectionNode.canUserPublish(_userManager.myUserID, p_nodeName)) {
				throw new Error("MessageManager.retractItem : insufficient permissions to retract item");
				return;
			}
			_sessionManager.session_internal::retractItem(p_collectionName, p_nodeName, p_itemID);
		}

		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function fetchItems(p_collectionName:String, p_nodeName:String, p_itemIDs:Array):void
		{
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (!collectionNode.isNodeDefined(p_nodeName)) {
				throw new Error("MessageManager.fetchItems : no such node");
			}
			if (!collectionNode.canUserSubscribe(_userManager.myUserID, p_nodeName)) {
				throw new Error("MessageManager.fetchItems : insufficient permissions to fetch items");
				return;
			}
			_sessionManager.session_internal::fetchItems(p_collectionName, p_nodeName, p_itemIDs);
		}	
	
		/**
		 * 
		 * @private
		 * The CollectionNode's internal method for submitting this request
		 */
		messaging_internal function setUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			if (p_role>UserRoles.OWNER) {
				throw new Error("MessageManager.setUserRole : can't set a role higher than owner!");
			}
			if (p_collectionName) {
				var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
				if (!(collectionNode.canUserConfigure(_userManager.myUserID) || (p_userID==_userManager.myUserID && _userManager.myUserAffiliation>=UserRoles.OWNER))) {
					throw new Error("MessageManager.setUserRole : insufficient permissions to change user roles");
					return;
				}
			}
			_sessionManager.session_internal::setUserRole(p_userID, p_role, p_collectionName, p_nodeName);
		}
		

		messaging_internal function getRootUserRole(p_userID:String):int
		{
			if (_rootUserRoles[p_userID]!=null) {
				return _rootUserRoles[p_userID];
			}
			var userDesc:UserDescriptor = _userManager.getUserDescriptor(p_userID);
			if (userDesc==null) {
				if (!_userManager.anonymousPresence) {
					throw new Error("MessageManager.getRootUserRole - This user doesn't exist.");
				} else {
					throw new Error("MessageManager.getRootUserRole - UserManager.anonymousPresence is set to true and the user's userDescriptor might not have been fetched, so call this method after the required userDescriptor's are fetched");
				}
			} else {
				return userDesc.affiliation;
			}
		}


		// ::: RECEIVING FUNCTIONS. Route async responses back to the right collections (or to the root itself)

		/**
		 * receiveRootSyncData is the server's response to a request from the MessageManager to subscribe to the root collection.
		 * Its job is to receive the entire list of (first-level) collections in the message bus, as well as any explicitly set user roles 
		 * at the root level.
		 * 
		 * @param p_collectionNames a list of collection names ...
		 */
		messaging_internal function receiveRootSyncData(p_collectionNames:Array, p_userRoles:Object):void
		{
			_collectionNames = new Object();
			for each (var collectionName:String in p_collectionNames) {
				_collectionNames[collectionName] = true;
				// if a _rootCollectionNode is hooked up, let it know
				if (_rootCollectionNode) {
					_rootCollectionNode.receiveNode(collectionName);
				}
			}
			if (p_userRoles) {
				_rootUserRoles = p_userRoles;
			}
			if (_rootCollectionNode) {
				_rootCollectionNode.setIsSynchronized(true);
			}
			dispatchEvent(new CollectionNodeEvent(CollectionNodeEvent.SYNCHRONIZATION_CHANGE));
		}


		/**
		 * receiveNodes is part one of the server's response to a request to subscribe to a CollectionNode (part 2 is receiveItems). Its job is to send across
		 * all (accessible) stored nodes, their configurations, and the UserRoles for the CollectionNode and the nodes within it. The parameters below
		 * (as well as the code for unwrapping them) detail the formats expected in the default implementation of a MessageManager for receiving this set of 
		 * stored details which the user needs in order to consider his subscription to a CollectionNode "synchronized". 
		 * The formats below are intentionally obtuse, sacrificing readibility or type safety for compactness and universality. 
		 * 
		 * This method is also triggered when new nodes within a collection become available to a User due to a UserRole change or a new NodeConfiguration.
		 * 
		 * @param p_collectionName the name of the collection whose nodes are being received
		 * @param p_nodeConfigValueObjects an Object table of NodeConfiguration valueObjects, hashed by nodeName, representing all accessible nodes in this collection. 
		 * @param p_collectionUserRoles an Object table of UserRoles (ints), hashed by userID, for the specified CollectionNode. 
		 * If the user can configure, this will contain roles for everyone subscribed to the Collection, otherwise just the user's own UserRole.
		 * @param p_nodeUserRoles an Object table of Object tables, first level hashed by nodeName, second by userID. The userRole (int) for each node 
		 * in this collection. If the user can configure a given node, all user roles will be included, otherwise just the user's own UserRole.
		 */
		messaging_internal function receiveNodes(p_collectionName:String, p_nodeConfigValueObjects:Object, p_collectionUserRoles:Object, p_nodeUserRoles:Object):void
		{
			myTrace("receiveNodes "+p_collectionName);
			
			_nodesAlreadyHere = new Object();
			var nodeName:String;
			var userID:String;
			var collectionNode:CollectionNode = _collectionNodes[p_collectionName];
			if (collectionNode==null) {
				// we sometimes receive late-arriving messages on collection nodes that been closed. ignore them.
				return;
			}
			// iterate through the NodeConfiguration valueObjects, set up nodes
			for (nodeName in p_nodeConfigValueObjects) {
				if (collectionNode.isNodeDefined(nodeName)) {
					// there is a possibility that this is being triggered because our role to the CollectionNode got upped. In this case, 
					// the server is sending all nodes in that collection, even if there's a (very, very) slim chance we already had rights to some of the nodes
					// within it (the default implementation isn't smart enough to track all this, and it's a tiny use case). Assuming we always clean up nodes
					// when we lose access to them, it's safe to assume that receiving a node we already know is an example of this case. 
					// Just ignore them, it's no biggie.
					_nodesAlreadyHere[nodeName] = true;
				} else {
					receiveNode(p_collectionName, nodeName, p_nodeConfigValueObjects[nodeName]);
				}
			}
			// iterate through all collection userRoles, set them up. 
			for (userID in p_collectionUserRoles) {
				receiveUserRole(userID, p_collectionUserRoles[userID], p_collectionName);
			}
			var currentRoles:Object;
			// iterate through all node userRoles, set them up. 
			for (nodeName in p_nodeUserRoles) {
				currentRoles = p_nodeUserRoles[nodeName];
				for (userID in currentRoles) {
					// note that, as with the case above, we may be receiving redundant roles. The CollectionNode is smart enough 
					// to recognize when an role is redundant, and not trigger events, so it's safe to pass through.
					receiveUserRole(userID, currentRoles[userID], p_collectionName, nodeName);
				}
			}
		}

		/**
		 * receiveItems is part 2 of a server's response to a CollectionNode subscription request. Its job is to send across all stored MessageItems 
		 * (at least the set accessible by this user) for the collection. The parameters below (as well as the code for unwrapping them) detail the formats 
		 * expected in the default implementation of a MessageManager for receiving this set of stored items, which the user needs in order 
		 * to consider her subscription to a CollectionNode "synchronized".
		 * The transport format of the MessageItems is intentionally obtuse, sacrificing readibility or type safety for compactness and universality. 
		 * 
		 * This method is also triggered when new nodes within a collection become available to a User due to a UserRole change or a new NodeConfiguration.
		 * It's REQUIRED that each receiveItems call be paired with a previous receiveNodes call. The only reason for separating the 2 functions is 
		 * to break up the amount of data being sent over one call.
		 * 
		 * @param p_collectionName The name of the affected CollectionNode. 
		 * @param p_nodeItems An Object table, hashed by nodeName, of Object tables, hashed by itemID, of MessageItem ValueObjects.
		 */
		messaging_internal function receiveItems(p_collectionName:String, p_nodeItems:Object, p_privateItems:Object, p_previouslySynched:Boolean=false):void
		{
			myTrace("receiveItems "+p_collectionName);

			var itemQueue:Array = new Array();
			var nodeName:String;
			var itemID:*;
			var items:Object;
			var privateItems:Object;
			var messageItem:MessageItem;
			for (nodeName in p_nodeItems) {
				// here, we trust that receiveNodes happened corresponding to this receiveItems. If that function caught redundant nodes, 
				// then we should definitely not accept their MessageItems again.
				if (_nodesAlreadyHere[nodeName]==null) {
					items = p_nodeItems[nodeName];
					for (itemID in items) {
						itemQueue.push(items[itemID]);
					}
					privateItems = p_privateItems[nodeName];
					for (itemID in privateItems) {
						itemQueue.push(privateItems[itemID]);
					}
				}
			}
			// make sure all MessageItems received for this collection come in the order they were sent.
//			itemQueue.sortOn(["timeStamp", "timeStampOrder"], [Array.NUMERIC, Array.NUMERIC]);
			itemQueue.sort(itemSort);
			var l:int = itemQueue.length;
			for (var i:int=0; i<l; i++) {
				receiveItem(p_collectionName, itemQueue[i].nodeName, itemQueue[i]);
			}
			if (!p_previouslySynched) {
				receiveAllSynchData(p_collectionName);
			}
		}

		protected function itemSort(p_objA:Object, p_objB:Object):Number
		{
			if (p_objA.timeStamp==p_objB.timeStamp) {
				return (p_objA.timeStampOrder==null || p_objA.timeStampOrder<p_objB.timeStampOrder) ? -1 : 1;
			}
			return (p_objA.timeStamp<p_objB.timeStamp) ? -1 : 1;
		}

		/**
		 * Notifies the relevant CollectionNode when a new node is created
		 * 
		 * @param p_collectionName
		 * @param p_nodeName
		 * @param p_nodeConfiguration
		 * 
		 */
		messaging_internal function receiveNode(p_collectionName:String, p_nodeName:String=null, p_nodeConfigurationVO:Object=null):void
		{
			myTrace("receiveNode "+p_collectionName+", "+p_nodeName);

			if (p_nodeName == null) {
				//this is a new collection getting created
				if (_rootCollectionNode) {
					_rootCollectionNode.receiveNode(p_collectionName);
				}
				_collectionNames[p_collectionName] = true;
				return;
			}
			
			var nodeCollection:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (nodeCollection==null) {
				// we sometimes receive late-arriving messages on collection nodes that been closed. ignore them.
				return;
			}
			var nodeConfig:NodeConfiguration;
			if (p_nodeConfigurationVO!=null) {
				nodeConfig = new NodeConfiguration();
				nodeConfig.readValueObject(p_nodeConfigurationVO);
			}
			nodeCollection.receiveNode(p_nodeName, nodeConfig);
		}
		
		/**
		 * Notifies the relevant CollectionNode when a node is configured
		 * 
		 * @param p_collectionName
		 * @param p_nodeName
		 * @param p_nodeConfiguration
		 * 
		 */
		messaging_internal function receiveNodeConfiguration(p_collectionName:String, p_nodeName:String, p_nodeConfigurationValueObject:Object):void
		{
			myTrace("receiveNodeConfiguration "+p_collectionName+", "+p_nodeName);

			var nodeCollection:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (nodeCollection==null) {
				// we sometimes receive late-arriving messages on collection nodes that been closed. ignore them.
				return;
			}
			// the config change might mean that we can't see this node any more
			var couldISeeNode:Boolean = (nodeCollection.canUserSubscribe(_userManager.myUserID, p_nodeName) || 
																nodeCollection.canUserPublish(_userManager.myUserID,p_nodeName) );
			var nodeConfig:NodeConfiguration = new NodeConfiguration();
			nodeConfig.readValueObject(p_nodeConfigurationValueObject);
			nodeCollection.receiveNodeConfiguration(p_nodeName, nodeConfig);
			var canISeeNode:Boolean = (nodeCollection.canUserSubscribe(_userManager.myUserID, p_nodeName) || 
																nodeCollection.canUserPublish(_userManager.myUserID,p_nodeName) );
			if (couldISeeNode && !canISeeNode) {
				// I can't see this node any longer, flush it
				receiveNodeDeletion(p_collectionName, p_nodeName);
			}
		}

		/**
		 * Notifies the relevant CollectionNode when a node is deleted
		 * 
		 * @param p_collectionName
		 * @param p_nodeName
		 * 
		 */
		messaging_internal function receiveNodeDeletion(p_collectionName:String, p_nodeName:String=null):void
		{
			if (p_nodeName == null) {
				//this is a collection going away
				delete _collectionNames[p_collectionName];
				if (_rootCollectionNode) {
					_rootCollectionNode.receiveNodeDeletion(p_collectionName);
				}
				return;
			}
			
			var nodeCollection:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (nodeCollection==null) {
				// we sometimes receive late-arriving messages on collection nodes that been closed. ignore them.
				return;
			}
			nodeCollection.receiveNodeDeletion(p_nodeName);
		}


		/**
		 *  Notifies the relevant CollectionNode when an item arrives at a node
		 * 
		 * @param p_collectionName
		 * @param p_nodeName
		 * @param p_item
		 * 
		 */
		messaging_internal function receiveItem(p_collectionName:String, p_nodeName:String, p_itemVO:Object):void
		{
			myTrace("receiveItem "+p_collectionName+", "+p_nodeName+", "+p_itemVO.toString());
			var nodeCollection:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (nodeCollection==null) {
				// sometimes we might get a late-arriving message after a cN has been closed. Just ignore it.
				return;
			}
			var item:MessageItem = new MessageItem();
			item.readValueObject(p_itemVO);
			nodeCollection.receiveItem(item);
		}

		/**
		 * Notifies the relevant CollectionNode when an item is retracted from the node
		 * @param p_collectionName the name of the collectionNode which contains this item
		 * @param p_nodeName the name of the node which contains this item
		 * @param p_itemID the ID of the MessageItem to delete.
		 * 
		 */
		messaging_internal function receiveItemRetraction(p_collectionName:String, p_nodeName:String, p_itemVO:Object):void
		{
			var nodeCollection:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (nodeCollection==null) {
				// sometimes we might get a late-arriving message after a cN has been closed. Just ignore it.
				return;
			}
			nodeCollection.receiveItemRetraction(p_nodeName, p_itemVO);
		}

		/**
		 *  Notifies the relevant CollectionNode when an Role change occurs for the collection, or a node within it
		 * 
		 * @param p_collectionName
		 * @param p_userID
		 * @param p_role
		 * @param p_role
		 * 
		 */
		messaging_internal function receiveUserRole(p_userID:String, p_role:int, p_collectionName:String=null, p_nodeName:String=null):void
		{
			
			var collectionNode:CollectionNode;
			if (p_collectionName == null) {
				//this is a role change on the root collection. lotsa work to do.
				
				if (p_role==CollectionNode.NO_EXPLICIT_ROLE) {
					delete _rootUserRoles[p_userID];
				} else {
					//update our root table
					_rootUserRoles[p_userID] = p_role;
				}

				_userManager.receiveUserRoleChange(p_userID, p_role);
				if (_rootCollectionNode) {
					_rootCollectionNode.receiveUserRole(p_userID, p_role);
				}

				//next, go through our first-level collectionNodes, and see if they've got explicit roles set for this user
				for (var collectionName:String in _collectionNodes) {
					collectionNode = _collectionNodes[collectionName] as CollectionNode;
					if (collectionNode.getExplicitUserRole(p_userID)==CollectionNode.NO_EXPLICIT_ROLE) {
						// no explicit role is set - this change will cascade down to the nodes
						collectionNode.receiveCascadingUserRole(p_userID);
					}
				}

				return;
			}
			
			collectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (collectionNode==null) {
				// sometimes we might get a late-arriving message after a cN has been closed. Just ignore it.
				return;
			}
			if (p_nodeName==null) {
				// receiving an explicit new role for the collection
				if (collectionNode.getExplicitUserRole(p_userID)!=p_role) {
					collectionNode.receiveUserRole(p_userID, p_role);
				}
			} else {
				if (collectionNode.getExplicitUserRole(p_userID,p_nodeName)!=p_role) {
					collectionNode.receiveUserRole(p_userID, p_role, p_nodeName);
					// we might not be able to see this node anymore
					if (p_userID==_userManager.myUserID && !collectionNode.canUserPublish(p_userID, p_nodeName) && !collectionNode.canUserSubscribe(p_userID, p_nodeName)) {
						receiveNodeDeletion(p_collectionName, p_nodeName);
					}
				}
			}
		}

		protected function onUserRemove(p_evt:UserEvent):void
		{
			delete _rootUserRoles[p_evt.userDescriptor.userID];
		}
		
		protected function onUserCreate(p_evt:UserEvent):void
		{
			if ( _rootUserRoles[p_evt.userDescriptor.userID] == null ) {
				_rootUserRoles[p_evt.userDescriptor.userID] = p_evt.userDescriptor.role ;
			}
			
			
			//TODO: Review this approach with Nigel, as there might be some latency and the messages might not be in order
			//This approach worked at other places, because order wasnt needed.
			if (_waitingUserDescriptorList[p_evt.userDescriptor.userID] && _sessionManager) {
				var tmpObject:Object = _waitingUserDescriptorList[p_evt.userDescriptor.userID];
				_sessionManager.session_internal::publishItem(tmpObject.collectionName, tmpObject.nodeName, tmpObject.itemObject, tmpObject.overWrite);
				delete _waitingUserDescriptorList[p_evt.userDescriptor.userID];
				tmpObject = null;
			}
		}
		

		protected function onDisconnect(p_evt:SessionEvent):void
		{
			if (_rootCollectionNode) {
				_rootCollectionNode.messaging_internal::setIsSynchronized(false);
			}
			
			//notify all collections
			for each (var collectionNode:CollectionNode in _collectionNodes) {
				collectionNode.messaging_internal::setIsSynchronized(false);
			}				
		}

		/**
		 * Notifies the relevant CollectionNode when the last of the collection sync data (nodes, nodeConfigurations,
		 * roles, stored items) has arrived. The collection is said to be "synchronized" once this stored data is set.
		 * 
		 * @param p_collectionName
		 * 
		 */
		protected function receiveAllSynchData(p_collectionName:String):void
		{
			DebugUtil.debugTrace("receiveAllSynchData "+p_collectionName);

			var collectionNode:CollectionNode = _collectionNodes[p_collectionName] as CollectionNode;
			if (collectionNode==null) {
				// we sometimes receive late-arriving messages on collection nodes that been closed. ignore them.
				return;
			}
			if (!collectionNode.isSynchronized) {
				collectionNode.messaging_internal::setIsSynchronized(true);
			}
		}
		
		protected function flushPendingSubscriptions(p_evt:Event):void
		{
			_connectSession.removeEventListener(SessionEvent.SYNCHRONIZATION_CHANGE, flushPendingSubscriptions);
			var l:int = _pendingSubscriptions.length;
			for (var i:int=0; i<l; i++) {
				subscribeCollection(_pendingSubscriptions[i].collectionNode as CollectionNode, _pendingSubscriptions[i].nodeNames as Array);
			}
			_pendingSubscriptions = new Array();
		}

		// TODO : nigel : there may be times where we're accepting messages from collections that 
		// haven't actually been requested (ie, archive playback getting ahead of instantiated pods)
		// In this case, we need to implement some kind of item queueing until it's requested
		
		protected function myTrace(p_msg:String):void
		{
//			trace("#MessageManager# "+p_msg);
		}
	}
}
