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
package com.adobe.rtc.session
{
	// AdobePatentID="B587"
	import com.adobe.rtc.archive.ArchiveManager;
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.authentication.PlaybackAuthenticator;
	import com.adobe.rtc.core.messaging_internal;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.messaging.manager.MessageManager;
	import com.adobe.rtc.session.managers.SessionManagerBase;
	import com.adobe.rtc.session.managers.SessionManagerFMS;
	import com.adobe.rtc.session.sessionClasses.PrimarySession;
	import com.adobe.rtc.session.sessionClasses.SessionInternals;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	


	/**
	 * The <code>synchronizationChange</code> is dispatched when: 
	 * <ul>
	 *   <li>When ConnectSession establishes a connection to the service and has fully synchronized 
	 *  the major room elements such as UserManager, RoomManager, StreamManager, and FileManager.</li>
	 *   <li>When the component loses its connection to the service.</li>
	 * </ul>
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.SessionEvent")]

	/**
	 * Dispatched when there's an error on the server.
	 *
	 * @eventType com.adobe.rtc.events.SessionEvent
	 */
	[Event(name="error", type="com.adobe.rtc.events.SessionEvent")]
	
	/**
	 * Dispatched when the session is closed before any children (in the case of ConnectSessionContainer) are removed.
	 */
	[Event(name="close", type="com.adobe.rtc.events.ConnectSessionEvent")]
	
	/**
	 * Dispatched on a regular interval to return connection statistics. 
	 * @eventType com.adobe.rtc.events.SessionEvent
	 */
	[Event(name="ping", type="com.adobe.rtc.events.SessionEvent")]
	
	/**
	 * Dispatched when the connection status changes from good to poor or disconnected.
	 * @eventType com.adobe.rtc.events.SessionEvent
	 */
	[Event(name="connectionStatusChange", type="com.adobe.rtc.events.SessionEvent")]

	/**
	 * <p>
	 * ConnectSession is the "headless" variant of IConnectSession, responsible for the concrete implementation of the
	 * interface. Free of any dependency on DisplayObject/UIComponent, it is intended as the class to use when establishing
	 * sessions via ActionScript. Standard features of IConnectSession apply : 
	 * <ul>
	 *  <li>It requires both <code class="property">roomURL</code> and <code class="property">authenticator</code>.</li> 
	 * 	<li>It is responsible for the operation of the sharedManager classes (User, Room, 
	 * Stream, File) and maintains the properties to access them.</li>
	 * </ul>
	 * 
	 * <p>
	 * ConnectSession <b>requires</b> a call to <code>login()</code> in order to begin establishing and synchronizing a session
	 * to a Room (this in comparison to ConnectSessionContainer, which may login by default). To end the session, 
	 * call <code>logout()</code>. If the session is disconnected without this method 
	 * (for example, due to network or server failure), ConnectSession will automatically reconnect.
	 * </p>
 	 * <h6>Creating a session via actionscript</h6>
	 *	<listing>
	 * var auth:AdobeHSAuthenticator = new AdobeHSAuthenticator();
	 * auth.userName="AdobeIDusername";
	 * auth.password="AdobeIDpassword";
	 * var session:ConnectSession = new ConnectSession();
	 * session.roomURL="http://connect.acrobat.com/fakeRoom/";
	 * session.authenticator=auth;
	 * session.login();
	 *       
	 * var webCam:WebCamera = new WebCamera();
	 * webCam.percentWidth = webCam.percentHeight = 100;
	 * addChild(webCam);
	 * </listing>
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
 	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 * @see com.adobe.rtc.sharedManagers.RoomManager
 	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.FileManager
 	 */
   public class  ConnectSession extends EventDispatcher implements IConnectSession
	{
		/**
		 * @private
		 */
		 protected var _suppressDebugTraces:Boolean = false ;
		/**
		 * The build number for beta bug reporting.
		 */
		public static const BUILD_NUMBER:String = "2.2.1";
		
		/**
		 * @private
		 */
		private static const Adobe_patent_B587:String = 'AdobePatentID="B587"';
		
		/**
		 * @private - A static reference to the ConnectSession TODOTODO.
		 */
		protected static var _primarySession:IConnectSession = new PrimarySession();
		
		/**
		 * ConnectSession.primarySession can be used in order to access the first IConnectSession instance created in a given application.
		 * In general, it is preferable to access a local instance of IConnectSession, which allows for multiple IConnectSessions to coexist
		 * in the application, but in a one-IConnectSession application or as a default, primarySession can be used.
		 */
		public static function get primarySession():IConnectSession
		{
			return _primarySession;
		}
		
		/**
		 * @private
		 */
		protected var _sessionManager:SessionManagerBase;
		
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
		protected var _streamManager:StreamManager;
		
		/**
		 * @private
		 */
		protected var _fileManager:FileManager;
		
		/**
		 * @private
		 */
		protected var _roomManager:RoomManager;
		/**
		 * @private
		 */
		 protected var _archiveManager:ArchiveManager ;
		
		/**
		 * @private
		 */
		protected var _connection:*;
		
		/**
		 * @private
		 */
		protected var _roomSettings:RoomSettings;
		
		/**
		 * @private
		 */
		protected var _synchedManagers:Dictionary;

		
		/**
		 * @private
		 * (Required) The room URL to connect to.
		 */
		protected  var _roomURL:String;
		
		/**
		 * @private
		 */
		protected var _authenticator:AbstractAuthenticator;
		
		/**
		 * @private
		 */
		protected var _isSynchronized:Boolean=false;		

		/**
		 * @private
		 */
		protected var _sessionInternals:SessionInternals;
		
		

		public function ConnectSession()
		{
			var pSession:PrimarySession = ConnectSession.primarySession as PrimarySession;
			if (pSession.connectSessionInstance==null) {
				pSession.connectSessionInstance = this;
			}
			_sessionInternals = new SessionInternals();

			_messageManager = new MessageManager();
			_sessionInternals.messaging_internal::messageManager = _messageManager;
			_messageManager.connectSession = this;
			_archiveManager = new ArchiveManager();
			_userManager = new UserManager();
			_userManager.connectSession = this;
			_fileManager = new FileManager();
			_fileManager.connectSession = this;
			_streamManager = new StreamManager();
			_streamManager.connectSession = this;
			_roomManager = new RoomManager();
			_roomManager.connectSession = this;
			
			//default settings
			_roomSettings = new RoomSettings();
			
			
			createCleanSynchedManagersTable();
		}

		/**
		 * @private
		 */
		protected function createCleanSynchedManagersTable():void
		{
			_synchedManagers = new Dictionary();
			_synchedManagers[_userManager]=false;
			_synchedManagers[_fileManager]=false;
			_synchedManagers[_streamManager]=false;
//			_synchedManagers[_messageManager]=false;
			_synchedManagers[_roomManager]=false;

//			_messageManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_userManager.addEventListener(UserEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_userManager.addEventListener(UserEvent.USER_BOOTED, onUserBooted);
			_fileManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_roomManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);			
		}
	
	

		/**
		 * (Required) The authenticator through which login information is passed.
		 */
		public function get authenticator():AbstractAuthenticator
		{
			return _authenticator;
		}
		
		public function set authenticator(p_auth:AbstractAuthenticator):void
		{
			_authenticator = p_auth;
		}
		
		/**
		 * @private 
		 */
		public function get sessionInternals():SessionInternals
		{
			return _sessionInternals;
		}
		
		//[Bindable (event="synchronizationChange")]
		/**
		 * [Read-only] A variable that indicates whether or not the ConnectSession is fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _isSynchronized;
		}
		
		
		/**
		 * The <code>UserManager</code> class for the current session.
		 */
		public function get userManager():UserManager
		{
			return _userManager;
		}

		/**
		 * The <code>FileManager</code> class for the current session.
		 */
		public function get fileManager():FileManager
		{
			return _fileManager;
		}

		/**
		 * The <code>StreamManager</code> class for the current session.
		 */
		public function get streamManager():StreamManager
		{
			return _streamManager;
		}

		/**
		 * The <code>RoomManager</code> class for the current session.
		 */
		public function get roomManager():RoomManager
		{
			return _roomManager;
		}
		
		/**
		 * @private
		 */
		 public function get archiveManager():ArchiveManager
		 {
		 	return _archiveManager ;
		 }

		/**
		 * @private
		 */
		public function set initialRoomSettings(p_roomSettings:RoomSettings):void
		{
			_roomSettings = p_roomSettings;
		}
		
		/**
		 * The initial room settings for the current room. Note that this property 
		 * <b>only works the FIRST TIME</b> the room receives a connection from an user 
		 * with an owner role. 
		 */
		public function get initialRoomSettings():RoomSettings
		{
			return _roomSettings;
		}
		
		/**
		 * The property to enable/disable debug traces 
		 */
		 public function get suppressDebugTraces():Boolean
		 {
		 	return DebugUtil.suppressDebugTraces;
		 }
		 
		 /**
		 * @private
		 */
		 public function set suppressDebugTraces(p_debugTrace:Boolean):void
		 {
		 	DebugUtil.suppressDebugTraces = p_debugTrace;
		 }
		 
		
		 /**
		  * Setting the archiveID instead of the defaultID
		  */
		 public function get archiveID():String
		 {
			return _archiveManager.archiveID; 
		 }
		 
		 /**
		 * @private
		 */
		 public function set archiveID(p_archiveID:String):void
		 {
			 _archiveManager.archiveID = p_archiveID ; 
		 }

		//[Bindable]
		/**
		 *  [Required] The URL of the room to which to connect.
		 */
		public function get roomURL():String
		{
			return _roomURL ;	
		}
		
		public function set roomURL(p_url:String):void
		{
			_roomURL = p_url ;
		}

		
		/**
		 * @private
		 */
		protected function onLogin(p_evt:SessionEvent):void
		{
			DebugUtil.debugTrace("RECEIVED LOGIN AT SESSION");
			var userDesc:* = p_evt.userDescriptor;
			DebugUtil.dumpObjectShallow("user descriptor from server", userDesc);
			
			// TODO : nigel : figure out these timing dependencies, can we rely on the order of retrieval?
				
			if (_connection != null) {
				//this is a reconnect
				createCleanSynchedManagersTable();
			}
			
			_userManager.myTicket = p_evt.ticket;
			
			//DO NOT TOUCH THE ORDER OF THESE
			_userManager.session_internal::myUserDescriptor = userDesc;
			
			_sessionManager.session_internal::messageManager = _messageManager;
			_messageManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onMessageMgrSync);
			_messageManager.subscribe();
		}
		
		/**
		 * @private
		 */		
		protected function onMessageMgrSync(p_evt:CollectionNodeEvent):void
		{
			_messageManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onMessageMgrSync);

			_userManager.subscribe();
			_connection = _sessionManager.session_internal::connection;
			_sessionInternals.session_internal::connection = _connection;
			// bootstrap the other managers
			
			_fileManager.subscribe();
			_streamManager.subscribe();
			_roomManager.subscribe();
			
		}
		
		/**
		 * @private
		 */
		protected function onSessionError(p_error:SessionEvent):void
		{
			if (hasEventListener(SessionEvent.ERROR)) {
				dispatchEvent(p_error);
			} else {
				throw p_error.error;
			}
		}
		
		/**
		 * @private 
		 */		
		protected function onPing(p_evt:SessionEvent):void
		{
			dispatchEvent(p_evt);
		}

		/**
		 * Logs into the RTC service. Calling login is required for using ConnectSession, as compared with ConnectSessionContainer,
		 * Which does so automatically.
		 */
		public function login():void
		{
			DebugUtil.debugTrace("LCCS SDK Version : " + BUILD_NUMBER + "    Player Version : " + Capabilities.version);
			if (_sessionManager==null) {
				if (authenticator) {
					_sessionManager = authenticator.session_internal::sessionManager;
					_sessionInternals.session_internal::sessionManager = _sessionManager;
					_sessionManager.session_internal::authenticator = authenticator;
					_archiveManager.subscribe();					
				} else {
					_sessionManager = new SessionManagerFMS();
				}
				_sessionManager.addEventListener(SessionEvent.DISCONNECT, onDisconnect);
				_sessionManager.addEventListener(SessionEvent.ERROR, onSessionError);
				_sessionManager.addEventListener(SessionEvent.LOGIN, onLogin);
				_sessionManager.addEventListener(SessionEvent.PING, onPing);
				_sessionManager.addEventListener(SessionEvent.CONNECTION_STATUS_CHANGE, onPing);
			}
            if (roomURL) {
			    _sessionManager.session_internal::roomURL = roomURL;
            }
			_sessionManager.session_internal::login();
		}

		/**
		 * Logs out and disconnects from the session.
		 */
		public function logout():void
		{
			DebugUtil.debugTrace("CONNECTSESSION:LOGOUT");
			// if we are recording and the room closes, then we should stop the recording first
			_sessionManager.session_internal::logout();							
		}

		/**
		 * Disposes all listeners to the network and framework classes. 
		 * 
		 */
		public function close(p_reason:String=""):void
		{
			dispatchEvent(new ConnectSessionEvent(ConnectSessionEvent.CLOSE, p_reason));
			
			if ( _messageManager != null ) {
				_messageManager.close();
			}
			
			logout();
		}

		
		/**
		 * @private
		 */
		protected function onDisconnect(p_evt:SessionEvent):void
		{
			if (_isSynchronized) {
				_isSynchronized = false;
				dispatchEvent(new SessionEvent(SessionEvent.SYNCHRONIZATION_CHANGE));
			}
		}
		
		/**
		 * @private
		 */
		protected function onUserBooted(p_evt:UserEvent):void
		{
			if(_userManager.myUserID == p_evt.userDescriptor.userID) {
				logout();
			}
		}

		/**
		 * @private
		 */
		protected function checkManagerSync(p_evt:Event):void
		{
			if (isSynchronized) {
				DebugUtil.debugTrace("checkManagerSync: we should not get here!");
				return;
			}

			DebugUtil.debugTrace("checkManagerSync:"+p_evt.target);
			_synchedManagers[p_evt.target] = true;
			for (var i:* in _synchedManagers) {
				if (!_synchedManagers[i]) {
					return;
				}
			}
			if ( (_roomManager.roomState == RoomSettings.ROOM_STATE_ACTIVE || _roomManager.roomState == RoomSettings.ROOM_STATE_HOST_NOT_ARRIVED) && _userManager.myUserRole <= UserRoles.LOBBY && (_roomManager.guestsHaveToKnock == true) ) {
				_roomManager.knockingQueue.request("",_userManager.getUserDescriptor(_userManager.myUserID).createValueObject());
			}

//			_messageManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_userManager.removeEventListener(UserEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_fileManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);
			_roomManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, checkManagerSync);			

			_isSynchronized = true;
			dispatchEvent(new SessionEvent(SessionEvent.SYNCHRONIZATION_CHANGE));
			_sessionManager.session_internal::isSynchronized = true;
			if (_roomManager.roomState == RoomSettings.ROOM_STATE_ENDED && _userManager.myUserRole < UserRoles.OWNER) {
				logout();
			}
		}
		
		
		
	}
}
