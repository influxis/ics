// ActionScript file
package
{
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ArrayCollection;

	/**
	 * Dispatched when the GroupModel has fully connected and synchronized with the service or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	/**
	 * Dispatched when the current user's role changes with respect to this component.
	 */
	[Event(name="myRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]
	/**
	 * Dispatched when the collectionNode receives an item.
	 */
	[Event(name="itemReceive", type="com.adobe.rtc.events.CollectionNodeEvent")]
	/**
	 * Dispatched when an item is retracted.
	 */
	[Event(name="itemRetract", type="com.adobe.rtc.events.CollectionNodeEvent")]	
		

	/**
	 * MultipleGroupModel is an example for using collectionNode to build a model for keeping track of various users 
	 * in one or more groups.
	 * 
	 * It has functions for creating and removing groups, adding and removing users from a group, and for listing 
	 * all groups or just the groups of a specific user.
	 */
	 
	 /**********************************************************
	  * ADOBE SYSTEMS INCORPORATED
	  * Copyright [2007-2010] Adobe Systems Incorporated
	  * All Rights Reserved.
	  * NOTICE: Adobe permits you to use, modify, and distribute this file in accordance with the 
	  * terms of the Adobe license agreement accompanying it.If you have received this file from a 
	  * source other than Adobe, then your use, modification, or distribution of it requires the prior 
	  * written permission of Adobe.
	  * *********************************/
	public class MultipleGroupModel extends EventDispatcher
	{
		/**
		 * The collectionNode to use.
		 */
		protected var _collectionNode:CollectionNode;
		/**
		 * Keep a reference to the userManager handy.
		 */
		protected var _userManager:UserManager;
		
		protected var _userList:Object ;
		protected var _groups:Array = new Array();
		protected var _userInGroup:Object = new Object();
		
		static private var _instance:MultipleGroupModel;
				
		function MultipleGroupModel():void
		{
			// Assume that the room is already synchronized once this is instantiated. Build the connection to the service.
			// Note the collection is named after our ID.
			
			if(_instance)
			{
				throw new Error("DialogManager singleton already instantiated");				
			}
			
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = "break" ;
			_collectionNode.subscribe();
			// Begin listening for the collectionNode to synchronize, and listen for any messages we might get.
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSyncChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE,onNodeCreate);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE,onNodeDelete);
			_collectionNode.addEventListener(CollectionNodeEvent.MY_ROLE_CHANGE, onMyRoleChange);
			// store a local reference to the userManager
			_userManager = ConnectSession.primarySession.userManager;
			_userManager.addEventListener(UserEvent.USER_CREATE,onUserCreate);
			_userManager.addEventListener(UserEvent.USER_REMOVE,onUserRemove);
			_userList = new Object();			
			
			_userList["default"] = new ArrayCollection();
			for ( var i:int = 0 ; i < _userManager.userCollection.length ; i ++ ) {
				_userList["default"].addItem(_userManager.userCollection.getItemAt(i)) ;
			}
		}
		
		/**
		 * The model has one instance.
		 */
		public static function getInstance():MultipleGroupModel
		{
			if(!_instance)
				_instance = new MultipleGroupModel();
				
			return _instance;				
		}
		
		/**
		 *  Creates a new group.
		 */
		public function createGroup(p_groupName:String):void
		{
			if (_collectionNode.canUserConfigure(_userManager.myUserID)  && !_collectionNode.isNodeDefined(p_groupName)) {
				
				var nodeConfig:NodeConfiguration = new NodeConfiguration();
				// Only OWNERs can modify this; all the other default values for the config will work.
				nodeConfig.publishModel = UserRoles.OWNER;
				nodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL ;
				// for every group there is a node there is a node that is being created with the nodeConfiguration
				_collectionNode.createNode(p_groupName, nodeConfig);
			}
			
		}
		
		/**
		 * Function for removing a group.
		 */
		public function removeGroup(p_groupName:String):void
		{
			if (_collectionNode.canUserConfigure(_userManager.myUserID)  && _collectionNode.isNodeDefined(p_groupName)) {
				// first remove all the users in that group and put them to default group
				if ( _userList[p_groupName] ) {
					for ( var i:int = 0 ; i < _userList[p_groupName].length ; i++ ) {
						notifyRemoveUserFromGroup((_userList[p_groupName] as ArrayCollection).getItemAt(i).userID,p_groupName);
					}
				}
				
				// Remove the node itself.
				_collectionNode.removeNode(p_groupName);
			}
		}
		
		/**
		 * Adds a user to a group.
		 */
		public function notifyAddUserToGroup(p_userID:String , p_groupName:String):void
		{
			// add a user to a particular group ...
			if ( _collectionNode.canUserPublish(_userManager.myUserID,p_groupName) ) {		
				_collectionNode.publishItem(new MessageItem(p_groupName,p_userID,p_userID));
			} 
		}
		
		/**
		 *  Check if the user has the right to publish.
		 */
		public function canIPublish(p_groupName:String):Boolean
		{
			// if I am allowed to publish on this node , by default it is set to the host
			if ( _userManager.myUserRole > _collectionNode.canUserPublish(_userManager.myUserID,p_groupName)) {
				return true;
			}
			
			return false ;
		}
		
		/**
		 *  Removing a user from a group.
		 */
		public function notifyRemoveUserFromGroup(p_userID:String , p_groupName:String):void
		{
			// notify removal of a user from a group ....
			if ( _collectionNode.canUserPublish(_userManager.myUserID, p_groupName) ) {
				_collectionNode.retractItem(p_groupName,p_userID);
			} 
		}
		
		/**
		 *  Checks to see if the group is defined.
		 */
		public function isGroupDefined(p_groupName:String):Boolean
		{
			// loops over the array and returns true if the group exists else it returns false
			for ( var i:int = 0 ; i < _groups.length ; i++ ) {
				if ( _groups[i] == p_groupName ) {
					return true ;
				}
			}
			
			return false ;
		}
		
		/**
		 * Gets all group names. 
		 */
		public function getGroups():Array
		{
			// gets the groups array
			return _groups ;
		}
		
		/**
		 * Returns which group I am in.
		 */
		public function getMyGroup():String 
		{
			// Returns which group I belong to; if not specific virtual group then the main group.
			if ( _userInGroup[_userManager.myUserID] )
				return _userInGroup[_userManager.myUserID] ;
				
			return "default" ;
		}
		
		/**
		 * Returns the users in a valid group.
		 */
		public function getUsersInGroup(p_groupName:String):ArrayCollection
		{
			// returns all the users in a particular group
			return _userList[p_groupName] ;
		}
				
		/**
		 * Handles a synchronization change.
		 */		
		protected function onSyncChange(p_evt:CollectionNodeEvent):void
		{	
			dispatchEvent(p_evt);
		}
		
		/**
		 * Response to CollectionNodeEvent.ITEM_RECEIVE
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			// Fired when an user is added; first update that user's group name.
				
		
			if ( _userList[p_evt.nodeName] == null ) {
				_userList[p_evt.nodeName] = new ArrayCollection();
			}
		
			// Remove the user from default user list.
			for ( var i:int = 0 ; i < _userList["default"].length ; i++ ) {
				if ( _userList["default"].getItemAt(i).userID == p_evt.item.body ) {
					(_userList["default"] as ArrayCollection).removeItemAt(i);
				}	
			}
			
			// Add the user to the new list.
			if ( _userManager.getUserDescriptor(p_evt.item.body) ) {
				// add only if the user doesn't belong to the group
				if ( !(_userList[p_evt.nodeName] as ArrayCollection).contains(_userManager.getUserDescriptor(p_evt.item.body))) {
					(_userList[p_evt.nodeName] as ArrayCollection).addItem(_userManager.getUserDescriptor(p_evt.item.body));
					_userInGroup[p_evt.item.body] = p_evt.nodeName ;
				}
				
			}
				
			// Dispatches the event listened by the view to update their userlist.
			var event:CollectionNodeEvent = new CollectionNodeEvent(CollectionNodeEvent.ITEM_RECEIVE) ;
			event.item = p_evt.item ;
			event.nodeName = p_evt.nodeName ;
			dispatchEvent(event);
		}
		
		/**
		 * Response to CollectionNodeEvent.ITEM_RETRACT.
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{	
			// fires when we retract items from the specific group....
			if ( p_evt.item.itemID == _userManager.myUserID ) 
				_userInGroup[_userManager.myUserID] = "default" ;
			
			var i:int = 0 ;	
			// If the group exists: 
			if ( _userList[p_evt.nodeName] != null ) {
				
				// first we remove the item from that group
				for ( i = 0 ; i < _userList[p_evt.nodeName].length ; i++ ) {
					if ( (_userList[p_evt.nodeName] as ArrayCollection).getItemAt(i).userID == p_evt.item.itemID) {
						(_userList[p_evt.nodeName] as ArrayCollection).removeItemAt(i) ;
						break ;
					}
						
				}
				
				// If the group now has no users, delete its userlist.
				if ( _userList[p_evt.nodeName].length == 0 ) {
					delete _userList[p_evt.nodeName] ;
				}
				
				// Check if it exists in the main group or not. If not add it.
				var exists:Boolean = false ;
				for ( i = 0 ; i < _userList["default"].length ; i++ ) {
					if ( (_userList["default"] as ArrayCollection).getItemAt(i).userID == p_evt.item.itemID) {
						exists = true ;
						break ;
					}
				}
				
				// Add only if it doesn't exist.
				if ( !exists ) {
					(_userList["default"] as ArrayCollection).addItem(_userManager.getUserDescriptor(p_evt.item.body));
				}
				
				// Dispatch the event so the user interface gets updated.
				var event:CollectionNodeEvent = new CollectionNodeEvent(CollectionNodeEvent.ITEM_RETRACT) ;
				event.item = p_evt.item ;
				event.nodeName = p_evt.nodeName ;
				dispatchEvent(event);
				
			}
			
			
		}

		/**
		 * Response to CollectionNodeEvent.MY_ROLE_CHANGE.
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			// just bubble it up for the sake of binding "canISetQuestion"
			dispatchEvent(p_evt);
		}
		
		
		protected function onNodeCreate(p_evt:CollectionNodeEvent):void
		{
			_groups.push(p_evt.nodeName);
			
			if ( canIPublish(p_evt.nodeName))
				dispatchEvent(p_evt);
		}
		
		protected function onNodeDelete(p_evt:CollectionNodeEvent):void
		{
			
			for ( var i:int = 0 ; i < _groups.length ; i++ ) {
				if ( _groups[i] == p_evt.nodeName ) {
					_groups.splice(i,1);
					break ;
				}
			}
			
			// Deleting the userlist for this group if that exists.
			if ( _userList[p_evt.nodeName] )
				delete _userList[p_evt.nodeName] ;
			
			
			if ( canIPublish(p_evt.nodeName))
				dispatchEvent(p_evt);
		}
		
		protected function onUserCreate(p_evt:UserEvent):void
		{
			// Add the new user to the default group.
			if ( !(_userList["default"] as ArrayCollection).contains(p_evt.userDescriptor) ) 
				  (_userList["default"] as ArrayCollection).addItem(p_evt.userDescriptor) ;
		}
		
		protected function onUserRemove(p_evt:UserEvent):void
		{
			// Remove the user from the group.
			if ( _userInGroup[p_evt.userDescriptor.userID] == null ) {
				return ;
			}
			
			if ( _userList[_userInGroup[p_evt.userDescriptor.userID]] == null ) {
				return ;
			}
			
			for ( var i:int = 0; i < _userList[_userInGroup[p_evt.userDescriptor.userID]].length ; i++ ) {
				if ( _userList[_userInGroup[p_evt.userDescriptor.userID]].getItemAt(i).userID == p_evt.userDescriptor.userID) {
					(_userList[_userInGroup[p_evt.userDescriptor.userID]] as ArrayCollection).removeItemAt(i);
					delete _userInGroup[p_evt.userDescriptor.userID] ;
					break ;
				}
			}
		}
		
		
		
	}
}