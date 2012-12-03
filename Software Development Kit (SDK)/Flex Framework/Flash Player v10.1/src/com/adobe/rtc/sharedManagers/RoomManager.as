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
	import com.adobe.coreUI.localization.Localization;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.RoomManagerEvent;
	import com.adobe.rtc.events.UserQueueEvent;
	import com.adobe.rtc.messaging.MessageItem;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.sharedModel.UserQueue;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
	 * Dispatched either when the RoomManager has received everything up to the current 
	 * state of the room or when it has lost connection to the service.
	 *
	 * @eventType com.adobe.rtc.events.CollectionNodeEvent
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]

	/**
	 * Dispatched when the room bandwidth changes. This could happen independently 
	 * from <code>bwSelectionChange</code> when the bandwidth is set to AUTO.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="bwActualChange", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * Dispatched when the selected room bandwidth changes. This could happen independently 
	 * than <code>bwActualChange</code>. 
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="bwSelectionChange", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * Dispatched when the value of "auto promote" changes.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="autoPromoteChange", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * Dispatched when the room state changes.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="roomStateChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * Dispatched when the room goes from private to public and vice-versa.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="guestsHaveToKnockChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * Dispatched when the user limit for the room changes. Defaults to NO_TIME_OUT meaning no timeout.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="roomUserLimitChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * Dispatched when the time out for the room changes. Defaults to NO_USER_LIMIT meaning no timeout.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="roomTimeOutChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * Dispatched when the room Lock value changes.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="roomLockChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * Dispatched when guests not allowed parameter is changed.
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="roomGuestsNotAllowedChange", type="com.adobe.rtc.events.RoomManagerEvent")]
	/**
	 * @private
	 * Dispatched <code>_autoDisconnectTimerMinutes</code> after the host is left 
	 * alone in the room. The host has 60 seconds to call <code>postponeAutoDisconnect</code> 
	 * or the connection will be closed and <code>autoDisconnectDisconnected</code> will 
	 * be thrown.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="autoDisconnectWarning", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched every second between the <code>autoDisconnectWarning</code> event and 
	 * the <code>autoDisconnectDisconnected</code> events. Use <code>autoDisconnectSecondsLeft
	 * </code> to get the number of seconds remaining before the disconnect happens.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="autoDisconnectWarningTick", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched 60 seconds after <code>autoDisconnectWarning</code> and after the 
	 * connection to the server is closed.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="autoDisconnectDisconnected", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched if the host calls <code>postponeAutoDisconnect</code> between the 
	 * warning and the disconnection or if some other user joined during that time. 
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="autoDisconnectCanceled", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched <code>_noHostTimerMinutes</code> after the last host left the room.
	 * The viewers have 60 seconds to finish up what they were doing before 
	 * they get disconnected and <code>noHostDisconnected</code> will be thrown.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="noHostWarning", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched every second between the <code>noHostWarning</code> event and the 
	 * <code>noHostDisconnected</code> events. Use <code>noHostSecondsLeft</code> to 
	 * get the number of seconds remaining before the disconnect happens.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="noHostWarningTick", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched 60 seconds after <code>noHostWarning</code> and after the connection 
	 * to the server is closed.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="noHostDisconnected", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * @private
	 * Dispatched if a host comes in between the warning and the disconnection.
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="noHostCanceled", type="com.adobe.rtc.events.RoomManagerEvent")]

	/**
	 * Dispatched when the end-meeting message changes. 
	 * 
	 * @eventType com.adobe.rtc.events.RoomManagerEvent
	 */
	[Event(name="endMeetingMessageChange", type="com.adobe.rtc.events.RoomManagerEvent")]


	/**
	 * One of the "4 pillars" of a room, the RoomManager is responsible for handling all 
	 * runtime configuration changes to the room. Note that the APIs called here 
	 * (as they are for all sharedManagers) are asynchronous: changes won't be reflected 
	 * until the server has validated them and returned the result to all clients. At that 
	 * point, RoomManager will dispatch the appropriate event. General areas covered by 
	 * the RoomManager include: 
	 * <ul>
	 * <li><strong>Room state</strong>: Open, closed, etc.
	 * <li><strong>Room privacy settings</strong>: Determines if guests must knock to enter.
	 * <li><strong>Room bandwidth settings</strong>: The specified room bandwidth.
	 * </ul>
	 * <p>
	 * Only a user with an owner role may modify room settings. Many of these settings 
	 * can be declared <b>the first time the room is made</b> by using IConnectSession's 
	 * <code class="property">initialRoomSettings</code> property and by specifying a <code>RoomSettings</code> 
	 * object. 
	 * <p>Each IConnectSession handles creation/setup of its own RoomManager instance.  Use an <code>IConnectSession</code>'s
	 * <code class="property">roomManager</code> property to access it.</p>
	 * <blockquote>
	 * <b>Note</b>: You can configure room settings programmatically or via the Room Console.
	 * Some settings are owned by the RoomSettings class, and others by the RoomManager class.
	 * Room settings are saved with any templates created from the room.
	 * </blockqoute><p></p>
	 * <img src="../../../../devimages/dc_roomsettings.png" alt="LCCS room settings">
	 * 
	 * @see com.adobe.rtc.session.RoomSettings
	 * @see com.adobe.rtc.messaging.UserRoles
	 * @see com.adobe.rtc.events.RoomManagerEvent
	 * @see com.adobe.rtc.session.IConnectSession
	 */
   public class  RoomManager extends EventDispatcher implements ISessionSubscriber
	{
		/**
		 * The name of the collectionNode used to represent the RoomManager's shared model.
		 */
		public static const COLLECTION_NAME:String = "RoomManager";
		
		/**
		 * @private
		 */
		protected const NODE_BW_SELECTION:String = "bwSelected";
		
		/**
		 * @private
		 */
		protected const NODE_BW_ACTUAL:String = "bwActual";
		
		/**
		 * @private
		 */
		protected const NODE_AUTO_PROMOTE:String = "autoPromote";
		
		/**
		 * @private
		 */
		protected const NODE_ROOM_STATE:String = "roomState";
		
		/**
		 * @private
		 */
		protected const NODE_GUESTS_HAVE_TO_KNOCK:String = "guestsHaveToKnock";
		
		/**
		 * @private
		 */
		protected const NODE_HOST_IN_THE_ROOM:String = "hostInTheRoom";
		
		/**
		 * @private
		 */
		protected const NODE_KNOCKINGQUEUE_QUEUE:String = "knockingQueue_queue";
		
		/**
		 * @private
		 */
		protected const NODE_KNOCKINGQUEUE_NOTIFICATIONS:String = "knockingQueue_notifications";
		
		/**
		 * @private
		 */
		protected const NODE_USER_ALONE:String = "userAlone";
		
		/**
		 * @private
		 */
		protected const NODE_MEETING_ENDED:String = "meetingEnded";
		
		/**
		 * @private
		 */
		protected const NODE_HOST_LEFT:String = "hostLeft";
		/**
		 * @private
		 */
		protected const NODE_ROOM_ACCESS:String = "roomAccess";
		
		/**
		 * @private
		 */
		protected const NODE_END_MEETING_MSG:String = "endMeetingMsg";
		
		/**
		 * @private
		 */
		protected const NODE_ROOM_BW_SETTINGS:String = "roomBwSettings";
		
		/**
		 * @private 
		 */
		protected const NODE_SERVICE_LEVEL_REFRESH:String = "serviceLevelRefresh";

		/**
		 * @private
		 */
		protected const NODE_ROOM_SETTINGS:String = "roomSettings";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_PRODUCT_NAME:String = "productName";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_ROOM_URL:String = "roomURL";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_ROOM_NAME:String = "roomName";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_AUTO_DISCONNECT_MINUTES:String = "autoDisconnectAfterMinutes";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_NO_HOST_TIMER_MINUTES:String = "noHostTimerMinutes";
		
		/**
		 * @private
		 */
		protected const ROOM_SETTINGS_ITEM_ACCOUNT_SETTINGS_URL:String = "accountSettingsURL";
		
		/**
		 * @private
		 */
		protected const ROOM_ACCESS_ITEM_ALLOW_DUPLICATE_USERIDS:String = "allowDuplicateUserIDs";

		/**
		 * @private
		 */
		protected const ROOM_STATE_ITEM_RECORDING_STATE:String = "recordingState";

		/**
		 * @private 
		 */
		protected const ROOM_SETTINGS_LOGOUT_URL:String = "logoutURL";

		/**
		 * @private 
		 */
		protected const ROOM_SETTINGS_SERVICE_LEVEL:String = "serviceLevel";

		/**
		 * @private 
		 */
		protected const ROOM_SETTINGS_ACCOUNT_USER_LIMIT:String = "accountUserLimit";

		/**
		 * @private
		 */
		protected const NODE_CONNECTION_SPEED_SETTINGS:String = "connectionSpeedSettings";
		/**
		 * @private
		 */
		protected const ROOM_ACCESS_ITEM_LOCKED:String = "locked";
		/**
		 * @private
		 */
		protected const ROOM_ACCESS_ITEM_GUEST_NOT_ALLOWED:String = "guestNotAllowed";
		/**
		 * @private
		 */
		protected const ROOM_ACCESS_ITEM_USER_LIMIT:String = "userLimit";
		/**
		 * @private
		 */
		protected const ROOM_ACCESS_ITEM_TIME_OUT:String = "timeOut";
		/**
		 * Constant which defines no user limit for the RoomManager.roomUserLimit property. 
		 */
		 public static const NO_USER_LIMIT:Number = -1 ;
		 /**
		 * Constant which defines no time out for the RoomManager.roomTimeOut property. 
		 */
		 public static const NO_TIME_OUT:Number = -1 ;
		/**
		 * @private
		 */
		protected var _bandwidthSelection:String;

		/**
		 * @private
		 */
		protected var _bandwidthActual:String;

		/**
		 * @private
		 */
		protected var _collectionNode:CollectionNode;
		
		/**
		 * @private 
		 */		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;

		/**
		 * @private
		 */
		protected var _userManager:UserManager;

		/**
		 * @private
		 */
		protected var _autoPromote:Boolean;	
		
		/**
		 * @private 
		 */
		protected var _allowDuplicateUserIDs:Boolean = true;
		
		/**
		 * @private
		 */
		protected var _roomState:String;
		/**
		 * @private
		 */
		protected var _roomLocked:Boolean = false;
		/**
		 * @private
		 */
		protected var _guestNotAllowed:Boolean = false;
		/**
		 * @private
		 */
		protected var _roomTimeout:Number = RoomManager.NO_TIME_OUT ;
		/**
		 * @private
		 */
		protected var _roomUserLimit:Number = RoomManager.NO_USER_LIMIT;
		/**
		 * @private
		 */
		protected var _screenSharing:Boolean;
		
		/**
		 * @private
		 */
		protected var _roomName:String;
		
		/**
		 * @private
		 */
		protected var _roomURL:String;
		
		/**
		 * @private
		 */ 
		protected var _bwTable:Object;

		/**
		 * @private
		 */ 
		protected var _connectionSettingsTable:Object;
		
		/**
		 * @private
		 */
		protected var _knockingQueue:UserQueue;
		
		/**
		 * @private
		 */
		protected var _guestsHaveToKnock:Boolean;
		
		/**
		 * @private
		 */
		protected var _autoDisconnectWhenAlone:Boolean = true;	//TODO: make this configurable in the future

		/**
		 * @private
		 */
		protected var _autoDisconnectSecondsTimer:Timer;

		/**
		 * @private
		 */
		protected var _autoDisconnectWhenNoHost:Boolean = true;	//TODO: make this configurable in the future
				
		/**
		 * @private
		 */
		protected var _noHostSecondsTimer:Timer;
		
		/**
		 * @private
		 */
		protected var _hostIsInTheRoom:Boolean = false;
		/**
		 * @private
		 */
		protected var _meetingIsEnded:Boolean = false;

		/**
		 * @private
		 */
		protected var _endMeetingMessage:String = "";
		
		/**
		 * @private
		 */
		protected var _autoDisconnectTimeout:uint;
		
		/**
		 * @private
		 */
		protected var _noHostTimeout:uint;
		
		/**
		 * @private
		 */
		protected var _productName:String;
		
		/**
		 * @private
		 */
		protected var _serviceLevel:String;

		/**
		 * @private
		 */
		protected var _accountUserLimit:Number;

		/**
		 * @private
		 */
		protected var _logoutURL:String;

		/**
		 * @private
		 */
		protected var _accountSettingsURL:String;
		
		/**
		 * @private
		 */
		protected var _hasBeenModified:Boolean = false;
		

		public function RoomManager()
		{
			initializeModel();
			
			_autoDisconnectSecondsTimer = new Timer(1*1000, 60);	//tick every second
			_autoDisconnectSecondsTimer.addEventListener(TimerEvent.TIMER, onAutoDisconnectSecondsTimerTick);
			
			_noHostSecondsTimer = new Timer(1*1000, 60);	//tick every second
			_noHostSecondsTimer.addEventListener(TimerEvent.TIMER, onNoHostSecondsTimerTick);
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
		 * @private 
		 */
		public function get sharedID():String
		{
			return COLLECTION_NAME;
		}
		
		public function set sharedID(p_id:String):void
		{
			// NO-OP
		}
		
		[Bindable(event="synchronizationChange")]
		/**
		 * Returns true if the model is synchronized.
		 * 
		 * @return True if synchronized; false if not.
		 */
		public function get isSynchronized():Boolean
		{
			return _collectionNode.isSynchronized ;
		}
		
		/**
		 * @private
		 * On Closing session..
		 */
		public function close():void
		{
			//NO OP
		}
		
		/**
		 * Returns a display string corresponding to the supplied bandwidth setting. 
		 * 
		 * @param p_value One of the constants supplied by RoomSettings.
		 * 
		 * @return A display string.
		 */
		public static function getBandwidthString(p_value:String):String
		{
			var table:Object = new Object();
			table[RoomSettings.LAN] = "LAN";
			table[RoomSettings.DSL] = "DSL/Cable";
			table[RoomSettings.MODEM] = "Modem";
			return table[p_value];
		}		

		/**
		 * @private
		 * The product name.
		 */
		public function get productName():String
		{
			return Localization.impl.getString(_productName);
		}

		/**
		 * @private
		 */
		public function get serviceLevel():String
		{
			return _serviceLevel;
		}

		/**
		 * Returns the number of users this account is allowed to have connected at one time.
		 */
		public function get accountUserLimit():Number
		{
			return _accountUserLimit;
		}


		/**
		 * @private
		 */
		public function get logoutURL():String
		{
			return _logoutURL;
		}

		/**
		 * The room name, if any.
		 * 
		 * @return The room name.
		 */
		public function get roomName():String
		{
			return _roomName;
		}		

		/**
		 * The room URL.
		 * 
		 * @return The room URL.
		 */
		public function get roomURL():String
		{
			return _roomURL;
		}	

		/**
		 * @private
		 * @return 
		 * 
		 */
		public function get accountSettingsURL():String
		{
			return _accountSettingsURL;
		}
		
		/**
		 * @private
		 * @return 
		 * 
		 */
		public function	get autoDisconnectTimeout():uint
		{
			return _autoDisconnectTimeout;
		}

		/**
		 * @private
		 * @return 
		 * 
		 */
		public function get noHostTimeout():uint
		{
			return _noHostTimeout;
		}

		[Bindable(event="endMeetingMessageChange")]
		/**
		 * The message to display once a session has ended. It's important to set 
		 * this prior to ending the room since no messages may be sent once the session ends.
		 * 
		 * @return An end of meeting message.
		 */
		public function get endMeetingMessage():String
		{
			return (_endMeetingMessage == "") ? Localization.impl.getString("The host has ended the meeting. Thank you for attending.") : _endMeetingMessage;
		}

		/**
		 * @private
		 */
		public function set endMeetingMessage(p_message:String):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_END_MEETING_MSG) && _endMeetingMessage != p_message) {
				_collectionNode.publishItem(new MessageItem(NODE_END_MEETING_MSG, p_message));
			}
		}
			
		/**
		 * @private
		 * @return 
		 * 
		 */
		public function get bandwidthTable():Object
		{
			return _bwTable;
		}
		
		/**
		 * @private
		 */
		public function getBandwidthCap(p_value:String):Number
		{
			return _bwTable[p_value];
		}		
		
		/**
		 * @private
		 */
		public function get connectionSettingsTable():Object
		{
			return _connectionSettingsTable;
		}

		/**
		 * @private
		 */
		public function getConnectionSpeedUpValue(p_value:String):Number
		{
			return _connectionSettingsTable[p_value].up;
		}		

		/**
		 * @private
		 */
		public function getConnectionSpeedDownValue(p_value:String):Number
		{
			return _connectionSettingsTable[p_value].down;
		}
		
		/**
		 * @private
		 * @return 
		 * 
		 */
		public function get knockingQueue():UserQueue
		{
			return _knockingQueue;
		}
				
		
				
		/**
		 * Returns the actual bandwidth calculated by the room.
		 */
		[Bindable (event="bwActualChange")]
		public function get bandwidth():String
		{
			return _bandwidthActual;
		}
		
		/**
		 * Specifies the bandwidth setting as selected by the user with an owner role.
		 */
		[Bindable (event="bwSelectionChange")]
		public function get selectedBandwidth():String
		{
			return _bandwidthSelection;
		}
		
		/**
		 * @private
		 */
		public function set selectedBandwidth(p_bw:String):void
		{
			switch (p_bw) {
				case RoomSettings.AUTO:
					_collectionNode.publishItem(new MessageItem(NODE_BW_SELECTION, p_bw));
					break;
				case RoomSettings.MODEM:
				case RoomSettings.DSL:
				case RoomSettings.LAN:
					_collectionNode.publishItem(new MessageItem(NODE_BW_ACTUAL, p_bw));
					_collectionNode.publishItem(new MessageItem(NODE_BW_SELECTION, p_bw));
					break;
				default:
					throw new Error("Unknown value:"+p_bw);
			}
		}

		[Bindable (event="autoPromoteChange")]
		/**
		 * If true, all users with a viewer role are promoted upon entry to a publisher role.
		 * 
		 * @return True if autoPromote is on; otherwise, false.
		 */
		public function get autoPromote():Boolean
		{
			return _autoPromote;
		}
		/**
		 * @private
		 */
		public function set autoPromote(p_autoPromote:Boolean):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_AUTO_PROMOTE)) {
				if (p_autoPromote != _autoPromote) {
					_collectionNode.publishItem(new MessageItem(NODE_AUTO_PROMOTE, p_autoPromote));
					for each (var userDesc:UserDescriptor in _userManager.userCollection) {
						if (p_autoPromote && userDesc.role == UserRoles.VIEWER) {
							//promote this user
							_userManager.setUserRole(userDesc.userID, UserRoles.PUBLISHER);
						} else if (!p_autoPromote && userDesc.role == UserRoles.PUBLISHER) {
							//demote this user
							_userManager.setUserRole(userDesc.userID, UserRoles.VIEWER);
						}
					}
				}
			}	
		}
		
		/**
		 * @private
		 */
		public function set allowDuplicateUserIDs(p_allow:Boolean):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_ACCESS)) {
				if (p_allow != _allowDuplicateUserIDs) {
					_collectionNode.publishItem(new MessageItem(NODE_ROOM_ACCESS, p_allow, ROOM_ACCESS_ITEM_ALLOW_DUPLICATE_USERIDS));
				}
			}
		}
		
		/**
		 * Specifies whether the room allows users of the same userID to enter the room. If set to false, a new user who enters the room with a pre-existing userID
		 * will eject the existing user with that userID. 
		 */
		public function get allowDuplicateUserIDs():Boolean
		{
			return _allowDuplicateUserIDs;
		}
		

		[Bindable (event="guestsHaveToKnockChange")]
		/**
		 * Whether or not guests must knock and get permission before entering a room. 
		 * 
		 * @return True if guests have to knock before entering; otherwise, false.
		 */
		public function get guestsHaveToKnock():Boolean
		{
			return _guestsHaveToKnock;
		}

		/**
		 * @private
		 */
		public function set guestsHaveToKnock(p_guestsHaveToKnock:Boolean):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_GUESTS_HAVE_TO_KNOCK)) {
				if (p_guestsHaveToKnock != _guestsHaveToKnock) {
					_collectionNode.publishItem(new MessageItem(NODE_GUESTS_HAVE_TO_KNOCK, p_guestsHaveToKnock));
				}
			}	
		}

		[Bindable (event="roomStateChange")]
		/**
		 * Specifies the room state from among values supplied by RoomSettings constants.
		 * 
		 * @see com.adobe.rtc.session.RoomSettings
		 */
		public function get roomState():String
		{
			if (_meetingIsEnded) {
				return RoomSettings.ROOM_STATE_ENDED;
			} else if (!_hostIsInTheRoom) {
				return RoomSettings.ROOM_STATE_HOST_NOT_ARRIVED;
			} else {
				return _roomState;
			}
		}

		/**
		 * @private
		 */
		public function set roomState(p_roomState:String):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_STATE)) {
				if (p_roomState != roomState) {	//we have to use the getter here!
					switch (p_roomState) {
						case RoomSettings.ROOM_STATE_ENDED:
							//this is done by publishing a sessionDependentItem
							var conf:NodeConfiguration = new NodeConfiguration(UserRoles.LOBBY, UserRoles.OWNER, true, true, false, true);
							_collectionNode.createNode(NODE_MEETING_ENDED, conf);
							_collectionNode.publishItem(new MessageItem(NODE_MEETING_ENDED, true));
							break;
						case RoomSettings.ROOM_STATE_ACTIVE:
						case RoomSettings.ROOM_STATE_ON_HOLD:
							//publish the item
							//note that if the meeting has ended, the server will retract the NODE_MEETING_ENDED item
							_collectionNode.publishItem(new MessageItem(NODE_ROOM_STATE, p_roomState));
							break;
						case RoomSettings.ROOM_STATE_HOST_NOT_ARRIVED:	//this is automatic
						default:
							throw new Error("Invalid room state:"+p_roomState);
							return;
					}
				}
			}
		}
		
		
		/**
		 * Specifies whether the room access state is locked or not.
		 * If a room is locked, no new users other than hosts are allowed 
		 * to enter the room. However, users who are already inside can return to the
		 * room if they get disconnected.
		 */
		public function get roomLocked():Boolean
		{
			return _roomLocked;
		}
		
		/**
		 *@private
		 */
		public function set roomLocked(p_locked:Boolean):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_ACCESS) && p_locked != _roomLocked) {
				_collectionNode.publishItem(new MessageItem(NODE_ROOM_ACCESS, p_locked,ROOM_ACCESS_ITEM_LOCKED));
			}
		}
		
		/**
		 * @private
		 */		
		public function recordSession(p_startStop:Boolean, p_archiveID:String, p_guestsAllowed:Boolean=true, p_collections:Object=null, p_streams:Object=null):void
		{
			if (p_startStop) {
				var item:MessageItem = new MessageItem(NODE_ROOM_STATE, null, ROOM_STATE_ITEM_RECORDING_STATE);
				if (p_collections==null && p_streams==null) {
					// it's the full session
					item.body = {fullSession:true, archiveID:p_archiveID, guestsAllowed:p_guestsAllowed};
				} else {
					// individual collections/streams. Unsupported for now.					
				}
				_collectionNode.publishItem(item);
			} else {
				if (p_collections==null && p_streams==null) {
					// it's the full session
					_collectionNode.retractItem(NODE_ROOM_STATE, ROOM_STATE_ITEM_RECORDING_STATE);
				} else {
					// individual collections/streams. Unsupported for now.
				}
			}
		}
		
		/**
		 * Specifies whether the room currently allows guests or not.
		 * If this parameter is true, then no new guests are allowed.
		 * However, note the following: xxx
		 * <ul>
		 * <li>Those with roles higher than guests can enter.</li>
		 * <li>Guests who are already inside the room can return if they are disconnected.</li>
		 * </ul>
		 * 
		 */
		public function get guestsNotAllowed():Boolean
		{
			return _guestNotAllowed;
		}
		
		/**
		 * @private
		 */
		public function set guestsNotAllowed(p_guestNotAllowed:Boolean):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_ACCESS) && p_guestNotAllowed != _guestNotAllowed) {
				_collectionNode.publishItem(new MessageItem(NODE_ROOM_ACCESS,p_guestNotAllowed,ROOM_ACCESS_ITEM_GUEST_NOT_ALLOWED));
			}
		}
		
			
		/**
		 * Specifies the number of users permitted to enter the room. 
		 * Only users with the role UserRoles.OWNER can set this property. 
		 * Defaults to NO_USER_LIMIT
		 */
		public function get roomUserLimit():Number
		{
			return _roomUserLimit;
		}
		
		/**
		 *@private
		 */
		public function set roomUserLimit(p_userLimit:Number):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_ACCESS) && p_userLimit != _roomUserLimit) {
				_collectionNode.publishItem(new MessageItem(NODE_ROOM_ACCESS, p_userLimit,ROOM_ACCESS_ITEM_USER_LIMIT));
			}
		}
		
		
		/**
		 * Specifies a timeout duration (in seconds) for the room after which the room session ends. 
		 * Only users with role UserRoles.OWNER can set this property. 
		 * Defaults to NO_TIME_OUT, meaning there is no timeout duration.
		 */
		public function get roomTimeOut():Number
		{
			return _roomTimeout;
		}
		
		/**
		 * @private
		 */
		public function set roomTimeOut(p_roomTimeOut:Number):void
		{
			if (_collectionNode.canUserPublish(_userManager.myUserID, NODE_ROOM_ACCESS) && p_roomTimeOut != _roomTimeout) {
				_collectionNode.publishItem(new MessageItem(NODE_ROOM_ACCESS,p_roomTimeOut,ROOM_ACCESS_ITEM_TIME_OUT));
			}
		}
		

		/**
		 * @private
		 */
		public function postponeAutoDisconnect():void
		{
			if (_autoDisconnectSecondsTimer.running)
			{
				//prevent the current auto-disconnect
				_autoDisconnectSecondsTimer.stop();
				 
				_collectionNode.publishItem(new MessageItem(NODE_USER_ALONE, null));
				//this will restart the timer on the server
			}
		}
		
		
		/**
		 * @private
		 */
		public function postponeNoHostAutoDisconnect():void
		{
			if (_noHostSecondsTimer.running)
			{
				//prevent the current auto-disconnect
				_noHostSecondsTimer.stop();
				 
				_collectionNode.publishItem(new MessageItem(NODE_HOST_LEFT, null));
				//this will restart the timer on the server
			}
		}

		/**
		 * @private
		 */
		public function get autoDisconnectSecondsLeft():uint
		{
			return Math.max(0, _autoDisconnectSecondsTimer.repeatCount-_autoDisconnectSecondsTimer.currentCount);
			//The Math.max is because we might have to lie to account for some latency, the interval is on the server
		}
				
		/**
		 * @private
		 */
		protected function onAutoDisconnectSecondsTimerTick(p_evt:TimerEvent):void
		{
			dispatchEvent(new RoomManagerEvent(RoomManagerEvent.AUTO_DISCONNECT_WARNING_TICK));
		}

		/**
		 * @private
		 */
		public function get noHostSecondsLeft():uint
		{
			return Math.max(0, _noHostSecondsTimer.repeatCount-_noHostSecondsTimer.currentCount);
		}
		
		/**
		 * @private
		 */
		protected function onNoHostSecondsTimerTick(p_evt:TimerEvent):void
		{
			dispatchEvent(new RoomManagerEvent(RoomManagerEvent.NO_HOST_WARNING_TICK));			
		}
				
		/**
		 * @private
		* Tells the manager to retrieve items from the network (used in ConnectSession).
		*/
		public function subscribe():void
		{
			_userManager = _connectSession.userManager;
			initializeModel();
			
			_collectionNode = new CollectionNode();
			_collectionNode.sharedID = COLLECTION_NAME;
			_collectionNode.connectSession = _connectSession;
			_collectionNode.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
			_collectionNode.addEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
			_collectionNode.subscribe();
			
			_knockingQueue = new UserQueue();
			_knockingQueue.addEventListener(UserQueueEvent.ITEM_UPDATE,onKnockingQueueUpdate);
			_knockingQueue.collectionNode = _collectionNode;
			_knockingQueue.nodeNameQueue = NODE_KNOCKINGQUEUE_QUEUE ;
			_knockingQueue.nodeNameNotification = NODE_KNOCKINGQUEUE_NOTIFICATIONS ;
			_knockingQueue.roleForRequesting = UserRoles.LOBBY ;
			_knockingQueue.roleForManaging = UserRoles.OWNER ;
			_knockingQueue.userDependentQueueItems = true ;
			_knockingQueue.sessionDependentQueueItems = true ;
			_knockingQueue.sharedID = "knocking_UserQueue" ;
			_knockingQueue.connectSession = _connectSession;
			_knockingQueue.subscribe();
		}


		/**
		 * @private 
		 */
		public function refreshServiceLevel():void
		{
			if (_collectionNode.canUserConfigure(_userManager.myUserID)) {
				if (!_collectionNode.isNodeDefined(NODE_SERVICE_LEVEL_REFRESH)) {
					var nodeConfig:NodeConfiguration = new NodeConfiguration();
					nodeConfig.accessModel = UserRoles.OWNER;
					nodeConfig.publishModel = UserRoles.OWNER;
					nodeConfig.persistItems = false;
					_collectionNode.createNode(NODE_SERVICE_LEVEL_REFRESH, nodeConfig);
				}
				var msgItem:MessageItem = new MessageItem(NODE_SERVICE_LEVEL_REFRESH, true);
				_collectionNode.publishItem(msgItem);
			}
		}

		/**
		 * @private
		 */
		protected function onItemReceive(p_event:CollectionNodeEvent):void
		{
			var item:MessageItem = p_event.item;
			if (item.publisherID!="__server__") {
				_hasBeenModified = true;
			}
			switch (item.nodeName) {
				case NODE_BW_SELECTION:
					if (String(p_event.item.body)!=_bandwidthSelection) {
						_bandwidthSelection = p_event.item.body as String;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.BW_SELECTION_CHANGE));
					}
					break;
				case NODE_BW_ACTUAL:
					if (String(p_event.item.body)!=_bandwidthActual) {
						_bandwidthActual = p_event.item.body as String;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.BW_ACTUAL_CHANGE));
					}
					break;
				case NODE_AUTO_PROMOTE:
					if (Boolean(p_event.item.body)!=_autoPromote) {
						_autoPromote = p_event.item.body as Boolean;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.AUTO_PROMOTE_CHANGE));
					}
					break;
				case NODE_ROOM_STATE:
					if (p_event.item.itemID==ROOM_STATE_ITEM_RECORDING_STATE) {
						var evt:RoomManagerEvent = new RoomManagerEvent(RoomManagerEvent.RECORDING_CHANGE);
						evt.recordingState = {isRecording:true, recordingDetails:p_event.item.body};
						dispatchEvent(evt);
					} else if (String(p_event.item.body)!=_roomState) {
						_roomState = p_event.item.body as String;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_STATE_CHANGE));
					}
					break;
				case NODE_ROOM_ACCESS:
					if ( p_event.item.itemID == ROOM_ACCESS_ITEM_LOCKED ) {
						_roomLocked = p_event.item.body ;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_LOCK_CHANGE));
					}else if ( p_event.item.itemID == ROOM_ACCESS_ITEM_GUEST_NOT_ALLOWED ) {
						_guestNotAllowed = p_event.item.body ;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_GUESTS_NOT_ALLOWED_CHANGE));
					}else if ( p_event.item.itemID == ROOM_ACCESS_ITEM_TIME_OUT ) {
						_roomTimeout = p_event.item.body ;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_TIME_OUT_CHANGE));
					}else if ( p_event.item.itemID == ROOM_ACCESS_ITEM_USER_LIMIT ) {
						_roomUserLimit = p_event.item.body ;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_USER_LIMIT_CHANGE));
					} else if (p_event.item.itemID == ROOM_ACCESS_ITEM_ALLOW_DUPLICATE_USERIDS) {
						_allowDuplicateUserIDs = item.body;
					}
					
					break;	
				case NODE_GUESTS_HAVE_TO_KNOCK:
					if (Boolean(p_event.item.body)!=_guestsHaveToKnock) {
						_guestsHaveToKnock = p_event.item.body as Boolean;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.GUESTS_HAVE_TO_KNOCK_CHANGE));
					}
					break;
				case NODE_HOST_IN_THE_ROOM:
					_hostIsInTheRoom = true;
					dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_STATE_CHANGE));
					break;
				case NODE_MEETING_ENDED:
					_meetingIsEnded = true;
					dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_STATE_CHANGE));
					if (_userManager.myUserRole < UserRoles.OWNER && isSynchronized) {
						// owners get to stay in ended rooms
						_connectSession.logout();
					}
					break;
				case NODE_END_MEETING_MSG:
					if (String(p_event.item.body)!=_endMeetingMessage) {
						_endMeetingMessage = p_event.item.body as String;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.END_MEETING_MESSAGE_CHANGE));
					}
					break;
				case NODE_USER_ALONE:
					if (item.body == "warning") {
						_autoDisconnectSecondsTimer.reset();
						_autoDisconnectSecondsTimer.start();
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.AUTO_DISCONNECT_WARNING));
					} else if (item.body == "out") {
						//close the connection
						_meetingIsEnded = true;
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.AUTO_DISCONNECT_DISCONNECTED));
						_connectSession.logout();
						//tell people
					} else if (item.body == null) {
						//postponed
						_autoDisconnectSecondsTimer.reset();
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.AUTO_DISCONNECT_CANCELED));					
					}
					break;
				case NODE_HOST_LEFT:
					if (item.body == "warning") {
						_noHostSecondsTimer.reset();
						_noHostSecondsTimer.start();
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.NO_HOST_WARNING));
					} else if (item.body == "out") {

						_noHostSecondsTimer.reset();
						_meetingIsEnded = true;
						//tell people
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.NO_HOST_DISCONNECTED));			
						//close the connection
						_connectSession.logout();
			
					} else if (item.body == null) {
						//the server retracted the item
						_noHostSecondsTimer.reset();
						dispatchEvent(new RoomManagerEvent(RoomManagerEvent.NO_HOST_CANCELED));
					}
					break;
				case NODE_ROOM_SETTINGS:
					switch (item.itemID) {
						case ROOM_SETTINGS_ITEM_ACCOUNT_SETTINGS_URL:
						{
							_accountSettingsURL = item.body as String;
							break;
						}
						case ROOM_SETTINGS_ITEM_AUTO_DISCONNECT_MINUTES:
						{
							_autoDisconnectTimeout = item.body as uint;
							//no event required, this doesn't change mid-meeting
							break;
						}
						case ROOM_SETTINGS_ITEM_NO_HOST_TIMER_MINUTES:
						{
							_noHostTimeout = item.body as uint;
							//no event required, this doesn't change mid-meeting
							break;
						}
						case ROOM_SETTINGS_ITEM_PRODUCT_NAME:
						{
							_productName = item.body as String;
							//no event required, this doesn't change mid-meeting
							break;
						}
						case ROOM_SETTINGS_ITEM_ROOM_NAME:
						{
							_roomName = item.body;
                            dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_NAME_CHANGE));
							break;
						}
						case ROOM_SETTINGS_ITEM_ROOM_URL:
						{
							_roomURL = item.body;
                            //no event required, this is always fetched when required
							break;
						}
						case ROOM_SETTINGS_LOGOUT_URL : 
						{
							_logoutURL = item.body;
                            //no event required, this is always fetched when required
							break;
						}
						case ROOM_SETTINGS_SERVICE_LEVEL : 
						{
							_serviceLevel = item.body;
							dispatchEvent(new RoomManagerEvent(RoomManagerEvent.SERVICE_LEVEL_CHANGE));
							break;
						}
						case ROOM_SETTINGS_ACCOUNT_USER_LIMIT : 
						{
							_accountUserLimit = item.body;
							break;
						}

					}
				case NODE_ROOM_BW_SETTINGS:
					_bwTable[item.itemID] = item.body;
					break;
				case NODE_CONNECTION_SPEED_SETTINGS:
					_connectionSettingsTable = item.body;
					dispatchEvent(new RoomManagerEvent(RoomManagerEvent.CONNECTION_SPEED_SETTINGS_CHANGE));
					break;
			}
		}

		/**
		 * @private
		 */
		protected function onItemRetract(p_event:CollectionNodeEvent):void
		{
			var item:MessageItem = p_event.item;
			switch (item.nodeName) {
				case NODE_MEETING_ENDED:
					_meetingIsEnded = false;
					dispatchEvent(new RoomManagerEvent(RoomManagerEvent.ROOM_STATE_CHANGE));
					break;
				case NODE_ROOM_STATE:
					if (item.itemID==ROOM_STATE_ITEM_RECORDING_STATE) {
						var evt:RoomManagerEvent = new RoomManagerEvent(RoomManagerEvent.RECORDING_CHANGE);
						evt.recordingState = {isRecording:false};
						dispatchEvent(evt);
					}
					break;
			}
		}
		
		
		/**
		 * @param p_event The event to handle.
		 * @private
		 */		
		protected function onSynchronizationChange(p_event:CollectionNodeEvent):void
		{
			if(_collectionNode.isSynchronized) {
				if(!_hasBeenModified && _collectionNode.canUserConfigure(_userManager.myUserID))
				{
					var roomSettings:RoomSettings = _connectSession.initialRoomSettings;
					
					//bwSelect && bwActual
					_collectionNode.createNode(NODE_BW_SELECTION); 
					//_collectionNode.createNode(NODE_BW_ACTUAL); - this has to be created on the server
					
					_collectionNode.publishItem(new MessageItem(NODE_BW_SELECTION, roomSettings.roomBandwidth));
					
					// auto promote
					_collectionNode.createNode(NODE_AUTO_PROMOTE);
					_collectionNode.publishItem(new MessageItem(NODE_AUTO_PROMOTE, roomSettings.autoPromote));
					
					//roomState
					var nodeConfigurationForRoomState:NodeConfiguration = new NodeConfiguration(UserRoles.LOBBY, UserRoles.OWNER);						
					_collectionNode.createNode(NODE_ROOM_STATE, nodeConfigurationForRoomState);
					_collectionNode.publishItem(new MessageItem(NODE_ROOM_STATE, roomSettings.roomState));
					
					//guestHaveToKnock (use same nodeConfiguration as roomstate)
					_collectionNode.createNode(NODE_GUESTS_HAVE_TO_KNOCK, nodeConfigurationForRoomState);
					_collectionNode.publishItem(new MessageItem(NODE_GUESTS_HAVE_TO_KNOCK, roomSettings.guestsMustKnock));	

					//the node will be empty until the first host arrives (in this case right now)
					var conf:NodeConfiguration = new NodeConfiguration(UserRoles.LOBBY, UserRoles.OWNER, true, true, false, true);
					_collectionNode.createNode(NODE_HOST_IN_THE_ROOM, conf);
					
					conf = new NodeConfiguration(UserRoles.LOBBY, UserRoles.OWNER);
					_collectionNode.createNode(NODE_END_MEETING_MSG, conf);
					_collectionNode.publishItem(new MessageItem(NODE_END_MEETING_MSG, _endMeetingMessage));	//"" means default, the getter will do the right thing
					
					//NODE_ROOM_URL is created on the server
					//NODE_ROOM_NAME is created on the server
				}
				if (!_hostIsInTheRoom && _collectionNode.canUserConfigure(_userManager.myUserID)) {
					//I'm the first host, publish the item to the node
					_collectionNode.publishItem(new MessageItem(NODE_HOST_IN_THE_ROOM, true));
				}
				
				var tempConf:NodeConfiguration;
				
				if (!_collectionNode.isNodeDefined(NODE_USER_ALONE) && _collectionNode.canUserConfigure(_userManager.myUserID, NODE_USER_ALONE))
				{
					//new session, create the node
					tempConf = new NodeConfiguration();
					tempConf.accessModel = UserRoles.LOBBY;
					tempConf.publishModel = UserRoles.LOBBY;
					tempConf.persistItems = false;
//					tempConf.userDependentItems = false;	//doesn't mean anything since persistItems=false
//					tempConf.sessionDependentItems = false;	//doesn't mean anything since persistItems=false
					_collectionNode.createNode(NODE_USER_ALONE, tempConf);
					//the server-side intervals populate this with either "warning" or "out", and it becomes null when someone else enters or some client calls postponeAutoDisconnect
				}
				
				
				if (!_collectionNode.isNodeDefined(NODE_ROOM_ACCESS) && _collectionNode.canUserConfigure(_userManager.myUserID, NODE_ROOM_ACCESS))
				{
					//new session, create the node
					tempConf = new NodeConfiguration();
					tempConf.accessModel = UserRoles.LOBBY;
					tempConf.publishModel = UserRoles.OWNER;
					tempConf.itemStorageScheme = NodeConfiguration.STORAGE_SCHEME_MANUAL ;
					_collectionNode.createNode(NODE_ROOM_ACCESS, tempConf);
					//the server-side intervals populate this with either "warning" or "out", and it becomes null when someone else enters or some client calls postponeAutoDisconnect
				}

				if (!_collectionNode.isNodeDefined(NODE_HOST_LEFT) && _collectionNode.canUserConfigure(_userManager.myUserID, NODE_HOST_LEFT))
				{
					//new session, create the node
					tempConf = new NodeConfiguration();
					tempConf.accessModel = UserRoles.LOBBY;
					tempConf.publishModel = UserRoles.OWNER;	//this is really only published to by the server
					tempConf.persistItems = false;
//					tempConf.userDependentItems = false;	//doesn't mean anything since persistItems=false
//					tempConf.sessionDependentItems = false;	//doesn't mean anything since persistItems=false
					_collectionNode.createNode(NODE_HOST_LEFT, tempConf);
					//the server-side intervals populate this with either "warning" or "out", and it becomes null when someone else enters or some client calls postponeAutoDisconnect
				}
			} else {
				_collectionNode.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RECEIVE, onItemReceive);
				_collectionNode.removeEventListener(CollectionNodeEvent.ITEM_RETRACT, onItemRetract);
				_collectionNode.unsubscribe();
			}

			dispatchEvent(p_event);			
		}		
		
		/**
		 * @private
		 */
		protected function initializeModel():void
		{
			//set default values
			_bwTable = new Object();
			_bwTable[RoomSettings.LAN] = 1000;
			_bwTable[RoomSettings.DSL] = 400;
			_bwTable[RoomSettings.MODEM] = 56;
			_meetingIsEnded = false;
			
			//set the default values
			_connectionSettingsTable = new Object();
			_connectionSettingsTable[RoomSettings.LAN] = {up:1000000, down:1000000};
			_connectionSettingsTable[RoomSettings.DSL] = {up:250, down:600};
			_connectionSettingsTable[RoomSettings.MODEM] = {up:28, down:40};
		}
		
		protected function onKnockingQueueUpdate(p_evt:UserQueueEvent):void
		{
			this.knockingQueue.removeEventListener(UserQueueEvent.ITEM_UPDATE,onKnockingQueueUpdate);
			if (guestsHaveToKnock && !_knockingQueue.hasEventListener(UserQueueEvent.ITEM_UPDATE) && _knockingQueue.pendingQueue.length > 0) {
				this.knockingQueue.addEventListener(UserQueueEvent.ITEM_UPDATE,onKnockingQueueUpdate);
				throw new Error("There are users waiting to knock. Please add event listener to knocking Queue in RoomManager" + 
						"and handle it to accept or deny users");
			}
		}		
	}
}
