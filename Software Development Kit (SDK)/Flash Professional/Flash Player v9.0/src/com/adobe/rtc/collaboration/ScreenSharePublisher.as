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
package com.adobe.rtc.collaboration
{
	
	import com.adobe.rtc.addin.*;
	import com.adobe.rtc.authentication.AdobeHSAuthenticator;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.AddInLauncherEvent;
	import com.adobe.rtc.events.CameraConfigurationEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.RoomManagerEvent;
	import com.adobe.rtc.events.ScreenShareEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.ConnectSession;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.DebugUtil;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.net.LocalConnection;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	
import flash.display.Sprite //FlashOnlyReplacement;

	/**
	 * Dispatched when the camera is accessed for publishing or is stopped.
	 */
	[Event(name="change", type="flash.events.Event")]	
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

	/**
	 * Dispatched when the user's role with respect to the component changes.
	 */
	[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
	
	/**
	 * Dispatched when the current user's webcam stream is published by the component.
	 */
	[Event(name="streamReceive", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when the current user's webcam stream stops publishing.
	 */
	[Event(name="streamDelete", type="com.adobe.rtc.events.StreamEvent")]	

	/**
	 * Dispatched when the current user's webcam stream is paused.
	 */
	[Event(name="streamPause", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when the user's camera publishing state changes.
	 */
	[Event(name="isScreenSharePublishingChanged", type="flash.events.Event")]
	
	/**
	 * Dispatched when the FPS of the camera has changed.
	 */
	[Event(name="fpsChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	
	/**
	 * Dispatched when the quality of the camera has changed.
	 */
	[Event(name="qualityChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	/**
	 * Dispatched when the jey frame interval of camera changes.
	 */
	[Event(name="keyFrameIntervalChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	/**
	 * Dispatched when the jey frame interval of camera changes.
	 */
	[Event(name="performanceChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	/**
	 * Dispatched when the jey frame interval of camera changes.
	 */
	[Event(name="bandwidthChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	/**
	 * Dispatched when the jey frame interval of camera changes.
	 */
	[Event(name="hfssChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]
	/**
	 * Dispatched when Adobe Addin is launched.
	 */
	[Event(name="launch", type="com.adobe.rtc.events.AddinLauncherEvent")]
	
	/**
	 * Dispatched when Adobe Addin failed to launch.
	 */
	[Event(name="fail", type="com.adobe.rtc.events.AddinLauncherEvent")]
	
	/**
	 * Dispatched when Adobe Addin failed to launch.
	 */
	[Event(name="stop", type="com.adobe.rtc.events.AddinLauncherEvent")]
	
	/**
	 * Dispatched when screen is controlled by other person.
	 */
	[Event(name="controlStarted", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * Dispatched when screen is controlled by other person has stopped.
	 */
	[Event(name="controlStopped", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * ScreenSharePublisher is the component responsible for publishing screen share data to other room members. It acts as an intermediary between the NetStream and
	 * StreamManager and publishes screen share StreamDescriptors to the StreamManager so that ScreenShareSubscribers in the room are aware a new stream has been
	 * initiated.  Use this to start ScreenShare, see screen share example in the SDKApps.
	 * <P>
	 * It also provides an facility to do following:
	 * <UL>
	 * <li> setting recipient ids or groupname (deprecated) for private screen sharing</li>
	 * <li> setting stream properties (frame per second, key frame Interval, qualities etc. Explain in detail in later API section.)</li>
	 * <li> setting node properties (accessModel, publishModel, groupName etc. Explain in detail in later API section.)</li>
	 * <li>launch Adobe Screen Share Addin component that has capability to do screen sharing. If Addin is not install, it will download and install on the fly.</li>
  	 * <li> manage screen share session and allow publisher to stop sharing and restart on demand.</li>
	 * </UL>
	 * <p>
	 * When ScreenSharePublisher is launched, a dialog will appear on the publisher side and ask permission to share user's desktop. Publisher user has opportunity 
	 * to select following choices: 
	 * 
	 * <UL>
	 * <li> Desktop (Your current desktop) </li>
	 * <li> Windows (any opened application window) </li>
	 * <li> Applications (any application, can have multiple windows)</li>
	 * </UL>
	 * <p>
	 * User can choose above option or he/she can also cancel the screen share.
	 * 
	 * The ScreenSharePublisher has no user interface of its own, but provides a basic API through which any commands concerning publishing screen share should be routed. 
	 * You can load publisher on stage as your display component through addChild method. By default, only users with role UserRoles.PUBLISHER or greater may publish 
	 * screen share, and all users with role of greater than UserRoles.VIEWER are able to subsribe to these streams.
	 * 
	 * Here is the example of calling sequence to use ScreenSharePublisher
	 *
	 * <div class="code panel" style="border-width: 1px;"><div class="codeContent panelContent"> 
	 * <pre class="code-java"><span class="code-keyword">import</span> com.adobe.rtc.collaboration.ScreenSharePublisher;
	 * <span class="code-keyword">var</span> sspublisher:ScreenSharePublisher = <span class="code-keyword">new</span> ScreenSharePublisher();
 	 *
	 * <span class="code-comment">//<span class="code-keyword">this</span> is optional
	 * </span><span class="code-keyword">var</span> userlist:ArrayCollection = connectSession.userManager.userCollection;
	 * <span class="code-keyword">var</span> recipientIDs:Array = <span class="code-keyword">new</span> Array();
	 * <span class="code-keyword">for</span>(<span class="code-keyword">var</span> i:<span class="code-object">int</span>=0; i&lt;userlist.length; i++){
  	 * recipientIDs.push((userlist.getItemAt(i) as UserDescriptor).userID);
	 * }
 	 *
	 * <span class="code-comment">// <span class="code-keyword">this</span> is optional, <span class="code-keyword">default</span> is everyone in the room can see the screen share
	 * </span>sspublisher.recipientIDs = recipientIDs;
 	 *
	 * <span class="code-comment">// see APIs section <span class="code-keyword">for</span> the options
	 * </span>sspublisher.quality = DEFAULT_SS_QUALITY;  
	 * sspublisher.performance = DEFAULT_SS_PERFORMANCE; 
	 * sspublisher.keyframeInterval = DEFAULT_SS_KFI; 
	 * sspublisher.fps = DEFAULT_SS_FPS;  
	 * sspublisher.enableHFSS = DEFAULT_SS_ENABLEHFSS; 
	 * sspublisher.bandwidth = DEFAULT_SS_BANDWIDTH; 
	 * sspublisher.publish();
	 * </pre> 
	 * </div></div> 
	 */		
	
public class ScreenSharePublisher extends Sprite implements ISessionSubscriber //FlashOnlyReplacement
	{
		
		// LCCS model variables
	   /**
		* ID for the node used to signal the cancellation of application control.
		*/		
	   public static const NODENAME_CANCEL_CONTROL:String = "cancelControl";
	   
		/**
		 * @private
		 * LCCS component for handling streams
		 */
		protected var _streamManager:StreamManager;
			
		/**
		 * @private
		 * LCCS component for handling users
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 * LCCS component for handling room 
		 */
		protected var _roomManager:RoomManager;
		
		/**
		 * @private
		 * @depreccated
		 * components are assigned to a group via groupName; if not specified, the component is assigned to the default, public group (the room at large).
		 */
		protected var _groupName:String = null;
		
		/**
		 * @private
		 * the person who is publishing the screen share
		 */
		 protected var _publisherID:String = null;
		
		/**
		* @private
		* The role value required for accessing screen share stream
		*/
		protected var _accessModel:int = -1 ;
		
		/**
		* @private
		* The role required for this component to publish.
		*/
		protected var _publishModel:int = -1 ;
		
		/**
		* @private
		* pecify list of users in the room who can see the screen share.  Use the userID from UserDescriptor object to form an array of users.
		*/
		protected var _recipientIDs:Array = null;
		
		/**
		* @private
		* Defines the logical location of the component on the service; typically this assigns the sharedID of the collectionNode used by the component. 
		* This is rarely needs to be updated, default value is suffice for sharing and if private stream is required use recipientIDs.
		*/
		protected var _sharedID:String = null;
		 
		/**
		* @private
		* is subscribe to all the events
		*/
		protected var _subscribed:Boolean = false ;
		 
		/**
		* TODO: do we need to have connectionSession already assigned?
		* @private 
		* This main connection session 
		*/		
		protected var _connectSession:IConnectSession = ConnectSession.primarySession;

		
		/**
		 * @private nodeConfiguration
		 * Sets the NodeConfiguration that defines message permissions and storage policies for the current stream.
		 */ 
		protected var _nodeConfiguration:NodeConfiguration = null;
		 
		// Screen Shared binary variables
		/**
		* @private
		* Returns true if the stream is paused, false if not or if there is no stream.
		*/
		protected var _isPaused:Boolean = false;

		/**
		* @private
		* Returns true if the stream is publishing and false if not.
		*/
		protected var _isPublishing:Boolean = false;
		
	
		/**
		 * @private
		 * Returns true if the Adobe Addin is launched for screen share.
		 */
		protected var _isLaunched:Boolean = false;
		 
		 
		/**
		* @private
		* Returns whether or not the screen share publisher component is synchronized.
		*/
		protected var _isSynchronized:Boolean = false;
		
		
		
		
		// flash native variable
		/**
		* @private
		* Netstream variable
		*/
		private var _stream:NetStream;


		// netstream properties
		/**
		 * @private
		 * The maximum rate for the camera to capture data in frames per second. The maximum rate possible depends on the capabilities of the camera; 
		 * that is, if the camera doesn't support the value you set here, this frame rate will not be achieved. 
		 */		
		private var _fps:Number = 4;
		
		/**
		 * @private
		 * Compression quality of the video. Defaults to 70 with 100 being the best.
		 */		 
		private var _quality:Number = 70;
		
		/**
		* @private
		* Specifies which video frames are transmitted in full (called keyframes) instead of being interpolated by the video compression algorithm. The default 
		* value is 15, which means that every 15th frame is a keyframe.
		*/		 
		private var _keyFrameInterval:Number = 15;
		
		/**
		 * @private
		 * Force screen share to use High Fidelity quality setting.  default = false
		 */ 
		private var _enableHFSS:Boolean = false;
		
		/**
		 * @private
		 * verall performance of the streaming. Defaults to 70 with 100 being the best.
		 */ 
		private var _performance:Number = 70
		
		/**
		 * @private
		 * streaming bandwidth of the uploading client.  default is 125000
		 */
		private var _bandwidth:Number = 125000
		
		// Addin Related Variables
		/**
		* @private
		*/
		private const invalidator:Invalidator = new Invalidator();
		
		/**
		* @private
		*/
		private var _addInLauncher:AddInLauncher;
		 
		/**
		* @private
		*/
		private var _addInName:String = "acaddin";
		 
		/**
		 * @private
		 * default addin
		 */
		private var _addInLocation:String = "default";
		
		/**
		* @private
		* local connection to the shell
		*/
		private var _outgoingConnection:LocalConnection;
		
		/**
		 * @private
		 * handshake connection from shell to publisher to tell it ready for outgoingConnection
		 */
		private var _handshakeConnection:LocalConnection;
		
		/**
		 * @private
		 * addin requried version
		 */
		private var _addInRequiredVersion:String = null;
		
		/**
		 * @private
		 * screen share shell swf name, default is following, 
		 * if you want to use the player10 version, change it to
		 * screenshareshell_player10_sgn.swf
		 */
		private static const PLAYER9_SSSHELLSWF:String = "screenshareshell_player9_sgn.swf"
		
		/**
		 * @private
		 * screen share shell swf name for flash player 10, 
		 */
		private static const PLAYER10_SSSHELLSWF:String = "screenshareshell_player10_sgn.swf"
		
		/**
		 * @private
		 * shell name to launch
		 */
		private var _shellName:String = PLAYER9_SSSHELLSWF;
		
		private static const PRIVATE_CONNECTION_NAME:String = "_ssincoming";
		private static const HANDSHAKE_CONNECTION_NAME:String = "_sshandshake";
		
		/**
		 * @private
		 * timer for launching the shell, try 50 times before we give up
		 */
		private var _retryTimer:Timer;
		
		/**
		 * @private
		 * try 50 times before we give up
		 */
		private var _retryCount:int = 0;
		
		/**
		 * @private
		 * launch shell url
		 */
		private var _myLaunchURL:String = null;
		
		/**
		 * @private
		 * launch shell url prefix
		 */
		private var _myLaunchURLPrefix:String = null;
		
		/**
		 * @privatef
		 * player version
		 */
		 private var _playerVersion:Number = 9;
		
		/**
		 * @private
		 * notified by handshake LC for sending publish command because addin is ready
		 */
		private var _bAddinReadyForLC:Boolean = false;
		
		/**
		 * Constructor.  Creates Instance of the ScreenSharePublisher object and set up resources needed for screen sharing.
		 */
		public function ScreenSharePublisher()
		{
super(); 
 this.addEventListener(Event.ADDED_TO_STAGE, onAddTOStage);  //FlashOnlyReplacement
		}
		
		// FLeX Begin
		/**
		 * 
		 * @private
		 * initialize components, get the url of the room and establish handshake local connection to the screen share shell
		 */
protected function onAddTOStage(p_evt:Event):void //FlashOnlyReplacement
		{
 //FlashOnlyReplacement
			
			var os:String = Capabilities.os.toLowerCase();
			
			if(os.toLowerCase().indexOf("mac") >=0) {
				_addInRequiredVersion = "Mac OS 10";
			}else if(os.toLowerCase().indexOf("windows xp") >=0) {
				_addInRequiredVersion = "Windows XP";
			}else {
				_addInRequiredVersion = "Windows";
			}
			
			// Creates the stream Manager singleton.
			if ( !_subscribed ) {
        		subscribe();
        		
        	}
        	
        	var startIndx:int = connectSession.roomURL.indexOf("http://");
        	if(startIndx < 0)
        		startIndx = connectSession.roomURL.indexOf("https://") + String("https://").length + 1;
        	else
        		startIndx = startIndx + String("http://").length + 1;
        		
        	_myLaunchURLPrefix = connectSession.roomURL.substring(0, connectSession.roomURL.indexOf("/", startIndx));
        	
        	_myLaunchURLPrefix += "/static/screenshare/";
        	
        	_myLaunchURL = _myLaunchURLPrefix + _shellName;
        	
        	_playerVersion = 9;
        			
		}
		
//[Bindable (event="streamPause")]
		/**
		 * @public
		 * if screenshare is paused
		 */
		public function get isPaused():Boolean
		{
			return _isPaused;
		}
		/**
		 * @public
		 * set which player version of screen share to use, default is 9
		 */
		public function set playerVersion(version:Number):void
		{
			if(version == 10) {
				_myLaunchURL = _myLaunchURLPrefix + PLAYER10_SSSHELLSWF;
				_playerVersion = 10;
			}
			else {
				_myLaunchURL = _myLaunchURLPrefix + PLAYER9_SSSHELLSWF;
				_playerVersion = 9;
			}
		}
		
		/**
		 * @public
		 * get which player version of screen share is using, default is 9
		 */
		public function get playerVersion():Number
		{
			return _playerVersion;
		}
		
		/**
		 * @public
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application.  Note that this may only be set once before 
		 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		/** 
		 * @public
		 * setting the connectionsession of the publisher
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * @public
		 * Defines the logical location of the component on the service; typically this assigns the sharedID of the collectionNode used by the component. This is rarely needs 
		 * to be updated, default value is suffice for sharing and if private stream is required use recipientIDs.
		 */
		public function get sharedID():String
		{
			return _sharedID;
		}
		
		/**
		 * @public
		 * setting the sharedID
		 */
		public function set sharedID(p_id:String):void
		{
			_sharedID = p_id;
		}
		
		/**
		 * @public
		 * @deprecated
		 * components are assigned to a group via groupName; if not specified, the component is assigned to the default, public group (the room at large).
		 */
		public function get groupName():String
		{
			return _groupName;
		}
		
		/**
		 * @public
		 * setting the groupname
		 */
		public function set groupName(str:String):void
		{
			_groupName = str;
		}
		
		
		/**
		 * @public
		 * The role value required for accessing screen share stream
		 */
		public function set accessModel(n:Number):void
		{
			_accessModel = n;
		}
		
		/**
		 * @public
		 * getthign the accessModel
		 */
		public function get accessModel():Number
		{
			return _accessModel;
		}
		
		
		/**
		 * @public
		 * The role required for this component to publish.
		 */
		public function set publishModel(n:Number):void
		{
			_publishModel = n;
		}
		
		/**
		 * @public
		 * getthign the accessModel
		 */
		public function get publishModel():Number
		{
			return _publishModel;
		}
		
		
		/**
		 * @public
		 * [read-only] Returns whether or not the screen share publisher component is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			return _connectSession.streamManager.isSynchronized;
		}
		
		/**
		 * @public
		 * Dispatched when the user's screen share publishing state changes.
		 */
//[Bindable("isScreenSharePublishingChanged")]
		public function get isPublishing():Boolean
		{
			return _isPublishing;
		}
		
		/**
		 * @public
		 * is addin Launched
		 */
		public function get isLaunched():Boolean
		{
			return _isLaunched;
		}
		
		/**
		 * @private
		 * Returns the Netconnection
		 */
		protected function get connection():NetConnection
		{
			return _connectSession.sessionInternals.session_internal::connection as NetConnection;
		}
		
		// netstream properties
		/**
		 * @pubic
		 * The maximum rate for the camera to capture data in frames per second. The maximum rate possible depends on the capabilities of the camera; 
		 * that is, if the camera doesn't support the value you set here, this frame rate will not be achieved. 
		 */		
		public function set fps(n:Number):void
		{
			if ( _fps == n ) 
				return ;
			_fps = n;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.FPS_CHANGED));
		}
		
		/**
		 * @public
		 * return fps
		 */
		public function get fps():Number
		{
			return _fps;
		}
		
		/**
		 * @pubic
		 * Compression quality of the video. Defaults to 70 with 100 being the best.
		 */
		public function set quality(n:Number):void
		{
			if ( _quality == n ) 
				return ;
			_quality = n;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.QUALITY_CHANGED));
		}
		
		/**
		 * @public
		 * return quality
		 */
		public function get quality():Number
		{
			return _quality;
		}
		
		/**
		 * @public
		 * Specifies which video frames are transmitted in full (called keyframes) instead of being interpolated by the video compression algorithm. The default 
		 * value is 15, which means that every 15th frame is a keyframe.
		 */ 
		public function set keyFrameInterval(n:Number):void
		{
			if ( _keyFrameInterval == n ) 
				return ;
			_keyFrameInterval = n;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.KEY_FRAME_INTERVAL_CHANGED));
		}
		
		/**
		 * @public 
		 * return keyFrameInterval
		 */
		public function get keyFrameInterval():Number
		{
			return _keyFrameInterval;
		}
		
		/**
		 * @public
		 * Force screen share to use High Fidelity quality setting.  default = false
		 */ 
		public function set enableHFSS(b:Boolean):void
		{
			if ( _enableHFSS == b ) 
				return ;
				
			_enableHFSS = b;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.HFSS_CHANGED));
		}
		
		/**
		 * @public
		 * return enableHFSS
		 */
		public function get enableHFSS():Boolean
		{
			return _enableHFSS;
		}
		
		/**
		 * @public
		 * overall performance of the streaming. Defaults to 70 with 100 being the best.
		 */
		public function set performance(n:Number):void
		{
			if ( _performance == n ) 
				return ;
				
			_performance = n;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.PERFORMANCE_CHANGED));
		}
		
		/**
		 * @public
		 * return performance
		 */
		public function get performance():Number
		{
			return _performance;
		}
		
		
		/**
		 * Bandwidth is the maxmimum bandwidth the video feed can take
		 * given other factors like quality. Default is RoomManager's current Bandwidth.
		 * For more, see bandwidth property in flash.media.Camera
		 * The value is in kilobit/sec (default is 125000)
		 *
		 * @param p_bandwidth
		 *
		 */
		public function set bandwidth(p_bandwidth:Number):void
		{
			if ( _bandwidth == p_bandwidth ) 
				return ;
				
			_bandwidth = p_bandwidth ;
			
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.BANDWIDTH_CHANGED));
		}
		
		/**
		 * @public
		 * return bandwidth
		 */
		public function get bandwidth():Number
		{
			return _bandwidth;
		}
		
		/**
		 * Array of Recipient UserIDs for ScreenShare streams published by this user.
		 * Set this property to null if you want to broadcast your camera stream to everyone. This is also the default case.
		 * 
		 * @default null
		 */
		public function set recipientIDs(p_recipientIDs:Array):void
		{
			if ( isPublishing ) {
				throw new Error("ScreenSharing in progress. Stop screenSharing and then set RecipientIDs.");
				return ;
			}
			
			if ( p_recipientIDs == null ) {
				_recipientIDs = null ;
				return ;
			}
			_recipientIDs = p_recipientIDs;
		}
		
		/**
		 * @private
		 */
		public function get recipientIDs():Array
		{
			return _recipientIDs;
		}
		
		
		/**********************************
		 * methods
		 * ********************************/
		
		/**
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if ( !_streamManager ) {
				_streamManager = _connectSession.streamManager;
				_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.addEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
				_streamManager.addEventListener(StreamEvent.STREAM_PAUSE,onStreamPause);
				_streamManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
				_streamManager.addEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
			}
			
			_connectSession.addEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
			
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
			}
   			
   			if ( !_roomManager ) {
				_roomManager = _connectSession.roomManager;  			
				_roomManager.addEventListener(RoomManagerEvent.BW_ACTUAL_CHANGE, onBwActualChange);
   			}
   			
   			_subscribed = true ;
		}
		
		/**
		 * @public
		 * Begins publishing the stream for the user identified by p_publisherID after prompting the user.
		 * this will launch Adobe Addin and set for screen share publishing
		 */
		public function publish():void
		{
			if(connectSession.isSynchronized == true &&
				!_isLaunched && !_isPublishing)
			{
				if (!_handshakeConnection) {
					_handshakeConnection = new LocalConnection();
					_handshakeConnection.allowDomain("*");
					_handshakeConnection.allowInsecureDomain("*");
					_handshakeConnection.client = this;
					_handshakeConnection.addEventListener(StatusEvent.STATUS, onStatus);
					try {
						_handshakeConnection.connect(HANDSHAKE_CONNECTION_NAME);
					}catch(e:Error) {
						DebugUtil.debugTrace("ERROR:The Connection wasn't closed properly by abrupt killing of sharing instance.\n You need to call stop screen sharing, close the client browser and addin and relaunch screen sharing again");
						_handshakeConnection = null;
					}
					
				}
				
				//try to launch shell.swf?... in the addin
				_addInLauncher = AddInLauncher.getInstance(_addInRequiredVersion, _addInName, _addInLocation);
				_addInLauncher.addEventListener(AddInLauncherEvent.LAUNCH, onLaunch);
				_addInLauncher.addEventListener(AddInLauncherEvent.FAIL, onFailedLaunch);
				
				_addInLauncher.openInAddIn(_myLaunchURL);
	
			}
		}
		
		/**
		 * @public
		 * stop screen being control by other subscriber
		 */
		public function stopBeingControlled():void
		{
			if(_outgoingConnection != null && _isLaunched)
			{
				var props:Object = new Object();
				//id?	
				_outgoingConnection.send(PRIVATE_CONNECTION_NAME, "stopBeingControlled", props);	
			
			}
		}
		
		/**
		 * Gets the NodeConfiguration that defines message permissions and storage policies for the current stream group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _streamManager.getNodeConfiguration(StreamManager.SCREENSHARE_STREAM,_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration that defines message permissions and storage policies for the current stream group.
		 * 
		 * @param p_nodeConfiguration The current stream groups node configuration.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_nodeConfiguration = p_nodeConfiguration;
			
		}
		
		/**
		 * Returns the given stream publisher or subscriber's user role within the stream's group.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _streamManager.getUserRole(p_userID,StreamManager.SCREENSHARE_STREAM,_groupName);
		}
		
		/**
		 * Sets the user role that enables publishing to the component's group specified by the <code class="property">groupName</code>. 
		 * 
		 * @param p_userID The user ID of the user whose role should be set.
		 * @param p_userRole The role value to assign to the user with this user ID.
		 */
		public function setUserRole(p_userID:String ,p_userRole:int):void
		{
			if ( p_userID == null ) 
				return ;
			
			if ( (p_userRole < 0 || p_userRole > 100) && p_userRole != CollectionNode.NO_EXPLICIT_ROLE ) 
				return ; 
				
			_streamManager.setUserRole(p_userID,p_userRole,StreamManager.SCREENSHARE_STREAM,_groupName);
		}
		
		
		/**
		 * @public
		 *Pauses or unpauses the stream specified by p_publisherID; defaults to the current user's stream.
		 *
		 */
		public function pause(p_pause:Boolean):void
		{
			if(_outgoingConnection != null)
			{
				var props:Object = new Object();
				props.pause = p_pause;
				_outgoingConnection.send(PRIVATE_CONNECTION_NAME, "pause", props);	
			}
			
		}
		
		/**
		 * @public
		 * Stops publishing the stream published by the user identified by p_publisherID; if the ID is null, it defaults to the current user's stream.
		 */
		public function stop(p_publisherid:String=null):void
		{
			if(_outgoingConnection != null && _isLaunched)
			{
				var props:Object = new Object();
				//id?
				if(p_publisherid != null){
					var streamDescriptors:Object = _streamManager.getStreamsOfType(StreamManager.SCREENSHARE_STREAM);
					
					if(streamDescriptors != null) {
						for(var id:String in streamDescriptors) {
							var desc:StreamDescriptor = streamDescriptors[id] as StreamDescriptor;
							if(desc.streamPublisherID == p_publisherid ||
								desc.originalScreenPublisher == p_publisherid) {
								props.publisherID = desc.streamPublisherID;
								break;
							}
						}
						
					}
				}
				
				_outgoingConnection.send(PRIVATE_CONNECTION_NAME, "stop", props);	
				_isLaunched = false;
				_isPublishing = false;
			}
		}
		
		/**
		 * TODO: close vs. stop?
		 * @public
		 * Disposes all listeners to the network and framework classes and assures proper garbage collection of the component.
		 */
		public function close():void
		{
			if(_isLaunched || _isPublishing) {
				stop();
			}
			
			connectSession.removeEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
			
			_roomManager.removeEventListener(RoomManagerEvent.BW_ACTUAL_CHANGE, onBwActualChange);
			
			if ( _streamManager ) {
				_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
				_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamPause);
				_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
				_streamManager.removeEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
			}
			
			if(_addInLauncher) {
				_addInLauncher.removeEventListener(AddInLauncherEvent.LAUNCH, onLaunch);
				_addInLauncher.removeEventListener(AddInLauncherEvent.FAIL, onFailedLaunch);
			}
			
			if(_outgoingConnection != null ) {
				try{
					_outgoingConnection.close();
				}catch(error:Error) {
				}
				_outgoingConnection = null;
			}
			
			if(_handshakeConnection != null) {
				try{
					_handshakeConnection.close();
				}
				catch(error:Error) {
				}
				_handshakeConnection = null;
			}
		}
		
		/**************************************
		 * EVENTS
		 *************************************/
		 
		/**
		 * @private
		 * Handles the synchronization change event from the Shared Stream Manager
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
 //FlashOnlyReplacement
			dispatchEvent(p_evt);	
		}
	
		/**
		 * @private
		 *
		 */
		protected function onStreamReceive(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if(desc.groupName != _groupName) {
				return;
			}
			
			if (desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM ) {
				return;
			}
			
			/**
			 * TODO: the id will be different than userID because shell using different id
			 */
			//if (desc.streamPublisherID != _userManager.myUserID) {
			//	return;
			//}
			if (desc.streamPublisherID != connectSession.userManager.myUserID && 
				desc.originalScreenPublisher != connectSession.userManager.myUserID) {
				return;
			}
			_isPublishing = true;
			var evt:Event = new Event("isScreenSharePublishingChanged");
			dispatchEvent(evt);
			
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 * 
		 */
		protected function onStreamDelete(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if(desc.groupName != _groupName) {
				return;
			}
			
			if (desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM ) {
				return;
			}
			
			if (desc.streamPublisherID != connectSession.userManager.myUserID && 
				desc.originalScreenPublisher != connectSession.userManager.myUserID) {
				return;
			}
			/**
			 * TODO: the id will be different than userID because shell using different id
			 */
			//if (desc.streamPublisherID != _userManager.myUserID) {
			//	return;
			//}
			
			_isPublishing = false;
			
			stop(desc.streamPublisherID);
			
			var evt:Event = new Event("isScreenSharePublishingChanged");
			dispatchEvent(evt);
			
			dispatchEvent(p_evt);
			
			if(desc.type == StreamManager.SCREENSHARE_STREAM) {
				trace("sspublisher closing lc due to stream delete");
				if(_outgoingConnection != null ) {
					try{
						_outgoingConnection.close();
					}catch(error:Error) {
					}
					_outgoingConnection = null;
				}
				
				if(_handshakeConnection != null) {
					try{
						_handshakeConnection.close();
					}
					catch(error:Error) {
					}
					_handshakeConnection = null;
				}
			}
			
		}
		
		/**
		 * @private
		 * 
		 */
		protected function onStreamPause(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if(desc.groupName != _groupName) {
				return;
			}
			
			if (desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM ) {
				return;
			}
			
			/**
			 * TODO: the id will be different than userID because shell using different id
			 */
			//if (desc.streamPublisherID != _userManager.myUserID) {
			//	return;
			//}
			
			_isPaused = desc.pause ;
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 * 
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			// If the user has not permission to use screenshare
 //FlashOnlyReplacement// update the stage
			dispatchEvent(p_evt);	//bubble it up
		}
		
		/**
		 * @private
		 * 
		 */
		protected function onBwActualChange(p_evt:RoomManagerEvent):void
		{
			//set for next publishing to use
			_bandwidth = _roomManager.getBandwidthCap(_roomManager.bandwidth);
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 * 
		 */
		protected function onAspectRatioChange(p_evt:StreamEvent):void
		{
			dispatchEvent(p_evt);
		}
		
		/**
		 * 
		 * @private
		 * Making sure my camera gets turned off if the session closes.
		 */
		protected function onSessionClose(p_evt:ConnectSessionEvent):void
		{
			if ( _isPublishing ) {
				stop();
			}
			
			dispatchEvent(p_evt);
		}
	
		/**
		 * @private
		 * handles addin launched event and re-broadcast it out
		 */
		protected function onLaunch(p_evt:AddInLauncherEvent):void
		{	
			_isLaunched = true;
			_outgoingConnection = new LocalConnection();
			_outgoingConnection.allowDomain("*");
			_outgoingConnection.allowInsecureDomain("*");
			_outgoingConnection.addEventListener(StatusEvent.STATUS,onStatus);		
			_outgoingConnection.addEventListener(Event.ACTIVATE, onActivate);
			_retryTimer = new Timer(500, 50);
			_retryTimer.addEventListener(TimerEvent.TIMER, onTryPublish);
			_retryTimer.start();
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 * publish on Timer, trying 50 times connecting to the local connection to launch the shell
		 */
		protected function onTryPublish(p_evt:TimerEvent):void
		{
			if(_bAddinReadyForLC) {
				
				var sessionParams:Object = new Object();
				var auth:AdobeHSAuthenticator = _connectSession.authenticator as AdobeHSAuthenticator;
				sessionParams.authenticationKey = auth.authenticationKey;
				sessionParams.roomName = _connectSession.roomManager.roomName;
				sessionParams.roomURL = _connectSession.roomURL;
				sessionParams.origUserID = _connectSession.userManager.myUserID;
				
				var props:Object = new Object();
				props.fps = _fps;
				props.keyFrameInterval = _keyFrameInterval;
				props.quality = _quality;
				props.enableHFSS = _enableHFSS;
				props.performance = _performance;
				props.bandwidth = _bandwidth;
				
				if(_recipientIDs != null) {
					props.recipientIDs = _recipientIDs;
				}
				
				if(_sharedID != null) {
					props.sharedID = _sharedID;
				}
				
				if(_groupName != null) {
					props.groupName = _groupName;
				}
				
				if(_accessModel >= 0) {
					props.accessModel = _accessModel;
				}
				
				if(_publishModel >= 0) {
					props.publishModel = _publishModel;
				}
				
				if(_nodeConfiguration != null) {
					props.nodeConfiguration = _nodeConfiguration.createValueObject();
				}
				
				_outgoingConnection.send(PRIVATE_CONNECTION_NAME, "publish", sessionParams, props);	
				_retryTimer.stop();
				_retryTimer.removeEventListener(TimerEvent.TIMER, onTryPublish);
				_retryCount = 0;
				_bAddinReadyForLC = false;
			}else {
				if(_retryCount < 50)
					_retryCount ++;
				else {
					_retryTimer.stop();
					_retryTimer.removeEventListener(TimerEvent.TIMER, onTryPublish);
					_retryCount = 0;
				}
			}
		}
		
		//TODO: adding stop mechanism and restart
		// what happen when this client is closed (should the screenshareshell detect the close of private connection?)
		/**
		 * @public
		 * needed for hankshakeconnection to indicate it is ready for publishing
		 */
		public function addinReadyForLC(status:String):void
		{
			_bAddinReadyForLC = true;
		}
		
		public function addinSharingStoppedForLC(status:String):void
		{
			_bAddinReadyForLC = false;
			var evt:AddInLauncherEvent = new AddInLauncherEvent(AddInLauncherEvent.STOP);
			dispatchEvent(evt);
			stop();
		}
		
		public function addinSharingControlStartedForLC(status:String):void
		{
			var event:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.CONTROL_STARTED);
			//event.streamDescriptor = p_desc;
			dispatchEvent(event);
		}
		
		public function addinSharingControlStoppedForLC(status:String):void
		{
			var event:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.CONTROL_STOPPED);
			//event.streamDescriptor = p_desc;
			dispatchEvent(event);
		}

		/**
		 * @private
		 * handles addin failed to launch event
		 */
		protected function onFailedLaunch(p_evt:AddInLauncherEvent):void
		{
			myTrace(p_evt.toString());
			dispatchEvent(p_evt);
		}	
		
		private function onActivate(p_evt:Event):void
		{
			myTrace(p_evt.toString());
		}
		
		/**
		 * @privare
		 * status of localconnection
		 */
		private function onStatus(p_evt:StatusEvent):void
		{
			 switch (p_evt.level) {
                case "status":
                    break;
                case "error":
                    myTrace("LocalConnection.send() failed");
                    break;
            }
		}
		
		/**
		 * @private
		 * trace output
		 */
		private function myTrace(p_msg:String):void
		{
			DebugUtil.debugTrace(p_msg);
		}
					
		
	}
}
