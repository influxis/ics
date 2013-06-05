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
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.coreUI.util.StringUtils;
	import com.adobe.rtc.events.ChatEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.descriptors.ChatMessageDescriptor;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;

	
	/**
	 * Dispatched when the NoteModel has fully connected and synchronized with the service
	 * or when it loses that connection.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the list of currently typing users is updated.
	 */
	[Event(name="typingListUpdate", type="com.adobe.rtc.events.ChatEvent")]
	/**
	 * Dispatched when the timestamp time format changes.
	 */
	[Event(name="timeFormatChange", type="com.adobe.rtc.events.ChatEvent")]
	/**
	 * Dispatched when private chat is turned on or off.
	 */
	[Event(name="allowPrivateChatChange", type="com.adobe.rtc.events.ChatEvent")]
	/**
	 * Dispatched when timestamps are turned on or off.
	 */
	[Event(name="useTimeStampsChange", type="com.adobe.rtc.events.ChatEvent")]
	/**
	 * Dispatched when the message history changes; for example, when there is a new message
	 * or the messages are cleared.
	 */
	[Event(name="historyChange", type="com.adobe.rtc.events.ChatEvent")]


	/**
	 * SimpleChatModel is a model component which drives the SimpleChat pod. 
	 * Its job is to keep the shared state of the chat pod synchronized across
	 * multiple users using an internal CollectionNode. It exposes methods for 
	 * manipulating that shared model as well as events indicating when that 
	 * model changes. In general, user with the viewer role and higher can both 
	 * add new messages and view those messages.
	 * 
	 * @see com.adobe.rtc.pods.SimpleChat
	 * @see com.adobe.rtc.sharedModel.descriptors.ChatMessageDescriptor
 	 * @see com.adobe.rtc.sharedModel.CollectionNode
	 */
   public class  SimpleChatModel extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * Constant for setting the time format of timestamps to AM/PM mode.
		 */
		public static const TIMEFORMAT_AM_PM:String = "ampm";
		/**
		 * Constant for setting the time format of timestamps to 24 hour mode.
		 */
		public static const TIMEFORMAT_24H:String = "24h";
		
		/**
		 * @private
		 */
		protected const HISTORY_NODE_EVERYONE:String = "history";
		/**
		 * @private
		 */
		protected const HISTORY_NODE_PARTICIPANTS:String = "history_participants";
		/**
		 * @private
		 */
		protected const HISTORY_NODE_HOSTS:String = "history_hosts";
		
		/**
		 * @private
		 */
		protected const TYPING_NODE_NAME:String = "typing";
		/**
		 * @private
		 */
		protected const TIMEFORMAT_NODE_NAME:String = "timeformat";
		/**
		 * @private
		 */
		protected const USE_TIMESTAMPS_NODE_NAME:String = "useTimeStamps";

		/**
		 * @private
		 */
		protected const TOO_MANY_TYPING_THRESHOLD:uint = 5;
		
		/**
		 * @private
		 */
		protected const COLOR_PRIVATE:String = "990000";
		/**
		 * @private
		 */
		protected const COLOR_HOSTS:String = "0099FF";
		
		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;

		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _history:String = "";
		/**
		 * @private
		 */
		protected var _myName:String;
		/**
		 * @private
		 */
		protected var _usersTyping:ArrayCollection;
		/**
		 * @private
		 */
		protected var _userWithoutUserDescriptorTyping:ArrayCollection;
		/**
		 * @private
		 */
		protected var _typingTimer:Timer;
		/**
		 * @private
		 */
		protected var _timeFormat:String;
		/**
		 * @private
		 */
		protected var _useTimeStamps:Boolean = true;
		/**
		 * @private
		 */
		protected var _allowPrivateChat:Boolean;
		/**
		 * @private
		 */
		protected var _chatCleared:Boolean = false;
		/**
		 * @private
		 */
		protected var _isClearAfterSessionRemoved:Boolean =false;
		/**
		 * @private
		 */
		protected var _messagesSeen:Object = new Object();
		/**
		 * @private
		 */
		protected var _historyFontSize:uint = 12;
		/**
		 * @private
		 */
		protected var _accessModel:int ;
		/**
		 * @private
		 */
		protected var _publishModel:int ;
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;
		/**
		 * @private
		 */
		protected var _sharedID:String = "default_SimpleChat";
		
		/**
		 * @private 
		 */
		protected var _maxMessages:int = -1;
		
		/**
		 * The default color used in formatting messages for the user's name
		 */
		public var nameColor:Number = 0x000000;
		
		/**
		 * The default color used in formatting messages for the timestamp
		 */
		public var timeStampColor:Number = 0x999999;

		/**
		 * Constructor
		 * @param p_isClearAfterSessionRemoved Whether or not the history should be cleared once the session ends.
		 */
		public function SimpleChatModel(p_isClearAfterSessionRemoved:Boolean=false)
		{
			super();
			
			_isClearAfterSessionRemoved = p_isClearAfterSessionRemoved;
			
		}
		
		/**
		 * Tells the component to begin synchronizing with the service.  
		 * For "headless" components such as this one, this method must be called explicitly.
		 */
		 public function subscribe():void
		 {
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = sharedID ;
			_collectionNode.connectSession = _connectSession ;
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onMyRoleChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			_collectionNode.addEventListener(CollectionNodeEvent.NODE_CREATE, onConfigChange);
			_collectionNode.addEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onConfigChange);
			_collectionNode.addEventListener(CollectionNodeEvent.RECONNECT, onReconnect);
			_collectionNode.subscribe();
									
			_userManager = _connectSession.userManager;
			_userManager.addEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
			
			_usersTyping = new ArrayCollection();
			_userWithoutUserDescriptorTyping = new ArrayCollection();
			
			_typingTimer = new Timer(2000, 1);			
			_typingTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
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
		 * Disposes all listeners to the network and framework classes. Recommended for 
		 * proper garbage collection of the component.
		 */
		public function close():void
		{
			_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onMyRoleChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.removeEventListener(CollectionNodeEvent.NODE_DELETE, onNodeDelete);
			_collectionNode.removeEventListener(CollectionNodeEvent.NODE_CREATE, onConfigChange);
			_collectionNode.removeEventListener(CollectionNodeEvent.CONFIGURATION_CHANGE, onConfigChange);
			_collectionNode.unsubscribe();
			_typingTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
			_userManager.removeEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
		}
		[Bindable(event="synchronizationChange")]
		/**
		 * Determines whether the Model is connected and fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized;
		}		

		[Bindable("historyChange")]
		/**
		 * Returns the current history of chat messages as a string.
		 */		
		public function get history():String
		{
			return _history;
		}
		
		/**
		 * @private
		 */
		public function get historyFontSize():uint
		{
			return _historyFontSize;
		}

		/**
		 * @private
		 */
		public function set historyFontSize(p_size:uint):void
		{
			if ( _historyFontSize != p_size ) {
				_historyFontSize = p_size;
				//EXPENSIVE!
				_history = _history.replace(/size=\".*?\"/g, "size=\""+_historyFontSize+"\"");
				dispatchEvent(new ChatEvent(ChatEvent.HISTORY_CHANGE));
			}
		}

		/**
		 * Sends a message which is specified by the ChatMessageDescriptor.
		 * 
		 * @param p_msgDesc the message to send
		 */
		public function sendMessage(p_msgDesc:ChatMessageDescriptor):void
		{
			//do this before the returns
			if (_typingTimer.running) {
				_typingTimer.stop();
				onTimerComplete();
			}

			if (!_collectionNode.isSynchronized) {
				return;
			}

			if (StringUtils.isEmpty(p_msgDesc.msg)) {
				return;	//we don't send empty messages
			}
			
			if (p_msgDesc.recipient is String && !_allowPrivateChat) {
				//private messages are not allowed, return
				return;
			}

			p_msgDesc.displayName = _userManager.getUserDescriptor(_userManager.myUserID).displayName;
			
			var nodeName:String;
			if (p_msgDesc.role==UserRoles.VIEWER) {
				nodeName = HISTORY_NODE_EVERYONE;
			} else if (p_msgDesc.role==UserRoles.PUBLISHER) {
				nodeName = HISTORY_NODE_PARTICIPANTS;
			} else {
				nodeName = HISTORY_NODE_HOSTS;
			}
			var msg:MessageItem = new MessageItem(nodeName, p_msgDesc.createValueObject());
			if (p_msgDesc.recipient!=null) {
				msg.recipientID = p_msgDesc.recipient;
			}
			if (p_msgDesc.role>_collectionNode.getUserRole(_userManager.myUserID, nodeName)) {
				// we're sending to people better than us. We won't receive notification, so mirror this locally.
				p_msgDesc.timeStamp = (new Date()).getTime();
				addMsgToHistory(p_msgDesc);
			}
			_collectionNode.publishItem(msg);

/*			
			if (	(p_msgDesc.recipient is String)
					|| (p_msgDesc.recipient is int && p_msgDesc.recipient > _userManager.myUserRole) )
			{
				//if this is a private message we need to add a fake one to our local history
				//or if this is a message to a role higher than use, we need to add a fake one to our local history
//				addMsgToHistory(_userManager.myUserID, (new Date()).getTime(), p_msgDesc);
			}
*/
		}
		
			
		/**
		 * Gets the NodeConfiguration on a specific node in the ChatModel. If the node is not defined, it will return null
		 * @param p_nodeName The name of the node.
		 */
		public function getNodeConfiguration(p_nodeName:String):NodeConfiguration
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				return _collectionNode.getNodeConfiguration(p_nodeName).clone();
			}
			
			return null ;
		}
		
		/**
		 * Sets the NodeConfiguration on a already defined node in chatModel. If the node is not defined, it will not do anything.
		 * @param p_nodeConfiguration The node Configuration on a node in the NodeConfiguration.
		 * @param p_nodeName The name of the node.
		 */
		public function setNodeConfiguration(p_nodeName:String,p_nodeConfiguration:NodeConfiguration):void
		{	
			if ( _collectionNode.isNodeDefined(p_nodeName)) {
				_collectionNode.setNodeConfiguration(p_nodeName,p_nodeConfiguration) ;
			}
			
		}
		
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			if ( p_publishModel < 0 || p_publishModel > 100 ) 
				return ; 
			
			var nodeConf:NodeConfiguration ;
			
			if ( _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(HISTORY_NODE_EVERYONE, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(HISTORY_NODE_HOSTS).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(HISTORY_NODE_HOSTS) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(HISTORY_NODE_HOSTS, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(HISTORY_NODE_PARTICIPANTS).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(HISTORY_NODE_PARTICIPANTS) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(HISTORY_NODE_PARTICIPANTS, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(TYPING_NODE_NAME).publishModel != p_publishModel ){
				nodeConf = _collectionNode.getNodeConfiguration(TYPING_NODE_NAME) ;
				nodeConf.publishModel = p_publishModel ;
				_collectionNode.setNodeConfiguration(TYPING_NODE_NAME, nodeConf ) ;
			}
			
			
		}
		
		/**
		 * The role value required for publishing to the chat
		 */
		public function get publishModel():int
		{
			return _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			if ( p_accessModel < 0 || p_accessModel > 100 ) 
				return ; 
			
			var nodeConf:NodeConfiguration ;
			
			if ( _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).accessModel != p_accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE) ;
				nodeConf.accessModel = p_accessModel ;
				_collectionNode.setNodeConfiguration(HISTORY_NODE_EVERYONE, nodeConf ) ;
			}
			
			if ( _collectionNode.getNodeConfiguration(TYPING_NODE_NAME).accessModel != p_accessModel ){
				nodeConf = _collectionNode.getNodeConfiguration(TYPING_NODE_NAME) ;
				nodeConf.accessModel = p_accessModel ;
				_collectionNode.setNodeConfiguration(TYPING_NODE_NAME, nodeConf ) ;
			}	
			
		}
		
		/**
		 * The role value required for accessing the chat history
		 */
		public function get accessModel():int
		{
			// the access model remains always same for HISTORY_NODE_PARTICIPANTS and HISTORY_NODE_HOSTS..
			// any change is only for everyone and typing node, so we return that value
			return _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).accessModel;
		}
		
		
		
		/**
		 *  Returns the role of a given user for the chat.
		 * 
		 * @param p_userID UserID of the user in question
		 */
		public function getUserRole(p_userID:String):int
		{
			return (_collectionNode.isSynchronized) ? _collectionNode.getUserRole(p_userID) : 5;
		}
		
		/**
		 *  Sets the role of a given user for the chat.
		 * 
		 * @param p_userID UserID of the user whose role we are setting
		 * @param p_userRole Role value we are setting
		 */
		public function setUserRole(p_userID:String ,p_userRole:int,p_nodeName:String=null):void
		{
			if ( p_userID == null ) 
				return ;
				
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
			
			if (p_nodeName) {
				if ( _collectionNode.isNodeDefined(p_nodeName)) {
					 _collectionNode.setUserRole(p_userID,p_userRole,p_nodeName);
				}else {
					throw new Error("SimpleChatModel: The node on which role is being set doesn't exist");
				}
			}else {
				_collectionNode.setUserRole(p_userID,p_userRole);
			}
		}
		
		/**
		 * Clears all chat history. Note that only a user with role UserRoles.OWNER may clear the chat
		 */
		public function clear():void
		{
			if (_collectionNode.isSynchronized && _collectionNode.canUserConfigure(_userManager.myUserID)) {
				_collectionNode.removeNode(HISTORY_NODE_EVERYONE);
				_collectionNode.createNode(HISTORY_NODE_EVERYONE, new NodeConfiguration(UserRoles.VIEWER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE, _allowPrivateChat, false, false, _maxMessages));
				_collectionNode.removeNode(HISTORY_NODE_PARTICIPANTS);
				_collectionNode.createNode(HISTORY_NODE_PARTICIPANTS, new NodeConfiguration(UserRoles.PUBLISHER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
				_collectionNode.removeNode(HISTORY_NODE_HOSTS);
				_collectionNode.createNode(HISTORY_NODE_HOSTS, new NodeConfiguration(UserRoles.OWNER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
				_messagesSeen = new Object();
			}
		}
		
		/**
		 * Specifies the format of timestamps (see the constants on this class). 
		 * Note that only a user with a publisher role or higher can change this setting.
		 */
		public function get timeFormat():String
		{
			return _timeFormat;
		}
		
		/**
		 * @private
		 */
		public function set timeFormat(p_timeFormat:String):void
		{
			switch (p_timeFormat) {
				case TIMEFORMAT_24H:
				case TIMEFORMAT_AM_PM:
					break;
				default:
					throw new Error("invalid time format");
					return;
			}
			
			if (_timeFormat == p_timeFormat) {
				return;
			}
			
			if (_collectionNode.canUserPublish(_userManager.myUserID, TIMEFORMAT_NODE_NAME)) {
				_collectionNode.publishItem(new MessageItem(TIMEFORMAT_NODE_NAME, p_timeFormat));
			}
		}

		/**
		 * Specifies whether or not to display timestamps next to each message. 
		 * Only users with a publisher role or higher can configure this setting.
		 */
		public function get useTimeStamps():Boolean
		{
			return _useTimeStamps;
		}
		
		/**
		 * @private
		 */
		public function set useTimeStamps(p_useThem:Boolean):void
		{
			if (_useTimeStamps == p_useThem) {
				return;
			}
			
			if (_collectionNode.canUserPublish(_userManager.myUserID, USE_TIMESTAMPS_NODE_NAME)) {
				_collectionNode.publishItem(new MessageItem(USE_TIMESTAMPS_NODE_NAME, p_useThem));
			}
		}

		/**
		 * Specifies whether private chat is allowed. Note that only users with the
		 * owner role can configure this setting.
		 */
		public function get allowPrivateChat():Boolean
		{
			return _allowPrivateChat;
		}

		/**
		 * @private
		 */
		public function set allowPrivateChat(p_allowIt:Boolean):void
		{
			if (_allowPrivateChat == p_allowIt) {
				return;
			}
			
			if (_collectionNode.canUserConfigure(_userManager.myUserID, HISTORY_NODE_EVERYONE)) {
				var oldConfig:NodeConfiguration = _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE);
				var newConfig:NodeConfiguration = new NodeConfiguration();
				newConfig.readValueObject(oldConfig.createValueObject());
				newConfig.allowPrivateMessages = p_allowIt;
				_collectionNode.setNodeConfiguration(HISTORY_NODE_EVERYONE, newConfig);
			}
		}
		
		/**
		 * @private 
		 */
		protected var _maxMessagesPending:Boolean = false;
		
		/**
		 * @private 
		 */
		public function set maxSavedMessages(p_max:int):void
		{
			if (_collectionNode && _collectionNode.isSynchronized && _collectionNode.isNodeDefined(HISTORY_NODE_EVERYONE)) {
				var config:NodeConfiguration = _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE);
				if (config.maxQueuedItems!=p_max) {
					config = config.clone();
					config.maxQueuedItems = p_max;
					_collectionNode.setNodeConfiguration(HISTORY_NODE_EVERYONE, config);
				}
				_maxMessagesPending = false;
			} else {
				_maxMessages = p_max;
				_maxMessagesPending = true;
			}
			
		}
		
		/**
		 * Specifies the number of messages that should be saved by the service. Only the last number of messages specified will be kept on the service;
		 * older messages are forgotten. Note that this only affects newcomers to the room - the chat client will remember all messages it has seen while
		 * it was in the room. Newcomers depend on the service to bring them "up to speed", so this will specify how much history is important for them
		 * to fetch upon their arrival. Also note, only a user with OWNER level credentials may set this property.
		 */
		public function get maxSavedMessages():int
		{
			if (_collectionNode.isSynchronized) {
				return _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).maxQueuedItems;
			} else {
				return _maxMessages;
			}
		}

		/**
		 * Returns a list of currently typing users as a string.
		 */
		public function get usersTyping():String
		{
			var res:String = "";
			for (var i:uint=0; i<_usersTyping.length; i++) {
				var userID:String = String(_usersTyping.getItemAt(i));
				var desc:UserDescriptor = _userManager.getUserDescriptor(userID);
				
				if ( _connectSession.archiveManager && _connectSession.archiveManager.isPlayingBack ) {
					if (desc != null) {
						res+=((res=="") ? "" : ", ")+desc.displayName;
					}
				}else {
					if (desc != null && userID!=_userManager.myUserID) {
						res+=((res=="") ? "" : ", ")+desc.displayName;
					}
				}
			}
			return res;
		}
		
		/**
		 * Updates the model to notify others that the current user is typing. This is automatically withdrawn after 2 seconds, unless this method is called again
		 * during that time, at which point the 2 second timeout is reset. Typically, chaining this call to a TextInput's CHANGE event is effective - iAmTyping will 
		 * avoid re-broadcasting the notification if not needed.
		 */
		public function iAmTyping():void
		{			
			if (!_collectionNode.isSynchronized) {
				//too early, ignore
				return;
			}
			
			if (	!_usersTyping.contains(_userManager.myUserID)
					&& _usersTyping.length < TOO_MANY_TYPING_THRESHOLD
			) {
				//I'm not typing yet and we're below the threshold, publish my item
				_collectionNode.publishItem(new MessageItem(TYPING_NODE_NAME, _userManager.myUserID, _userManager.myUserID));
				
				//the receiveItem will start the timer
			}				

			//Extend the timer if it's running (and it's only running if we received our own typing item)
			if (_typingTimer.running) {
				_typingTimer.reset();
				_typingTimer.start();
			}	
		}
		
		/**
		 * @private
		 */
		protected function onTimerComplete(p_evt:TimerEvent=null):void
		{
			//I am no longer typing
			if (_usersTyping.contains(_userManager.myUserID)) {
				_collectionNode.retractItem(TYPING_NODE_NAME, _userManager.myUserID);
			}
		}
		
		/**
		 * @private
		 */
		protected function onReconnect(p_evt:CollectionNodeEvent):void
		{
			_history = "";
			_messagesSeen = new Object();
			_chatCleared = true;
			dispatchEvent(new ChatEvent(ChatEvent.HISTORY_CHANGE));
		}
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_event:CollectionNodeEvent):void
		{
			_myName = (_userManager.getUserDescriptor(_userManager.myUserID) as UserDescriptor).displayName;
			if (_collectionNode.isSynchronized) {
				//if the node doesn't exist and I'm a host, create it empty so that viewers can publish to it
				if (!_collectionNode.isNodeDefined(HISTORY_NODE_EVERYONE) && _collectionNode.canUserConfigure(_userManager.myUserID)) {
					_collectionNode.createNode(HISTORY_NODE_EVERYONE, new NodeConfiguration(UserRoles.VIEWER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE, true, false, false, _maxMessages));
					_collectionNode.createNode(HISTORY_NODE_PARTICIPANTS, new NodeConfiguration(UserRoles.PUBLISHER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					_collectionNode.createNode(HISTORY_NODE_HOSTS, new NodeConfiguration(UserRoles.OWNER, UserRoles.VIEWER, true, false, false, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_QUEUE));
					_collectionNode.createNode(TYPING_NODE_NAME, new NodeConfiguration(UserRoles.VIEWER, UserRoles.VIEWER, true, false, true, _isClearAfterSessionRemoved, NodeConfiguration.STORAGE_SCHEME_MANUAL));
					//create by publishing the default
					_collectionNode.publishItem(new MessageItem(TIMEFORMAT_NODE_NAME, TIMEFORMAT_AM_PM));
					//create by publishing the default
					_collectionNode.publishItem(new MessageItem(USE_TIMESTAMPS_NODE_NAME, true));
					_userManager = _connectSession.userManager;
				} else if (_collectionNode.isNodeDefined(HISTORY_NODE_EVERYONE) && _maxMessagesPending) {
					maxSavedMessages = _maxMessages;
				}
			}
			
			dispatchEvent(p_event);
		}
		
		/**
		 * @private
		 */
		protected function onItemReceive(p_event:CollectionNodeEvent):void
		{
			var item:MessageItem = p_event.item;
			//Not using tmpUsrDesc. Just fetching the user descriptor as it might be required in the future.
			if (_userManager) {
				var tmpUsrDesc:UserDescriptor;
				if (item.publisherID) {
					tmpUsrDesc = _userManager.getUserDescriptor(item.publisherID);
				} else {
					tmpUsrDesc = _userManager.getUserDescriptor(item.itemID);
				}
			}

			switch (item.nodeName)
			{
			case HISTORY_NODE_PARTICIPANTS:
			case HISTORY_NODE_HOSTS:
			case HISTORY_NODE_EVERYONE:
				//add it to the history
				var msgDesc:ChatMessageDescriptor = new ChatMessageDescriptor();
				msgDesc.readValueObject(item.body);
				if (_messagesSeen[item.itemID]) {
//					return;
				}
				_messagesSeen[item.itemID] = true;
				if (item.recipientID!=null) {
					msgDesc.recipient = item.recipientID;
				}
				if (item.nodeName==HISTORY_NODE_HOSTS) {
					msgDesc.role = UserRoles.OWNER;
				} else if (item.nodeName==HISTORY_NODE_PARTICIPANTS) {
					msgDesc.role = UserRoles.PUBLISHER;
				}
/*				
				if ( (msgDesc.recipient is String && msgDesc.recipient != _userManager.myUserID) //it's a private but not for me
					|| (msgDesc.recipient is int && msgDesc.recipient > _userManager.myUserRole) )	//it's for a role higher than mine
				{
					//ignore this message
					//TODO: Nigel: I shouldn't be getting this at all!
					return;	
				}
*/				
				msgDesc.timeStamp = item.timeStamp;
				msgDesc.publisherID = item.publisherID;
				addMsgToHistory(msgDesc);				
				break;
			case TYPING_NODE_NAME:
				if (!_usersTyping.contains(item.itemID)) {
					if (item.itemID == _userManager.myUserID) {
						_usersTyping.addItem(item.itemID);
						//we got our own item back, start the timer
						_typingTimer.reset();
						_typingTimer.start();
						dispatchEvent(new ChatEvent(ChatEvent.TYPING_LIST_UPDATE));
					} else if (_userManager.getUserDescriptor(item.itemID)) {
						_usersTyping.addItem(item.itemID);
						dispatchEvent(new ChatEvent(ChatEvent.TYPING_LIST_UPDATE));
					} else {
						_userWithoutUserDescriptorTyping.addItem(item.itemID);
					}
					
				}
				break;
			case TIMEFORMAT_NODE_NAME:
				_timeFormat = item.body;
				dispatchEvent(new ChatEvent(ChatEvent.TIME_FORMAT_CHANGE));
				break;
			case USE_TIMESTAMPS_NODE_NAME:
				_useTimeStamps = item.body;
				dispatchEvent(new ChatEvent(ChatEvent.USE_TIME_STAMPS_CHANGE));
				break;
			}
		}
		
		/**
		 * @private
		 */
		protected function onUserDescriptorFetch(p_evt:UserEvent):void
		{
			if (_userWithoutUserDescriptorTyping.contains(p_evt.userDescriptor.userID)) {
				_usersTyping.addItem(p_evt.userDescriptor.userID);
				dispatchEvent(new ChatEvent(ChatEvent.TYPING_LIST_UPDATE));
				_userWithoutUserDescriptorTyping.removeItemAt(_userWithoutUserDescriptorTyping.getItemIndex(p_evt.userDescriptor.userID));
			}
		}
		
		/**
		 * @private
		 */
		protected function getNameColor(p_msgDesc:ChatMessageDescriptor):String
		{
			if (p_msgDesc.recipient!=null) {
				// it was a message I sent privately to another
				return COLOR_PRIVATE;
			} else if (p_msgDesc.role>UserRoles.VIEWER)	{
				// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
				return COLOR_HOSTS;
			} else {
				return nameColor+"";
			}
		}
		
		/**
		 * @private
		 */
		protected function getMsgColor(p_msgDesc:ChatMessageDescriptor):String
		{
			if (p_msgDesc.recipient!=null) {
				// it was a message I sent privately to another
				return COLOR_PRIVATE;
			} else if (p_msgDesc.role>UserRoles.VIEWER)	{
				// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
				return COLOR_HOSTS;
			} else {
				return p_msgDesc.color.toString(16);
			}
		}
		
		/**
		 * @private
		 */
		protected function getTimeStampColor(p_msgDesc:ChatMessageDescriptor):String
		{
			if (p_msgDesc.recipient!=null) {
				// it was a message I sent privately to another
				return COLOR_PRIVATE;
			} else if (p_msgDesc.role>UserRoles.VIEWER)	{
				// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
				return COLOR_HOSTS;
			} else {
				return timeStampColor+"";
			}
		}
		
		/**
		 * Formats a given MessageDescriptor into a readable string
		 * @param p_msgDesc the desired ChatMessageDescriptor to format
		 */
		public function formatMessageDescriptor(p_msgDesc:ChatMessageDescriptor):String
		{
			var timeStampStr:String = "";
			
			var nameColor:String = getNameColor(p_msgDesc);
			var msgColor:String = getMsgColor(p_msgDesc);
			var tStampColor:String = getTimeStampColor(p_msgDesc);
			var privateModifier:String = "";
			if (p_msgDesc.publisherID == _userManager.myUserID && p_msgDesc.recipient!=null) {
				// it was a message I sent privately to another
				privateModifier = " ("+Localization.impl.getString("to")+" "+p_msgDesc.recipientDisplayName+")";
			} else if (p_msgDesc.role>UserRoles.VIEWER)	{
				// it was a message sent to a role group, and I can see it (either because I sent it or am in the group)
				privateModifier = " ("+Localization.impl.getString("to")+" "+((p_msgDesc.role == UserRoles.OWNER)? Localization.impl.getString("hosts") : Localization.impl.getString("participants"))+")";
			} else if (p_msgDesc.recipient!=null) {
				// it was a message sent privately to me
				privateModifier = " ("+Localization.impl.getString("privately")+")";
			}

			if (_useTimeStamps && !isNaN(p_msgDesc.timeStamp)) {
				var d:Date = new Date(p_msgDesc.timeStamp);
				//var hourMinutes:Array = d.toTimeString().split(":").slice(0,2);
				var hourMinutes:Array = [d.getHours(),d.getMinutes()];
				if (hourMinutes[1] < 10) {	//pad minutes if needed
					hourMinutes[1] = "0"+hourMinutes[1];
				}
				if (_timeFormat == TIMEFORMAT_AM_PM) {
					var timeTemplate:String = Localization.impl.getString("%12%:%M% %D%");
					timeTemplate = timeTemplate.replace("%M%", hourMinutes[1]);
					var h:uint = hourMinutes[0];
					if (h >= 12) {
						h -= 12;
						timeTemplate = timeTemplate.replace("%D%", Localization.impl.getString("pm"));
					} else {
						timeTemplate = timeTemplate.replace("%D%", Localization.impl.getString("am"));
					}
					if (h == 0) {
						timeStampStr = timeTemplate.replace("%12%", "12");
					} else {
						timeStampStr = timeTemplate.replace("%12%", h);
					}
				} else {
					timeStampStr = hourMinutes[0]+":"+hourMinutes[1];
				}
				timeStampStr = "<font color=\"#"+parseInttoHex(tStampColor) +"\">["+timeStampStr+"]</font> ";
			}

			var msg:String = p_msgDesc.msg;
			msg = msg.replace(/</g, "&lt;");
			msg = msg.replace(/>/g, "&gt;");
			
			//TODO: make these colors come from a style!
			var toAdd:String;
			toAdd = "<font size=\""+_historyFontSize+"\">"
					+timeStampStr
					+"<font color=\"#"+parseInttoHex(nameColor)+"\"><b>"+p_msgDesc.displayName+privateModifier+"</b>: </font>"
					+"<font color=\"#"+parseInttoHex(msgColor)+"\">"+msg+"</font>"
					+"</font><br/>";
			
			return toAdd;
		}
		
		/**
		 * @private
		 */
		protected function addMsgToHistory(p_msgDesc:ChatMessageDescriptor):void
		{
			var toAdd:String = formatMessageDescriptor(p_msgDesc);				
			
			if (_chatCleared) {
				_history=toAdd;
				_chatCleared = false;
				dispatchEvent(new ChatEvent(ChatEvent.HISTORY_CHANGE,p_msgDesc));
			} else {
				_history+=toAdd;
				dispatchEvent(new ChatEvent(ChatEvent.HISTORY_CHANGE, p_msgDesc));
			}
			
		}
		
		/**
		 * @private
		 */
		protected function onItemRetract(p_evt:CollectionNodeEvent):void
		{
			var item:MessageItem = p_evt.item;

			if (item.nodeName == TYPING_NODE_NAME)
			{
				if (_usersTyping.contains(item.itemID)) {
					_usersTyping.removeItemAt(_usersTyping.getItemIndex(item.itemID));
					dispatchEvent(new ChatEvent(ChatEvent.TYPING_LIST_UPDATE));
				}
				
				if (_userWithoutUserDescriptorTyping.contains(item.itemID)) {
					_userWithoutUserDescriptorTyping.removeItemAt(_userWithoutUserDescriptorTyping.getItemIndex(item.itemID));	
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onNodeDelete(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName == HISTORY_NODE_EVERYONE) {
				_chatCleared = true;
				_history = "<font size=\""+_historyFontSize+"\" color=\"#666666\"><i>"+Localization.impl.getString("The chat history has been cleared.")+'\n'+"</i></font>";
				dispatchEvent(new ChatEvent(ChatEvent.HISTORY_CHANGE));
			}
		}
		
		/**
		 * @private
		 */
		protected function onConfigChange(p_evt:CollectionNodeEvent):void
		{
			if (p_evt.nodeName==HISTORY_NODE_EVERYONE) {
				var tmpAllow:Boolean = _collectionNode.getNodeConfiguration(HISTORY_NODE_EVERYONE).allowPrivateMessages;
				if (tmpAllow!=_allowPrivateChat) {
					_allowPrivateChat = tmpAllow;
					dispatchEvent(new ChatEvent(ChatEvent.ALLOW_PRIVATE_CHAT_CHANGE));
				}
			}
		}
		
		/**
		 * @private
		 * Handles the user role change event from shared stream manager
		 */
		protected function onMyRoleChange(p_evt:CollectionNodeEvent):void
		{
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 * Left Padding of hexa decimal numbers
		 */ 
		protected function parseInttoHex(p_intString:String):String
		{
			var hexLength:int = 6;
			/*if (!isNaN(Number(p_intString))) {
				p_intString = parseInt(p_intString).toString(16);
			}*/
			if (p_intString.substring(0,1) == "#") {
				p_intString = p_intString.substring(1);
			}
			
			if (p_intString.substring(0,2) == "0x") {
				p_intString = p_intString.substring(2);
			}
			
			if (p_intString.length == hexLength) {
				return p_intString;
			} else if (p_intString.length < hexLength) {
				for (var i:int = p_intString.length ; i < hexLength; i++) {
					p_intString = "0" + p_intString ;
				}
				return p_intString;
			} else {
				//shouldnt come here. Just making the method free from RTE
				return p_intString;
			}
		}
	}
}
