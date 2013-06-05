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
package com.adobe.rtc.session.sessionClasses
{
	import com.adobe.rtc.archive.ArchiveManager;
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.events.SessionEvent;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.RoomSettings;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;

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
	 * SessionContainerProxy is a specialized IConnectSession implementor used by UIComponent-based ISessionSubscribers
	 * to find the IConnectSession to which they should be associated. Upon finding the right IConnectSession, SessionContainerProxy
	 * proxies its implementation to that IConnectSession instance.
	 * <p>
	 * UIComponent-based ISessionSubscribers have 3 places to choose from in order to find an appropriate IConnectSession : 
	 * <ol>
	 * <li>An IConnectSession directly assigned to that component by a developer</li>
	 * <li>A ConnectSessionContainer which is in the parent chain of that component, if one exists</li>
	 * <li>The default ConnectSession.primarySession, which proxies the first IConnectSession created in the application.</li>
	 * </ol>
	 * SessionContainerProxy does the work of the 2 latter options is most appropriate. Developers of UIComponent-based
	 * ISessionSubscriber components should use SessionContainerProxy as their default <code>connectSession</code> value.
	 * <p>
 	 * <b>Example:</b> a UIComponent-based ISessionSubscriber declares its <code>_connectSession</code> protected variable 
 	 * (for use in its public <code>connectSession</code> getter) to default to a SessionContainerProxy
	 *	<listing>
	 * protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
	 * </listing>
	 * 
	 * @see com.adobe.rtc.session.IConnectSession
	 * @see com.adobe.rtc.session.ISessionSubscriber
	 * 
	 */
   public class  SessionContainerProxy extends EventDispatcher implements IConnectSession
	{
		
		/**
		 * @private 
		 */
		protected var _connectSession:IConnectSession ;
		/**
		 * @private 
		 */
		protected var _uiComponent:UIComponent ;
		
		/**
		 * 
		 * @param p_target The UIComponent which wants to locate its ConnectSessionContainer
		 * 
		 */
		public function SessionContainerProxy(p_target:UIComponent = null)
		{
			super();
			
			_uiComponent = p_target ;
			_uiComponent.addEventListener(FlexEvent.PREINITIALIZE,onADD);
		
		}
		
		
		/**
		 * @private 
		 */
		protected function onADD(p_evt:FlexEvent):void
		{
			
			if ( !(_uiComponent.owner is UIComponent) ) {
				_connectSession = ConnectSession.primarySession ;
				return ;
			}
			
			var nextOwner:UIComponent = _uiComponent.owner as UIComponent ;
			
			while (!(nextOwner is ISessionSubscriber) && !(nextOwner is IConnectSession) ) {
				
				if ( !(nextOwner is UIComponent)) {
					break ;
				}
				
				if ( nextOwner.owner != null ) {
					nextOwner = nextOwner.owner as UIComponent ;
				} else {
					break ;
				}
				
				
			}
			
			if ( nextOwner is ISessionSubscriber ) {
				_connectSession = (nextOwner as ISessionSubscriber).connectSession ;
			}else if ( (nextOwner is IConnectSession)) {
				_connectSession = nextOwner as IConnectSession;
			}else {
				_connectSession = ConnectSession.primarySession ;
			}
		}
		
		/**
		 * @inheritdoc
		 */
		override public function addEventListener(p_type:String, p_listener:Function, p_useCapture:Boolean=false, p_priority:int=0, p_useWR:Boolean=false):void
		{
			super.addEventListener(p_type, p_listener, p_useCapture, p_priority, p_useWR);
			_connectSession.addEventListener(p_type, onConnectSessionEvent, p_useCapture, p_priority, p_useWR);
		}
		
		/**
		 * @inheritdoc
		 */
		override public function removeEventListener(p_type:String, p_listener:Function, p_useCapture:Boolean=false):void
		{
			super.removeEventListener(p_type, p_listener, p_useCapture);
			_connectSession.removeEventListener(p_type, onConnectSessionEvent, p_useCapture);
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
			_connectSession.authenticator ;
		}
		
		/**
		 *  [Required] The URL of the room to which to connect.
		 */
		public function get roomURL():String
		{
			return _connectSession.roomURL;
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
		
		/**
		 * [Read-only] A variable that indicates whether or not the ConnectSession is fully synchronized with the service.
		 */
		public function get isSynchronized():Boolean
		{
			return _connectSession.isSynchronized;
		}
		
		/**
		 * @private
		 */
		public function get sessionInternals():SessionInternals
		{
			return _connectSession.sessionInternals;
		}

		/**
		 * Logs into the RTC service. Calling login is required for using ConnectSession, as compared with ConnectSessionContainer,
		 * Which does so automatically.
		 */
		public function login():void
		{
			_connectSession.login();
		}
		
		/**
		 * Logs out and disconnects from the session.
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
		protected function onConnectSessionEvent(p_evt:Event):void
		{
			dispatchEvent(p_evt);
		}
		
	}
}
