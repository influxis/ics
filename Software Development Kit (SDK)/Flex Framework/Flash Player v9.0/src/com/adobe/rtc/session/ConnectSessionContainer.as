/*
*
* ADOBE CONFIDENTIAL
* ___________________
*
* Copyright 2009 Adobe Systems Incorporated
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
	import com.adobe.rtc.archive.ArchiveManager;
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.sessionClasses.SessionInternals;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.util.DebugUtil;
	
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.core.ContainerCreationPolicy;
	import mx.core.UIComponentGlobals;
	
	
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
	 * Dispatched when the session is closed before any children are removed.
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
	 * ConnectSessionContainer is a Container-based tag which implements IConnectSession. 
	 * As such, an instance of ConnectSessionContainer corresponds to a session established 
	 * with an RTC room (as does any IConnectSession). Being container-based,
	 * it provides the convenience of easy expression through MXML tags.
	 * ConnectSessionContainer has the following behavior: 
	 * <ul>
	 *  <li>It requires both <code class="property">roomURL</code> and <code class="property">authenticator</code>.</li> 
	 * 	<li>It is responsible for the operation of the sharedManager classes (User, Room, 
	 * Stream, File) and maintains the properties to access them.</li>
	 *  <li>It automatically logs in when created. To prevent it from doing so, set the <code class="property">autoLogin</code> 
	 * property to false. In this case, call the <code>login()</code> method when needed. </li>
 	 *  <li>It does not instantiate any components within it until a session is fully 
	 * established and all the major sharedManagers are fully synchronized. Use the
	 * <code>synchronizationChange</code> event and the <code class="property">isSynchronized</code> property to determine 
	 * when the session is fully synchronized.
	 * 	<li>Any children of the ConnectSessionContainer are automatically associated with that particular session. If multiple ConnectSessionContainers
	 * are used, their children will be aware of which sessions they belong to.</li>
	 * </ul>
	 * If an action should be taken once the children are created, use the standard <code>creationComplete</code> event for those children.
 	 * 
	 * To end the session, call <code>logout()</code> to simply disconnect, or call <code>close()</code> 
	 * to remove all children before doing so. If the session is disconnected without these methods 
	 * (for example, due to network or server failure), ConnectSessionContainer will automatically reconnect.
	 * 
 	 * <h6>Creating a session</h6>
	 *	<listing>
	 * &lt;rtc:AdobeHSAuthenticator userName="AdobeIDusername password="AdobeIDpassword" id="auth"/&gt;
	 *       
	 *	&lt;session:ConnectSessionContainer
	 *	    roomURL="http://connect.acrobat.com/fakeRoom/" 
	 *	    authenticator="{auth}"&gt;
	 *      
	 *		&lt;pods:WebCamera width="100%" height="100%"/&gt;
	 *      
	 *	&lt;/session:ConnectSessionContainer&gt;</listing>
	 * </listing>
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
 	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 * @see com.adobe.rtc.sharedManagers.RoomManager
 	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 */
   public class  ConnectSessionContainer extends Canvas implements IConnectSession
	{
		
		/**
		 * @private 
		 */
		protected var _connectSession:ConnectSession = new ConnectSession();

		/**
		 * Whether to log in as soon as the <code>ConnectSessionContainer</code> is created (true) or wait until <code>login()</code> 
		 * is explicitly called (false).
		 * 
		 * @default true
		 */
		public var autoLogin:Boolean=true;
		
		public function ConnectSessionContainer()
		{
			super();
			creationPolicy = ContainerCreationPolicy.NONE;
			_connectSession.addEventListener(SessionEvent.SYNCHRONIZATION_CHANGE,onSynchronizationChange);
			_connectSession.addEventListener(ConnectSessionEvent.CLOSE,onClose);
		}
		
		/**
		 * @inheritdoc
		 */
		override public function addEventListener(p_type:String, p_listener:Function, p_useCapture:Boolean=false, p_priority:int=0, p_useWR:Boolean=false):void
		{
			super.addEventListener(p_type, p_listener, p_useCapture, p_priority, p_useWR);
			if (p_type==ConnectSessionEvent.CLOSE) {
				_connectSession.addEventListener(p_type, onClose, p_useCapture, p_priority, p_useWR);
			} else if (p_type==SessionEvent.SYNCHRONIZATION_CHANGE) {
				_connectSession.addEventListener(p_type, onSynchronizationChange, p_useCapture, p_priority, p_useWR);
			} else {
				_connectSession.addEventListener(p_type, onConnectSessionEvent, p_useCapture, p_priority, p_useWR);
			}
		}
		
		/**
		 * @inheritdoc
		 */
		override public function removeEventListener(p_type:String, p_listener:Function, p_useCapture:Boolean=false):void
		{
			super.removeEventListener(p_type, p_listener, p_useCapture);
			if (p_type==ConnectSessionEvent.CLOSE) {
				_connectSession.removeEventListener(p_type, onClose, p_useCapture);
			} else if (p_type==SessionEvent.SYNCHRONIZATION_CHANGE) {
				_connectSession.removeEventListener(p_type, onSynchronizationChange, p_useCapture);
			} else {
				_connectSession.removeEventListener(p_type, onConnectSessionEvent, p_useCapture);
			}
		}
		
		
		/**
		 * The <code>UserManager</code> class for the current session.
		 */
		public function get userManager():UserManager
		{
			return _connectSession.userManager;
		}
		
		/**
		 * The <code>StreamManager</code> class for the current session.
		 */
		public function get streamManager():StreamManager
		{
			return _connectSession.streamManager;
		}
		
		/**
		 * The <code>FileManager</code> class for the current session.
		 */
		public function get fileManager():FileManager
		{
			return _connectSession.fileManager;
		}
		
		/**
		 * The <code>RoomManager</code> class for the current session.
		 */
		public function get roomManager():RoomManager
		{
			return _connectSession.roomManager;
		}
		
		/**
		 * The <code>ArchiveManager</code> class for the current session.
		 */
		public function get archiveManager():ArchiveManager
		{
			return _connectSession.archiveManager;
		}
		
		/**
		 * (Required) The authenticator through which login information is passed.
		 */
		public function get authenticator():AbstractAuthenticator
		{
			return _connectSession.authenticator;
		}
		
		public function set authenticator(p_auth:AbstractAuthenticator):void
		{
			_connectSession.authenticator = p_auth ;
		}
		
		/**
		 *  [Required] The URL of the room to which to connect.
		 */
		public function get roomURL():String
		{
			return _connectSession.roomURL ;
		}
		
		public function set roomURL(p_url:String):void
		{
			_connectSession.roomURL = p_url ;
		}
		
		/**
		 * The initial room settings for the current room. Note that this property 
		 * <b>only works the FIRST TIME</b> the room receives a connection from an user 
		 * with an owner role. 
		 */
		public function get initialRoomSettings():RoomSettings
		{
			return _connectSession.initialRoomSettings;
		}
		
		public function set initialRoomSettings(p_settings:RoomSettings):void
		{
			_connectSession.initialRoomSettings = p_settings ;
		}
		
		
		[Bindable (event="synchronizationChange")]
		/**
		 * [Read-only] A variable that indicates whether or not the ConnectSession is fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _connectSession.isSynchronized;
		}
		
		/**
		 * @private
		 * Internal details pertaining to this session. 
		 */
		public function get sessionInternals():SessionInternals
		{
			return _connectSession.sessionInternals;
		}
		
		/**
		 * The property to suppress/enable debug traces. Set to true to suppress traces
		 * @default false
		 */
		public function set suppressDebugTraces(p_debugTrace:Boolean):void
		{
			DebugUtil.suppressDebugTraces = p_debugTrace;
		}
		
		/**
		 * @private
		 */
		public function get suppressDebugTraces():Boolean
		{
			return DebugUtil.suppressDebugTraces;
		}
		
		/**
		 * Setting the archiveID instead of the defaultID
		 */
		public function get archiveID():String
		{
			return _connectSession.archiveID ; 
		}
		
		/**
		 * @private
		 */
		public function set archiveID(p_archiveID:String):void
		{
			_connectSession.archiveID = p_archiveID ; 
		}

		/**
		 * Logs in and begins the process of synchronizing with the room. Note that unless <code>autoLogin</code> is set to false, 
		 * <code>login()</code> is called automatically upon the container being added to the display list. 
		 */		
		public function login():void
		{
			_connectSession.login();
		}
		
		/**
		 * Logs out and disconnects from the session. Any children built are left on 
		 * the <code>displayList</code>.
		 */
		public function logout():void
		{
			_connectSession.logout();
		}
		
		/**
		 * Disposes all listeners to the network and framework classes.
		 */
		public function close(p_reason:String=""):void
		{
			_connectSession.close(p_reason);
		}
		
		/**
		 * @private 
		 */
		protected function buildChild():void
		{
			createComponentsFromDescriptors();
			invalidateSize();
			invalidateDisplayList();
		}

		//this happens on reconnect
		/**
		 * @private
		 */
		protected function destroyChild():void
		{
/*			
			if (_childInstance) {
				var p:UIComponent = parent as UIComponent;
				p.removeChild(_childInstance);
				_childInstance = null;
				p.invalidateSize();
				p.invalidateDisplayList();
			}
			
*/
		}
		
		
		
		/**
		 * @private
		 */
		protected function onSessionError(p_error:SessionEvent):void
		{
			dispatchEvent(p_error);
		}
		
		
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_event:SessionEvent):void
		{
			if ( _connectSession.isSynchronized ) {
				buildChild();
			}
			dispatchEvent(p_event);
		}
		
		
		/**
		 * @private
		 */
		protected function onClose(p_event:ConnectSessionEvent):void
		{
			destroyChild();
			dispatchEvent(p_event);
		}


		/**
		 * @private
		 */
		protected function onConnectSessionEvent(p_event:Event):void
		{
			dispatchEvent(p_event);
		}

		
		/**
		 * @private
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			// add autoLogin
			if (!isSynchronized) {
				if ( autoLogin ) {
					_connectSession.login();
				}
			}
		}		

		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( UIComponentGlobals.designMode ) {
				minWidth = 100 ;
				minHeight = 50 ;
			}
			
			measuredWidth = measuredMinWidth = getExplicitOrMeasuredWidth();
			measuredHeight = measuredMinHeight = getExplicitOrMeasuredHeight();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			if ( UIComponentGlobals.designMode ) {
				buildChild();
				invalidateSize();
			}
			
			
		}
		
		
	}
}