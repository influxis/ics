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
package com.adobe.rtc.sharedManagers
{
	import com.adobe.rtc.core.messaging_internal;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.sharedManagers.constants.UserStatuses;
	import com.adobe.rtc.sharedManagers.constants.UserVoiceStatuses;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	
	import flash.events.EventDispatcher;
	import flash.net.NetConnection;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	
	/**
	 * Dispatched when the UserManager has received everything up to the current 
	 * state of the room or has lost the connection.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * Dispatched when the user's role has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * Dispatched when the user's displayName has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userNameChange", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * Dispatched when a new user joins the room.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userCreate", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * Dispatched when a user leaves the room.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userRemove", type="com.adobe.rtc.events.UserEvent")]

	/**
	 * 
	 * Dispatched when a custom field value for a user has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="customFieldChange", type="com.adobe.rtc.events.UserEvent")]
	/**
	 * 
	 * Dispatched when a custom field for a user is registered.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="customFieldRegister", type="com.adobe.rtc.events.UserEvent")]
	/**
	 * 
	 * Dispatched when a custom field for a user is deleted.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="customFieldDelete", type="com.adobe.rtc.events.UserEvent")]
	
	/**
	 * Dispatched when a user's connection speed has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userConnectionChange", type="com.adobe.rtc.events.UserEvent")]
	

	/**
	 * Dispatched when a user's ping data has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userPingDataChange", type="com.adobe.rtc.events.UserEvent")]


	/**
	 * Dispatched when a user's icon URL has changed.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userUsericonURLChange", type="com.adobe.rtc.events.UserEvent")]


	/**
	 * Dispatched when a user is forcibly ejected from the room.
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="userBooted", type="com.adobe.rtc.events.UserEvent")]
	
	/**
	 * Dispatched when anonymousPresence is set in the UserManager
	 *
	 * @eventType com.adobe.rtc.events.UserEvent
	 */
	[Event(name="anonymousPresenceChange", type="com.adobe.rtc.events.UserEvent")]


	
	/**
	 * UserManager is one of the "four pillars" of a room and is tasked with maintaining a list 
	 * of the set of users in the room, along with their descriptors. It is also the primary 
	 * class through which one publishes changes to a user role or other user information.
	 * 
	 * <p>
	 * Each IConnectSession handles the creation and setup of its own UserManager instance.  
	 * Use an IConnectSession <code class="property">userManager</code> property to access it.
	 * </p>
	 *
	 * <p>
	 * <h6>Building a basic roster list </h6>
	 * <listing>
	 *	&lt;rtc:AdobeHSAuthenticator userName="AdobeIDusername password="AdobeIDpassword" id="auth"/&gt;
	 *	&lt;session:ConnectSessionContainer 
	 * 		id="cSession" 
	 * 		roomURL="http://connect.acrobat.com/fakeRoom/" 
	 * 		authenticator="{auth}"&gt;
  	 *	
  	 * 		&lt;mx:List width="300" height="600" dataProvider="{cSession.userManager.userCollection}" 
  	 * 		labelField="displayName"/&gt;
	 *	&lt;/session:ConnectSessionContainer&gt; </listing>
	 * 
	 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor
	 * @see com.adobe.rtc.events.UserEvent
	 * @see com.adobe.rtc.session.IConnectSession
	 * */
   public class  UserManager extends EventDispatcher implements ISessionSubscriber
	{

		/**
		* @private
		* Temporary internal storage for the current user's descriptor (gets filed into _userDescriptorTable).
		*/
		protected var _myUserDescriptor:UserDescriptor;

		/**
		* @private - internal storage for the current user's unique ID
		*/
		protected var _myUserID:String;

		/**
		* @private - the collectionNode used for sending all UserManager messaging
		*/
		protected var _umCollectionNode:CollectionNode;

		/**
		* @private - internal storage for the entire set of users (hashed by userID)
		*/
		protected var _userDescriptorTable:Object = new Object();
		/**
		 * @private
		 */ 
		protected var _waitingUsersList:Array = new Array();

		/**
		* @private - internal storage for the sorted list of users
		*/
		protected var _userDescriptorList:Array = new Array();

		/**
		* @private - the nodeConfiguration needed for user list (and custom field) nodes
		*/
		protected var _userListNodeConfig:NodeConfiguration;

		/**
		* @private - whether or not we're creating the userManager as part of a template
		*/
		protected var _isTemplating:Boolean = false;

		/**
		* @private - the Stream Manager, which we need to monitor people's voice and sharing statuses
		*/
		protected var _streamManager:StreamManager;

		 [Bindable]
		/**
		 * [Read-only] Returns a sorted collection of user descriptors.
		 */
		public var userCollection:ArrayCollection;
		
		
		[Bindable]
		/**
		 * [Read-only] Returns a sorted collection of user descriptors with root user roles of UserRoles.OWNER.
		 */
		public var hostCollection:ArrayCollection;
		[Bindable]
		/**
		 * [Read-only] Returns a sorted collection of user descriptors with root user roles of UserRoles.PUBLISHER.
		 */
		public var participantCollection:ArrayCollection;
		[Bindable]
		/**
		 * [Read-only] Returns a sorted collection of user descriptors with root user roles of UserRoles.VIEWER.
		 */
		public var audienceCollection:ArrayCollection;
		
		/**
		 * @private
		 */
		public var myTicket:String;		

		/**
		 * @private 
		 */
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;

		/**
		* @private - The sort object for userCollection
		*/
		protected var _sorter:Sort;

		/**
		* @private - whether or not the current user's descriptor has been published
		*/
		protected var _myDescriptorPublished:Boolean=false;
		/**
		 * @private 
		 */
		protected var _customFieldNames:Array = new Array();

		/**
		* The name of the <code>collectionNode</code> UserManager uses to build its shared model.
		*/
		public static const COLLECTION_NAME:String = "UserManager";

		/**
		* @private - the name of the node used in storing the userdescriptor list
		*/
		protected static const NODENAME_USER_LIST:String = "UserList";
		
		/**
		* @private 
		* The name of the node used for ping data. Because this is updated so often,
		*  it gets its own node to publish to instead of overwriting the entire User Descriptor
		*  at once.  If it tried to update the user descriptor at the same time as something else
		*  did, there would be a race condition.
		*/		
		protected static const NODENAME_PING_LIST:String = "PingList";

		/**
		 * @private - the name of the node which is a messaging channel through which UserManager will keep buddies up to date
		 * This node will be created any time UserManager.anonymousPresence is set to true.
		 */
		protected static const NODENAME_BUDDY_NOTIFICATIONS:String = "BuddyNotifications";

		/**
		* @private - The name of the node used for voice data (talking or not). This is also updated
		 *  so often that it should get its own node to prevent race conditions.
		*/
		protected static const NODENAME_VOICE_STATUS_LIST:String = "VoiceStatusList";

		/**
		 * @private
		 */
		protected var _myCachedConnection:String = "";
		
		/**
		 * @private
		 */
		protected var _anonymousPresence:Boolean;

		/**
		 * @private
		 */
		protected var _anonymousPresenceSetFlag:Boolean = false;
		/**
		 * @private
		 */ 
		protected var _myBuddyList:Array;
		/**
		 * @private
		 */ 
		protected var _pendingCustomUserField:MessageItem;
		protected static const SIMPLE_BUDDY_PRESENCE_CHANGE:String = "here";
		

		public function UserManager()
		{
			userCollection = new ArrayCollection();
			_sorter = new Sort();
			_sorter.compareFunction = compareFunction;
			
			hostCollection = new ArrayCollection();
			participantCollection = new ArrayCollection();
			audienceCollection = new ArrayCollection();
		}


		/**
		 * @private
		 */
		public function get sharedID():String
		{
			return COLLECTION_NAME;
		}
		
		/**
		 * @private
		 */
		public function set sharedID(p_id:String):void
		{
			// no-op
		}
		
		/**
		 * (Read Only) Specifies the IConnectSession to which this manager is assigned. 
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
		 * Determines whether all the others users in the room be revealed.
		 * 
		 * Upon setting this property to true,  users aren't revealed until explicitly called for. 
		 * UserManager.userCollection and getUserDescriptor won't have any entry for any user (other than one's self)
		 * unless there's a specific request for that user. Any call to the getUserDescriptor will cause the UserManager to
		 * fetch that particular UserDescriptor and cache it, dispatching the usual userCreate event.
		 */ 
		public function get anonymousPresence():Boolean
		{
			if (_umCollectionNode.isSynchronized && _umCollectionNode.isNodeDefined(NODENAME_USER_LIST)) {
				return _umCollectionNode.getNodeConfiguration(NODENAME_USER_LIST).lazySubscription;
			} else {
				throw new Error("UserManager.anonymousPresence : Wrong time to check anonymousPresence. Wait for the UserManager to synchronize. The value of anonymousPresence is returned after its actually set in the server");
			}
		}
		// AdobePatentID="B1199"
		public function set anonymousPresence(p_anonymousPresence:Boolean):void
		{
			_anonymousPresenceSetFlag = true;
			_anonymousPresence = p_anonymousPresence;
			if (_umCollectionNode && _umCollectionNode.isSynchronized) {
				createUserManagerNodes();
			}
		}
		
		/**
		 * An array of userIDs, which represents the set of users which might be listening for the current user's updates
		 * 
		 * Note, this isn't the set of users the current user is listening for, but rather the inverse. The current user would 
		 * notify users in the Array about all his activities. In other words the users in the Array users are listening to the current user
		 * even if he is not listening to them.
		 */ 
		public function get myBuddyList():Array
		{
			return _myBuddyList;
		}
		
		public function set myBuddyList(p_myBuddyList:Array):void
		{
			_myBuddyList = p_myBuddyList;
			try {
				if (isSynchronized && anonymousPresence) {
					//Should the users be Notified ??. Reasonable Behaviour and expectation is that 
					//anonymousPresence is not toggled when the session is in progress.
					//So no need to add 
					createBuddyNode();
				}
			} catch (e:Error) {
				//Do nothing.
			}
		}
		
		
		
		/**
		 * @private
		 * On Closing session.
		 */
		public function close():void
		{
			//NO OP
		}
		

		/**
		 * @private
		 */
		public function subscribe():void
		{
			//this is needed for access before the first sync
//			_myUserDescriptor = _userDescriptorTable[_myUserID] as UserDescriptor;

			//clean up model
			_userDescriptorTable = new Object();
			userCollection.removeAll();
			hostCollection.removeAll(); 
			participantCollection.removeAll();
			audienceCollection.removeAll();
			_myDescriptorPublished = false;			
			
			_umCollectionNode = new CollectionNode();
			_umCollectionNode.connectSession = _connectSession;
			_umCollectionNode.sharedID = COLLECTION_NAME ;
			_umCollectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_umCollectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
			_umCollectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			_umCollectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_umCollectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_umCollectionNode.addEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onNodeConfigChange);
			_umCollectionNode.subscribe();
		}

		/**
		 * @private
		 */
		session_internal function set myUserDescriptor(p_userDescriptorVO:Object):void
		{
			_myUserID = p_userDescriptorVO.userID;
			_myUserDescriptor = readUserDesc(p_userDescriptorVO);
		}	
		
		/**
		 * @private
		 */
		messaging_internal function receiveUserRoleChange(p_userID:String, p_role:int):void
		{
			if (!_myDescriptorPublished && _myUserID==p_userID) {
				// I haven't had my desciptor round-trip yet, but my role has changed. Not possible!... unless...
				// the server has promoted me from lobby to "in the room". Store this new role on my temp descriptor
				_myUserDescriptor.role = p_role;
				return;
			}
			var userDesc:UserDescriptor = getUserDescriptor(p_userID);
			if (userDesc==null) {
				// it's possible to receive one of these notifications between the messageManager subscribing and the userManager subscribing.
				// don't worry, the userManager synching up will recover from this on its own
				try {
					if (anonymousPresence) {
						fetchUserDescriptor(p_userID);
					}
				} catch (e:Error) {
					return;
				}
				return;
			}
			
			
			removeUserFromCollection(userDesc);
			userDesc.role = p_role;
			addUserToCollection(userDesc);
			_userDescriptorTable[userDesc.userID] = userDesc;
			
			
			dispatchEvent(new UserEvent(UserEvent.USER_ROLE_CHANGE, userDesc));
		}
			
			
			
		/**
		 * The current user's <code>userID</code>.
		 */
		public function get myUserID():String
		{
			return _myUserID;
		}
		
		[Bindable (event="userRoleChange")]
		/**
		 * Specifies the current user's role. 
		 */
		public function get myUserRole():int
		{
			var myDesc:UserDescriptor = getUserDescriptor(_myUserID);
			return (myDesc==null) ? 0 : myDesc.role;
		}
		
		/**
		 * Specifies the current user's affiliation.
		 * 
		 * @see com.adobe.rtc.sharedManagers.descriptors.UserDescriptor   
		 */
		public function get myUserAffiliation():int
		{
			var myDesc:UserDescriptor = getUserDescriptor(_myUserID);
			return (myDesc==null) ? 0 : myDesc.affiliation;
		}

		/**
		 * Specifies whether or not the UserManager has connected and has synchronized all 
		 * of the user information from the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _umCollectionNode.isSynchronized;
		}
		
		/**
		 * Fetches all available details about the specified user. If <code>anonymousPresence</code> is set to true,
		 * the method migth return a null if <code>UserDescriptor</code> was never fetched. In such a situation we must
		 * listen to <code>UserEvent.USER_CREATE</code> event and update the User's  <code>UserDescriptor</code> we wanted.
		 * 
		 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
		 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
		 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
		 * userDescriptor's are fetched.
		 * 
		 * @param p_userID The unique ID of the user being queried.
		 * 
		 * @return The UserDescriptor of the specified user.
		 */
		public function getUserDescriptor(p_userID:String):UserDescriptor
		{
			if (p_userID==myUserID && !_myDescriptorPublished) {
				return _myUserDescriptor;
			}
			if (_userDescriptorTable[p_userID]) {
				return _userDescriptorTable[p_userID] as UserDescriptor;
			} else {
				//LazySubscription might be set
				try {
					if (anonymousPresence) {
						fetchUserDescriptor(p_userID);
					}
				} catch (e:Error) {
					return null;
				}
				return null;
			}
		}


		/**
		 * Promotes or demotes the specified user at the "root level". This is the primary 
		 * way to change a user's role (although it's also possible to change a user's role relative 
		 * to a specific CollectionNode within the application). Note that only users with an owner 
		 * role  at the root level may call this method.
		 * 
		 * @param p_userID The unique ID of the user to affect
		 * @param p_role The new role for the user
		 * @see com.adobe.rtc.sharedModel.CollectionNode
		 */
		public function setUserRole(p_userID:String, p_role:int):void
		{
			if (_umCollectionNode.canUserConfigure(myUserID) || (_myUserDescriptor.affiliation==UserRoles.OWNER && p_userID==myUserID)) {
				// TODO : nigel : think more about the dependencies between UserManager and MessageManager.
				_connectSession.sessionInternals.messaging_internal::messageManager.messaging_internal::setUserRole(p_userID, p_role);
			} else {
				throw new Error("UserManager.setUserRole : insufficient permissions to change user role");
			}
		}
		
		/**
		 * Gets the role of the specified user for a particular node. 
		 * 
		 * @param p_userID The specified user's <code>userID</code>.
		 * @param p_nodeName The group name on which we are getting the user roles, default is null
		 * 
		 * @return int which is the user role value
		 */
		public function getUserRole(p_userID:String, p_nodeName:String=null ):int
		{
			return _umCollectionNode.getUserRole(p_userID, p_nodeName);
		}
		
		
		/**
		 * @private
		 */
		public function setUserStatus(p_userID:String, p_status:String):void
		{
			if (!_umCollectionNode.canUserPublish(myUserID, NODENAME_USER_LIST)) {
				throw new Error("UserManager.setUserStatus: insufficient permissions to change user status");
				return;
			}
			
			if(!UserStatuses.isValidStatus(p_status)) {
				throw new Error("UserManager.setUserStatus: invalid status.");
				return;
			}
			
			var descriptorVO:Object = getUserDescriptor(p_userID).createValueObject();
			descriptorVO.status = p_status;
			_umCollectionNode.publishItem(new MessageItem(NODENAME_USER_LIST, descriptorVO, p_userID));			
		}
		
		/**
		 * Modifies the displayName of a given user. Note that only OWNERs and the user in question are able to 
		 * change the user's displayName.
		 * 
		 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
		 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
		 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
		 * userDescriptor's are fetched.
		 * 
		 * @param p_userID The userID of the specified user
		 * @param p_name The new displayName to assign to that user
		 */
		public function setUserDisplayName(p_userID:String, p_name:String):void
		{
			if (!_umCollectionNode.canUserPublish(myUserID, NODENAME_USER_LIST)) {
				throw new Error("UserManager.setUserStatus: insufficient permissions to change user name");
				return;
			}
			
			var descriptorVO:Object = getUserDescriptor(p_userID).createValueObject();
			descriptorVO.displayName = p_name;
			_umCollectionNode.publishItem(new MessageItem(NODENAME_USER_LIST, descriptorVO, p_userID));			
		}
		
		
		/**
		 * @private
		 */
		public function setUserVoiceStatus(p_userID:String, p_status:String):void
		{
			if (!_umCollectionNode.canUserPublish(myUserID, NODENAME_VOICE_STATUS_LIST)) {
				if ( p_userID != myUserID ) {
					throw new Error("UserManager.setUserVoiceStatus : insufficient permissions to change user status");
				}
				return;
			}
			
			if(!UserVoiceStatuses.isValidStatus(p_status)) {
				throw new Error("UserManager.setUserStatus: invalid status.");
				return;
			}
			
			// This will be called pretty frequently, so we publish to a separate node and let receivers
			//   fold it into the descriptor on their own.
			
			var descriptor:Object = {};
			descriptor.voiceStatus = p_status;
			if (_umCollectionNode.isNodeDefined(NODENAME_VOICE_STATUS_LIST)) {
				_umCollectionNode.publishItem(new MessageItem(NODENAME_VOICE_STATUS_LIST, descriptor, p_userID));
			}
		}
		
		
		/**
		 * Sets the URL for the user's avatar icon.
		 * 
 		 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
		 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
		 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
		 * userDescriptor's are fetched.
		 * 
		 * @param p_userID The userID of the user specified.
		 * @param p_usericonURL the URL of the icon desired.
		 */
		public function setUserUsericonURL(p_userID:String, p_usericonURL:String):void
		{
			if(_myDescriptorPublished) {
				var descriptorVO:Object = getUserDescriptor(p_userID).createValueObject();
				descriptorVO.usericonURL = p_usericonURL;
				_umCollectionNode.publishItem(new MessageItem(NODENAME_USER_LIST, descriptorVO, p_userID));
			}
		}
		
		/**
		 * Removes a specified user from the room, thereby ejecting that user.
		 * 
		 * @param p_userID the userID of the desired ejectee
		 */
		public function removeUser(p_userID:String):void
		{
			if (_umCollectionNode.canUserConfigure(myUserID)) {
				//_connectSession.messaging_internal::messageManager.messaging_internal::
				var userDesc:UserDescriptor = _userDescriptorTable[p_userID];
				if (userDesc!=null) {
					var item:MessageItem = new MessageItem(NODENAME_USER_LIST, userDesc, userDesc.userID);
					_umCollectionNode.retractItem(item.nodeName, item.itemID);
				}
			}else {
				throw new Error("UserManager.removeUser : insufficient permissions to remove user");
			}
		}
		
		
		/**
		 * Publishes a ping data update.
		 * 
		 * @param p_userID The userID of the user to update.
		 * @param p_latency The new latency statistic.
		 * @param p_drops The new drops statistic.
		 * 
		 */
		public function setPingData(p_userID:String, p_latency:int, p_drops:int):void {

			if(_myDescriptorPublished) {
				
				// Here we're going to publish to a separate node from the user descriptor in order
				//   to circumvent race conditions, since this will be called so often.
				// (Previously, we cloned the descriptor and updated the latency and drops fields, just
				//   like for the other properties.  But if it went out at the same time as another update,
				//   for example a user status update, both copies would have some accurate and some stale
				//   data.)
				
				var descriptor:Object = {};
				descriptor.latency = p_latency;
				descriptor.drops = p_drops;
				_umCollectionNode.publishItem(new MessageItem(NODENAME_PING_LIST, descriptor, p_userID));			
			}
		}

		/**
		 * Registers a custom field for use in the userDescriptor (will appear in the CustomField Object).
		 * Only hosts are allowed to create regisfields, but users can publish them once
		 * @param p_fieldName The name of the new custom field
		 * 
		 */
		public function registerCustomUserField(p_fieldName:String):void
		{
			if (_umCollectionNode.canUserConfigure(myUserID)) {
				if (!isCustomFieldDefined(p_fieldName)) {
					var nodeConfig:NodeConfiguration = new NodeConfiguration();
					// cheap cloning 
					nodeConfig.readValueObject(_userListNodeConfig.createValueObject());
					nodeConfig.allowPrivateMessages = true;
					nodeConfig.publishModel = UserRoles.VIEWER;
					_umCollectionNode.createNode(p_fieldName, nodeConfig);
				} else {
					throw new Error("UserManager.registerCustomUserField : custom field " + p_fieldName + " already registered.");
				}
			} else {
				throw new Error("UserManager.registerCustomUserField : Insufficient privileges to register a custom user field");
			}
		}


		/**
		 * @private
		 * Tests whether a custom field is already registered with the UserManager
		 * @param p_fieldName the custom field in question
		 * @return true if defined, false if not
		 */
		public function isCustomFieldDefined(p_fieldName:String):Boolean
		{
			return (p_fieldName!=NODENAME_USER_LIST && p_fieldName!=NODENAME_BUDDY_NOTIFICATIONS &&
			_umCollectionNode.isNodeDefined(p_fieldName) && _umCollectionNode.getNodeConfiguration(p_fieldName).userDependentItems);
		}
		
		/**
		 * Returns the list of all the custom fields created.
		 */
		public function get customFieldNames():Array
		{
			return _customFieldNames ;
		}


		/**
		 * Custom User Fields are used to store extended info about a particular user (for example, phone status, "I have a question", etc).
		 * A custom field must be registered before it can be modified. Custom fields are modifiable by the given user or a host.
		 * @param p_userID The user to be modified
		 * @param p_fieldName The name of the custom field to modify
		 * @param p_value The new value for the custom field (null to delete)
		 * 
		 */
		public function setCustomUserField(p_userID:String, p_fieldName:String, p_value:*):void
		{
			if (p_userID==myUserID || myUserRole==UserRoles.OWNER) {
				if ( !isCustomFieldDefined(p_fieldName)) {
					throw new Error("UserManager.setCustomUserField : Custom Field " + p_fieldName + " does not exist, register it first");
				}else  {
					if (!anonymousPresence) {
						_umCollectionNode.publishItem(new MessageItem(p_fieldName, p_value, p_userID));
					} else {
						var msgItem:MessageItem = new MessageItem(p_fieldName, p_value, p_userID);
						if (myBuddyList && myBuddyList.length > 0 ) {
							msgItem.recipientIDs = myBuddyList;
						} else {
							msgItem.recipientID = "fakeUserID";
						}
						if (_umCollectionNode.getNodeConfiguration(p_fieldName).allowPrivateMessages) {
							_umCollectionNode.publishItem(msgItem);
						} else if (_umCollectionNode.canUserConfigure(myUserID, p_fieldName)){
							var nodeConfig:NodeConfiguration = new NodeConfiguration();
							// cheap cloning 
							nodeConfig.readValueObject(_umCollectionNode.getNodeConfiguration(p_fieldName).createValueObject());
							nodeConfig.allowPrivateMessages = true;
							_umCollectionNode.setNodeConfiguration(p_fieldName,nodeConfig);
							_pendingCustomUserField = msgItem;
						}
					}
				}
			} else {
				throw new Error("UserManager.setCustomUserField : Insufficient privileges to set a custom field for " + p_userID);
			}
		}
		
		/**
		 * Deletes a custom field for used in the customField Object).
		 * Only hosts are allowed to create deleteFields.
		 * @param p_fieldName The name of the custom field to be deleted
		 * 
		 */
		public function deleteCustomUserField(p_fieldName:String):void
		{
			if (_umCollectionNode.canUserConfigure(myUserID)) {
				if ( !isCustomFieldDefined(p_fieldName)) {
					throw new Error("UserManager.deleteCustomUserField : Custom Field " + p_fieldName + " can't be deleted as it doesn't exist");
				}else {
					_umCollectionNode.removeNode(p_fieldName);
				}
			}else {
				throw new Error("UserManager.deleteCustomUserField : Insufficient privileges to delete a field " + p_fieldName);
			}
		}


		/**
		 * @private
		 * Publishes a new user's information for the room to see. Only the given user and the host may use this.
		 * @param p_userDescriptor The userDescriptor of the user to publish to the list
		 */
		public function createUser(p_userDescriptor:UserDescriptor):void
		{
			if (_userDescriptorTable[p_userDescriptor.userID]==null) {
				var item:MessageItem = new MessageItem(NODENAME_USER_LIST, p_userDescriptor.createValueObject(), p_userDescriptor.userID);
				_umCollectionNode.publishItem(item);
			}
		}

		/**
		 * Sets the user's connection to one of the following: 
		 * <ul>
		 * <li>RoomSettings.MODEM</li>
		 * <li>RoomSettings.DSL</li>
		 * <li>RoomSettings.LAN</li>
		 * </ul> 
		 * 
 		 * Note: If the <code>UserManager.anonymousPresence</code> is set to true, then this method might fail if the
		 * user's userDescriptor has not been fetched. So it is adviced to call this method after the required userDescriptor's
		 * are fetched.In other words listen to <code>UserEvent.USER_CREATE</code> event and call this method after the required
		 * userDescriptor's are fetched.
		 * 
		 * @param p_userID The userID of the user the change.
		 * @param p_conn The new connection speed value which is one of the RoomSetting constants.
		 * @param p_forceUpdate Whether or not the update should be forced; the default is false. 
		 */
		public function setUserConnection(p_userID:String, p_conn:String, p_forceUpdate:Boolean=false):void
		{
			if (	p_conn != RoomSettings.MODEM
				&&	p_conn != RoomSettings.DSL
				&&	p_conn != RoomSettings.LAN)
			{
				p_conn = RoomSettings.DSL;	//if input is bad, default to DSL
			}

			if (_userDescriptorTable[p_userID] == null) {
				if (p_userID == _myUserID && !_myDescriptorPublished) {
					//cache it
					_myCachedConnection = p_conn;
				} else {
					throw new Error("User :"+p_userID+" does not exist");
				}
				return;
			}	
			var userVO:Object = getUserDescriptor(p_userID).createValueObject();
			if (p_conn != userVO.connection || p_forceUpdate) {
				userVO.connection = p_conn;
				var item:MessageItem = new MessageItem(NODENAME_USER_LIST, userVO, p_userID);
				_umCollectionNode.publishItem(item);
			}
		}
		/**
		 * Determines whether or not the given user has power to make modifications to other users. 
		 * 
		 * @param p_userID The ID of the user in question.
		 * @return True if the user can make modifications; false if not.
		 */
		public function canUserConfigure(p_userID:String):Boolean
		{
			return _umCollectionNode.canUserConfigure(p_userID);
		}
		

		/**
		 * Called when we've either received all user info or lost connection.
		 * 
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if (_umCollectionNode.isSynchronized) {
				_userListNodeConfig = new NodeConfiguration();
				_userListNodeConfig.modifyAnyItem = false;
				_userListNodeConfig.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL;
				_userListNodeConfig.userDependentItems = true;
				_userListNodeConfig.publishModel = UserRoles.VIEWER;
				
				// we just received all current users, assume we're fresh
				createUserManagerNodes();
				
				//TODO: SDK - clean this up
				//sometimes the role I got in myUserDescriptor is not my actual role (this happens for knocking, auto-promote...)
				//
				//The sequence can be this:
				//	1.server sets my root role to 5
				//	2.in my set myUserDescriptor it's actually read in as 10 because the messageManager hasn't received the root role
				//	3.MessageManager gets sync with the right roles
				//	4.this function triggers
				//
				//in this case, we stuff the role back in _myUserDescriptor
				//
				//UserManager syncs first after MessageManager, so other components will get the correct role
				//
				
				var roleFromServer:int = _connectSession.sessionInternals.messaging_internal::messageManager.messaging_internal::getRootUserRole(_myUserDescriptor.userID);
				if (roleFromServer != _myUserDescriptor.role) {
					_myUserDescriptor.role = roleFromServer;
				}
				
				if (_myUserDescriptor.role == UserRoles.LOBBY) {
					//Tell ConnectSession that I'm done for now
					//I'm already listening to NODE_CREATE for NODENAME_USER_LIST, I'll publish my descriptor then
					dispatchEvent(new UserEvent(UserEvent.SYNCHRONIZATION_CHANGE));					
				} else {
					var uri:String;
					
					if ( (_connectSession.sessionInternals.session_internal::connection as NetConnection) != null ) {
						uri = (_connectSession.sessionInternals.session_internal::connection as NetConnection).uri ;
						if ( uri.split(":")[0] == "rtmfp" ) {
							_myUserDescriptor.isRTMFP = true ;
						}else {
							_myUserDescriptor.isRTMFP = false ;
						}
					}else 
						_myUserDescriptor.isRTMFP = false ;
					
					_myUserDescriptor.playerVersion = Capabilities.version ;
					createUser(_myUserDescriptor);
				}
				
			} else {
				_umCollectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_umCollectionNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onNodeCreate);
				_umCollectionNode.removeEventListener(CollectionNodeEvent.NODE_DELETE,onNodeDelete);
				_umCollectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_umCollectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_umCollectionNode.removeEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onNodeConfigChange);
				_umCollectionNode.unsubscribe();
				
				dispatchEvent(new UserEvent(UserEvent.SYNCHRONIZATION_CHANGE));					
			}
		}
		
		protected function fetchUserDescriptor(p_userID:String):void
		{
			if (_umCollectionNode.isSynchronized) {
				var userList:Array = [p_userID];
				if (_umCollectionNode.isNodeDefined(NODENAME_USER_LIST)) {
					_umCollectionNode.fetchItems(NODENAME_USER_LIST,userList);
				}
				if (_umCollectionNode.isNodeDefined(NODENAME_PING_LIST)) {
					_umCollectionNode.fetchItems(NODENAME_PING_LIST,userList);
				}
			}
		}
		
		protected function createUserManagerNodes():void
		{
			if (_umCollectionNode.isSynchronized) {
				var nodeConfig:NodeConfiguration = new NodeConfiguration();
				// cheap cloning 
				nodeConfig.readValueObject(_userListNodeConfig.createValueObject());
				if (_anonymousPresenceSetFlag) {
					nodeConfig.lazySubscription = _anonymousPresence;
				}
				
				// we just received all current users, assume we're fresh
				if ( _umCollectionNode.canUserConfigure(myUserID)) {
					if (!_umCollectionNode.isNodeDefined(NODENAME_USER_LIST)) {
						_isTemplating = true;
						_umCollectionNode.createNode(NODENAME_USER_LIST, nodeConfig);
					} else if (_anonymousPresenceSetFlag) {
						//set anonymousPresence to the node Configuration for lazy subscription
						var userListNodeConfig:NodeConfiguration = _umCollectionNode.getNodeConfiguration(NODENAME_USER_LIST);
						if (userListNodeConfig.lazySubscription != _anonymousPresence){
							userListNodeConfig.lazySubscription = _anonymousPresence;
							_umCollectionNode.setNodeConfiguration(NODENAME_USER_LIST, userListNodeConfig);
						} else {
							createBuddyNode();
						}
					} else if (anonymousPresence) {
						createBuddyNode();
					}
					
					if (!_umCollectionNode.isNodeDefined(NODENAME_PING_LIST)) {
						_umCollectionNode.createNode(NODENAME_PING_LIST, nodeConfig);
					} else if (_anonymousPresenceSetFlag) {
						//set anonymousPresence to the node Configuration for lazy subscription
						var pingListNodeConfig:NodeConfiguration = _umCollectionNode.getNodeConfiguration(NODENAME_PING_LIST);
						if (pingListNodeConfig.lazySubscription != _anonymousPresence){
							pingListNodeConfig.lazySubscription = _anonymousPresence;
							_umCollectionNode.setNodeConfiguration(NODENAME_PING_LIST, pingListNodeConfig);
						}
					}
					
					if (!_umCollectionNode.isNodeDefined(NODENAME_VOICE_STATUS_LIST)) {
						var voiceNodeConfig:NodeConfiguration = new NodeConfiguration();
						// cheap cloning 
						voiceNodeConfig.readValueObject(_userListNodeConfig.createValueObject());
						voiceNodeConfig.publishModel = UserRoles.PUBLISHER;
						//if (_anonymousPresenceSetFlag) {
						//	voiceNodeConfig.lazySubscription = _anonymousPresence;
						//}
						_umCollectionNode.createNode(NODENAME_VOICE_STATUS_LIST, voiceNodeConfig);
					} else if (_anonymousPresenceSetFlag) {
						var voiceStatusListNodeConfig:NodeConfiguration = _umCollectionNode.getNodeConfiguration(NODENAME_VOICE_STATUS_LIST);
						if (voiceStatusListNodeConfig.lazySubscription != _anonymousPresence){
							voiceStatusListNodeConfig.lazySubscription = _anonymousPresence;
							_umCollectionNode.setNodeConfiguration(NODENAME_PING_LIST, voiceStatusListNodeConfig);
						}
					}
				} else {
					if (_anonymousPresenceSetFlag) {
						_anonymousPresenceSetFlag = false;
						throw new Error("UserManager.anonymousPresence : insufficient permissions to set anonymousPresence");
					}
					
					if (_umCollectionNode.isSynchronized && _umCollectionNode.isNodeDefined(NODENAME_USER_LIST) && anonymousPresence) {
						createBuddyNode();
					}
				}
			}

		}
		
		protected function createBuddyNode():void
		{
			if (_umCollectionNode && _umCollectionNode.isSynchronized &&_umCollectionNode.isNodeDefined(NODENAME_BUDDY_NOTIFICATIONS)) {
				if (!anonymousPresence) {
					if (_umCollectionNode.canUserConfigure(myUserID)) {
						_umCollectionNode.removeNode(NODENAME_BUDDY_NOTIFICATIONS);
					}
				} else if (myBuddyList && myBuddyList.length > 0) {
					var msgItem:MessageItem =  new MessageItem(NODENAME_BUDDY_NOTIFICATIONS,SIMPLE_BUDDY_PRESENCE_CHANGE,myUserID);
					msgItem.recipientIDs = myBuddyList;
					_umCollectionNode.publishItem(msgItem);
				}
			}
			
			if (_umCollectionNode && _umCollectionNode.isSynchronized && !_umCollectionNode.isNodeDefined(NODENAME_BUDDY_NOTIFICATIONS) && anonymousPresence) {
				var nodeBuddyNotifierConfig:NodeConfiguration = new NodeConfiguration();
				nodeBuddyNotifierConfig.readValueObject(_userListNodeConfig.createValueObject());
				nodeBuddyNotifierConfig.userDependentItems = true;
				nodeBuddyNotifierConfig.publishModel = UserRoles.VIEWER; //Double Check
				nodeBuddyNotifierConfig.allowPrivateMessages = true;
				if (_umCollectionNode.canUserConfigure(myUserID)) {
					_umCollectionNode.createNode(NODENAME_BUDDY_NOTIFICATIONS, nodeBuddyNotifierConfig);
				}
			}
			
		}


		/**
		 * @private
		 */
		protected function onNodeCreate(p_evt:CollectionNodeEvent):void
		{			
			if (_umCollectionNode.isSynchronized && p_evt.nodeName==NODENAME_USER_LIST && !_isTemplating) {
				// so, here we've already synched up to the userManager, but we're receiving the userList node
				// later. This typically means we were in the lobby (role 5) and not able to see the userList
				createUser(_myUserDescriptor);
			}
			
			if (_umCollectionNode.isSynchronized && p_evt.nodeName==NODENAME_USER_LIST) {
				createBuddyNode();
			}
			
			if (_umCollectionNode.isSynchronized && p_evt.nodeName==NODENAME_BUDDY_NOTIFICATIONS) {
				if (myBuddyList && myBuddyList.length > 0) {
					var msgItem:MessageItem =  new MessageItem(NODENAME_BUDDY_NOTIFICATIONS,SIMPLE_BUDDY_PRESENCE_CHANGE,myUserID);
					msgItem.recipientIDs = myBuddyList;
					_umCollectionNode.publishItem(msgItem);
				}
			}
			
			if (p_evt.nodeName != StreamManager.AUDIO_STREAM && p_evt.nodeName != StreamManager.CAMERA_STREAM && p_evt.nodeName != StreamManager.SCREENSHARE_STREAM
					&& p_evt.nodeName != StreamManager.REMOTE_CONTROL_STREAM && p_evt.nodeName != NODENAME_PING_LIST
					&& p_evt.nodeName != NODENAME_USER_LIST && p_evt.nodeName != NODENAME_VOICE_STATUS_LIST ) {
				// it's a custom field
				_customFieldNames.push(p_evt.nodeName);
				dispatchEvent(new UserEvent(UserEvent.CUSTOM_FIELD_REGISTER,null, p_evt.nodeName));
			}
		}
		
		/**
		 * @private
		 */
		 protected function onNodeDelete(p_evt:CollectionNodeEvent):void
		 {
		 	if ( _customFieldNames.length == 0 ) {
		 		return ;
		 	}
		 	
		 	var i:int = 0 ;
		 	
		 	for ( i= 0 ; i < _customFieldNames.length ; i++ ) {
		 		if (_customFieldNames[i] == p_evt.nodeName ) {
		 			_customFieldNames.splice(i,1);
							
		 			for ( i = 0 ; i < userCollection.length ; i++ ) {
		 				var userD:UserDescriptor = userCollection.getItemAt(i) as UserDescriptor;
		 				removeUserFromCollection(userD);
		 				delete userD.customFields[p_evt.nodeName] ;
		 				addUserToCollection(userD);
		 			}
					
		 			dispatchEvent(new UserEvent(UserEvent.CUSTOM_FIELD_DELETE, null, p_evt.nodeName));
		 			
		 			break ;
		 		}
		 	}
		 }


		/**
		 * @private
		 */
		protected function onItemReceive(p_evt:CollectionNodeEvent):void
		{
			var userD:UserDescriptor ;
			if (p_evt.nodeName==NODENAME_USER_LIST) {
				userReceivedOrEdited(p_evt);
				if (_waitingUsersList.length > 0 && anonymousPresence) {
					for (var i:int=0; i >= _waitingUsersList.length; i++) {
						getUserDescriptor(_waitingUsersList[i]);
					}
					_waitingUsersList = new Array();
				}
			}
			else if(p_evt.nodeName == NODENAME_PING_LIST) {
				// Fold the change into the descriptor.
				
				userD = getUserDescriptor(p_evt.item.associatedUserID);
				if (userD==null || p_evt.item.body["latency"]==null) {
					// fail silently, it's possible this was a race
				} else {
					// TODO : nigel : custom Sorting
					// fold the change into the current userDescriptor
					
					userD.latency = p_evt.item.body.latency;
					userD.lastUpdated = p_evt.item.timeStamp ;
					userD.drops = p_evt.item.body.drops;
					dispatchEvent(new UserEvent(UserEvent.USER_PING_DATA_CHANGE, userD, p_evt.nodeName));
				}
			}
			else if(p_evt.nodeName == NODENAME_VOICE_STATUS_LIST) {
				// Fold the change into the descriptor.
				
				userD = getUserDescriptor(p_evt.item.associatedUserID);
				
				if (userD==null) {
					// fail silently, it's possible this was a race
				} else {
					// TODO : nigel : custom Sorting
					// fold the change into the current userDescriptor
					removeUserFromCollection(userD);
					userD.voiceStatus = p_evt.item.body.voiceStatus;
					userD.lastUpdated = p_evt.item.timeStamp ;
					addUserToCollection(userD);

					dispatchEvent(new UserEvent(UserEvent.USER_VOICE_STATUS_CHANGE, userD, p_evt.nodeName));
				}
			} else if (p_evt.nodeName == NODENAME_BUDDY_NOTIFICATIONS) {
				try{
					if (anonymousPresence && p_evt.item.body == SIMPLE_BUDDY_PRESENCE_CHANGE && p_evt.item.publisherID != myUserID && !_userDescriptorTable[p_evt.item.publisherID]) {
						getUserDescriptor(p_evt.item.publisherID);
					}
				}catch (e:Error) {
					//It just means that we have recievied an users presence information item in NODENAME_BUDDY_NOTIFICATIONS before the NODENAME_USER_LIST
					//We need to wait for the NODENAME_USER_LIST to sync.
					_waitingUsersList.push(p_evt.item.publisherID);
				}
			}			
			else if (isCustomFieldDefined(p_evt.nodeName)) {
				// received a custom field value
				userD = getUserDescriptor(p_evt.item.itemID);
				if (userD==null) {
					// fail silently, it's possible this was a race
				} else {
					// TODO : nigel : custom Sorting
					// fold the change into the current userDescriptor
					removeUserFromCollection(userD);
					userD.customFields[p_evt.nodeName] = p_evt.item.body;
					userD.lastUpdated = p_evt.item.timeStamp ;
					addUserToCollection(userD);

					dispatchEvent(new UserEvent(UserEvent.CUSTOM_FIELD_CHANGE, userD, p_evt.nodeName));
				}
			}
		}
		
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==NODENAME_USER_LIST) {
				if(p_evt.item.itemID == myUserID) {
					var item:MessageItem = p_evt.item;
					var userDesc:UserDescriptor = getUserDescriptor(item.itemID);
					dispatchEvent(new UserEvent(UserEvent.USER_BOOTED, userDesc));
				}else {
					userRemoved(p_evt);
				}
			} else if (p_evt.nodeName==NODENAME_BUDDY_NOTIFICATIONS) {
				anonymousUserRemoved(p_evt);
			} else if (isCustomFieldDefined(p_evt.nodeName)) {
				// a custom field value has been retracted
				var userD:UserDescriptor = getUserDescriptor(p_evt.item.associatedUserID);
				if (userD==null) {
					// fail silently, likely the userDescriptor was retracted already
				} else {
					// TODO : nigel : custom Sorting
					// remove the field from the descriptor
					userD.customFields[p_evt.nodeName] = null;
					dispatchEvent(new UserEvent(UserEvent.CUSTOM_FIELD_CHANGE, userD, p_evt.nodeName));
				}
			}

		}
		
		/**
		 * @private
		 */
		protected function onNodeConfigChange(p_evt:CollectionNodeEvent):void
		{
			if (_anonymousPresenceSetFlag && p_evt.nodeName == NODENAME_USER_LIST && _anonymousPresence == _umCollectionNode.getNodeConfiguration(NODENAME_USER_LIST).lazySubscription) {
				createBuddyNode();
				_anonymousPresenceSetFlag = false;
				dispatchEvent(new UserEvent(UserEvent.ANONYMOUS_PRESENCE_CHANGE));
			}
			
			if (_pendingCustomUserField && p_evt.nodeName == _pendingCustomUserField.nodeName) {
				_umCollectionNode.publishItem(_pendingCustomUserField);
				_pendingCustomUserField = null;
			}
		}
		
		/**
		 * @private
		 */
		protected function userReceivedOrEdited(p_evt:CollectionNodeEvent):void
		{
			var item:MessageItem = p_evt.item;
			var userDesc:UserDescriptor = readUserDesc(item.body);
			userDesc.lastUpdated = item.timeStamp ;
		
			var oldDesc:UserDescriptor = _userDescriptorTable[userDesc.userID] as UserDescriptor;
			if (oldDesc!=null) {
				
				// we've seen this descriptor before. What's changed?
				

				// Replace the old item in the table				
				_userDescriptorTable[userDesc.userID] = userDesc;
				// fold in any values that might have come on other nodes
				userDesc.voiceStatus = oldDesc.voiceStatus;
				userDesc.latency = oldDesc.latency;
				userDesc.drops = oldDesc.drops;
				userDesc.customFields = oldDesc.customFields;
				
				if (oldDesc.connection != userDesc.connection) {
					removeUserFromCollection(oldDesc);
					addUserToCollection(userDesc);
					dispatchEvent(new UserEvent(UserEvent.USER_CONNECTION_CHANGE, userDesc));
				}
				if (oldDesc.usericonURL != userDesc.usericonURL) {
					
					removeUserFromCollection(oldDesc);
					addUserToCollection(userDesc);

					dispatchEvent(new UserEvent(UserEvent.USER_USERICONURL_CHANGE, userDesc));
				}
				if (oldDesc.status != userDesc.status) {
					
					removeUserFromCollection(oldDesc);
					addUserToCollection(userDesc);

					dispatchEvent(new UserEvent(UserEvent.USER_STATUS_CHANGE, userDesc));
				}
				if (oldDesc.displayName != userDesc.displayName) {
					
					removeUserFromCollection(oldDesc);
					addUserToCollection(userDesc);

					dispatchEvent(new UserEvent(UserEvent.USER_NAME_CHANGE, userDesc));
				}
			} else {
				// it's completely new
				_userDescriptorTable[userDesc.userID] = userDesc;
//				addUserToList(userDesc);
				addUserToCollection(userDesc);
				if (userDesc.userID==myUserID && !_myDescriptorPublished) {
					_myDescriptorPublished = true;
					dispatchEvent(new UserEvent(UserEvent.SYNCHRONIZATION_CHANGE));
					if (_myCachedConnection!="") {
						setUserConnection(_myUserID, _myCachedConnection);
						_myCachedConnection = null;
					}
					
					if ( _connectSession.archiveManager.isPlayingBack ) {
						// we do not want to add the user who is seeing the playback...
						removeUserFromCollection(userDesc);
					}
				} else {
					dispatchEvent(new UserEvent(UserEvent.USER_CREATE, userDesc));
				}
			}
		}

		/**
		 * @private
		 */
		protected function userRemoved(p_evt:CollectionNodeEvent):void
		{
			var item:MessageItem = p_evt.item;
			var userDesc:UserDescriptor = readUserDesc(item.body);
			userDesc.lastUpdated = item.timeStamp ;

			var originalDesc:UserDescriptor = getUserDescriptor(userDesc.userID);
			delete _userDescriptorTable[userDesc.userID];			
			
//			removeUserFromList(userDesc);
			removeUserFromCollection(userDesc);
			
			dispatchEvent(new UserEvent(UserEvent.USER_REMOVE, originalDesc));
		}
		
		protected function anonymousUserRemoved(p_evt:CollectionNodeEvent):void
		{
			var originalDesc:UserDescriptor = getUserDescriptor(p_evt.item.associatedUserID);
			if (originalDesc) {
				delete _userDescriptorTable[originalDesc.userID];
				var tmpUsrDesc:UserDescriptor = new UserDescriptor();
				tmpUsrDesc.readValueObject(originalDesc.createValueObject());
				removeUserFromCollection(tmpUsrDesc);
				dispatchEvent(new UserEvent(UserEvent.USER_REMOVE, originalDesc));
			}
		}
		
		/**
		 * @private
		 */
		protected function addUserToCollection(p_descriptor:UserDescriptor):void
		{
			var idx:int;
			
			if(p_descriptor.role >= UserRoles.OWNER) {
				
				// Find out where it should go
				idx = hostCollection.length ? _sorter.findItem(hostCollection.source,
					p_descriptor, Sort.ANY_INDEX_MODE, true, compareFunction) : 0;
				
				userCollection.addItemAt(p_descriptor, idx);
				hostCollection.addItemAt(p_descriptor, idx);
			}
			else if(p_descriptor.role >= UserRoles.PUBLISHER) {
				idx = participantCollection.length ? _sorter.findItem(participantCollection.source,
					p_descriptor, Sort.ANY_INDEX_MODE, true, compareFunction) : 0;
				
				userCollection.addItemAt(p_descriptor, hostCollection.length + idx);
				participantCollection.addItemAt(p_descriptor, idx);
			}
			else if(p_descriptor.role >= UserRoles.VIEWER) {
				idx = audienceCollection.length ? _sorter.findItem(audienceCollection.source,
					p_descriptor, Sort.ANY_INDEX_MODE, true, compareFunction) : 0;
				
				userCollection.addItemAt(p_descriptor, hostCollection.length + participantCollection.length + idx);
				audienceCollection.addItemAt(p_descriptor, idx);
			}
			
			
			
		}
		
		/**
		 * @private
		 */
		protected function removeUserFromCollection(p_descriptor:UserDescriptor):void
		{
			var idx:int;
			var i:int = 0 ;
		
			if(p_descriptor.role >= UserRoles.OWNER) {
				idx = _sorter.findItem(hostCollection.source, p_descriptor, Sort.ANY_INDEX_MODE);
				if(idx != -1) {
					userCollection.removeItemAt(idx);
					hostCollection.removeItemAt(idx);
				}
			}
			else if(p_descriptor.role >= UserRoles.PUBLISHER) {
				idx = _sorter.findItem(participantCollection.source, p_descriptor, Sort.ANY_INDEX_MODE);
				if(idx != -1) {
					userCollection.removeItemAt(idx + hostCollection.length);
					participantCollection.removeItemAt(idx);
				}
			}
			else if(p_descriptor.role >= UserRoles.VIEWER) {
				idx = _sorter.findItem(audienceCollection.source, p_descriptor, Sort.ANY_INDEX_MODE);
				if(idx != -1) {
					userCollection.removeItemAt(idx + hostCollection.length + participantCollection.length);
					audienceCollection.removeItemAt(idx);
				}
			}
			
		}
		
		
		/**
		 * @private
		 */
		protected function compareFunction(a:Object, b:Object, fields:Array=null):int
		{
			if(a is UserDescriptor && b is UserDescriptor) {
				if (a.userID == b.userID) return 0;
				
				if(a.userID == myUserID) return -1;
				if(b.userID == myUserID) return 1;
				
				if(a.status == b.status || a.voiceStatus == b.voiceStatus) {
					if(String(a.displayName+a.userID).toLowerCase() < String(b.displayName+b.userID).toLowerCase()) return -1;
					else if(String(b.displayName+b.userID).toLowerCase() < String(a.displayName+a.userID).toLowerCase()) return 1;
					else return 0;
				}

				if( a.voiceStatus != UserVoiceStatuses.OFF) return -1;
				if( b.voiceStatus != UserVoiceStatuses.OFF) return 1;			
				if(String(a.displayName+a.userID).toLowerCase() < String(b.displayName+b.userID).toLowerCase()) return -1;
				if(String(b.displayName+b.userID).toLowerCase() < String(a.displayName+a.userID).toLowerCase()) return 1;
			}
			
			return 0;
		}
		
		/**
		* @private
		*/		
		protected function readUserDesc(p_vO:Object):UserDescriptor
		{
			var newUD:UserDescriptor = new UserDescriptor();
			newUD.readValueObject(p_vO);
			try {
				newUD.role = connectSession.sessionInternals.messaging_internal::messageManager.messaging_internal::getRootUserRole(newUD.userID);
			} catch (e:Error) {
				if ( newUD.role == -1 )
					newUD.role = newUD.affiliation;
				
			}
			
			return newUD;
		}

	}
}
