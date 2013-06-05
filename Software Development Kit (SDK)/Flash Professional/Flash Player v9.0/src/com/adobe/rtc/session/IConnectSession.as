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
	import com.adobe.rtc.archive.ArchiveManager;
	import com.adobe.rtc.authentication.AbstractAuthenticator;
	import com.adobe.rtc.session.sessionClasses.SessionInternals;
	import com.adobe.rtc.sharedManagers.FileManager;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	
	import flash.events.IEventDispatcher;

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
	 * IConnectSession is the interface responsible for representing a user session connected to a real-time collaboration
	 * room. IConnectSession instances have the following behavior : 
	 * <ul>
	 *  <li>It requires both <code class="property">roomURL</code> and <code class="property">authenticator</code>.</li> 
	 * 	<li>It is responsible for the operation of the sharedManager classes (User, Room, 
	 * Stream, File) and maintains the properties to access them.</li>
	 * 	<li>It is responsible for logging into and synchronizing with the service, via <code>login()</code>
	 * </ul>
	 * The principal implementors of IConnectSession are ConnectSession and ConnectSessionContainer, both of which 
	 * can be used to create new sessions to the service. 
	 * <p>
	 * Note that multiple IConnectSessions may be connected in one application simultaneously. In such cases, most RTC components
	 * will need to be associated with a particular session. Such components implement the <code>ISessionSubscriber</code> interface,
	 * exposing a <code class="property">connectSession</code> property, which should be assigned to the appropriate IConnectSession, or
	 * they will default to being associated with <code>ConnectSession.primarySession</code>,the first IConnectSession created. ISessionSubscriber
	 * instances found within ConnectSessionContainer tags are automatically associated with their ConnectSessionContainer.
	 * <p>
	 * RTC components may only be instantiated and subscribed <b>after</b> an IConnectSession has been instantiated. However, 
	 * such ISessionSubscriber components can be subscribed or added before any IConnectSession is finished synchronizing with the service.
	 * <br>
	 * @see com.adobe.rtc.session.ConnectSession
	 * @see com.adobe.rtc.session.ConnectSessionContainer
	 * @see com.adobe.rtc.session.ISessionSubscriber
 	 * @see com.adobe.rtc.session.sessionClasses.SessionContainerProxy
 	 * @see com.adobe.rtc.authentication.AdobeHSAuthenticator
	 * @see com.adobe.rtc.sharedManagers.UserManager
	 * @see com.adobe.rtc.sharedManagers.RoomManager
 	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.FileManager
	 * @see com.adobe.rtc.session.ISessionSubscriber
 	 */
	public interface IConnectSession extends IEventDispatcher
	{
		/**
		 * accessors for SharedManager classes
		 */

		/**
		 * The UserManager class for the current session.
		 */
		function get userManager():UserManager;
		/**
		 * The <code>StreamManager</code> class for the current session.
		 */
		function get streamManager():StreamManager;
		/**
		 * The <code>FileManager</code> class for the current session.
		 */
		function get fileManager():FileManager;
		/**
		 * The <code>RoomManager</code> class for the current session.
		 */
		function get roomManager():RoomManager;
		/**
		 * The <code>ArchiveManager</code> class for the current session.
		 */
		function get archiveManager():ArchiveManager;
		
		
		/**
		 * (Required) The authenticator through which login information is passed.
		 */
		function get authenticator():AbstractAuthenticator;
		function set authenticator(p_auth:AbstractAuthenticator):void;
		
		/**
		 *  [Required] The URL of the room to which to connect.
		 */
		function get roomURL():String;
		function set roomURL(p_url:String):void;
		
		/**
		 * The initial room settings for the current room. Note that this property 
		 * <b>only works the FIRST TIME</b> the room receives a connection from an user 
		 * with an owner role. 
		 */
		function get initialRoomSettings():RoomSettings;
		function set initialRoomSettings(p_settings:RoomSettings):void;
		
		/**
		 * [Read-only] A variable that indicates whether or not the ConnectSession is fully synchronized with the service.
		 */
		function get isSynchronized():Boolean;
		
		/**
		 * @private
		 */
		function get sessionInternals():SessionInternals;
		
		/**
		 * Logs into the RTC service. Calling login is required for using ConnectSession, as compared with ConnectSessionContainer,
		 * Which does so automatically.
		 */
		function login():void
		/**
		 * Logs out and disconnects from the session.
		 */
		function logout():void;
		/**
		 * Disposes all listeners to the network and framework classes. 
		 * 
		 */
		function close(p_reason:String=""):void;
		
	}
}