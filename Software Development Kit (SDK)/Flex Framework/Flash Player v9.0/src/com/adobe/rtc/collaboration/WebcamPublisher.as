// ActionScript file
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
	import com.adobe.coreUI.controls.VideoComponent;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CameraConfigurationEvent;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.RoomManagerEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.RoomManager;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.media.Camera;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;

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
	[Event(name="isCameraPublishing", type="flash.events.Event")]
	
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
	 * Dispatched when the width and height capturing factor of camera changes.
	 */
	[Event(name="captureWidthHeightFactorChanged", type="com.adobe.rtc.events.CameraConfigurationEvent")]	

	/**
	 * WebcamPublisher is the component responsible for publishing webcam video to other room members.
	 * It acts as an intermediary between the Camera/NetStream and StreamManager and publishes
	 * webcam StreamDescriptors to the StreamManager so that WebcamSubscribers in the room are aware a new 
	 * stream has been initiated. 
	 * <p>
	 * It also provides an API for the following: 
	 * <ul>
	 * <li>For requesting other users to begin publishing their webcams (<code class="property">publish</code> with an optional parameter).</li>
	 * <li>Listens for remote requests for the user to begin publishing. </li>
	 * <li>Prompts the user to begin when needed.</li> 
	 * </ul>
	 * 
	 * <p> 
	 * Like all stream components, WebcamPublisher has an API for setting and getting a 
	 * <code class="property">groupName</code>. This property can be used to create
	 * multiple video groups, each being separate and having different access/publish models, 
	 * allowing for multiple private conversations. 
	 * For a subscriber to listen to a particular video stream from a publisher, both should 
	 * have the same assigned <code class="property">groupName</code>.
	 * If no <code class="property">groupName</code> is assigned, the publisher 
	 * defaults to publishing into the public group.
	 * </p>
	 * 
	 * The WebcamPublisher has no user interface of its own, but provides a basic API through which any commands concerning publishing 
	 * webcam video should be routed. For a higher-level component with user interface and a publisher and subscriber, see com.adobe.rtc.pods.WebCamera.
	 * <p>
	 * By default, only users with role <code>UserRoles.PUBLISHER</code> or greater may publish webcams, and all users with
	 * role of greater than <code>UserRoles.VIEWER</code> are able to subsribe to these streams.
 	 * 
 	 * <h6>Starting and stopping webcam video in a room</h6>
 	 *	<listing>
	 *  &lt;session:ConnectSessionContainer 
	 * 			roomURL="http://connect.acrobat.com/exampleAccount/exampleRoom" 
	 * 			authenticator="{auth}"&gt;
	 * 			&lt;mx:VBox width="100%" height="100%"&gt;
	 *	&nbsp;&nbsp;&nbsp;			&lt;collaboration:WebcamPublisher id="camPub"/&gt;
	 *	&nbsp;&nbsp;&nbsp;			&lt;collaboration:WebcamSubscriber webcamPublisher="{camPub}"/&gt;
	 * 	&nbsp;&nbsp;&nbsp;			&lt;mx:Button label="Video" toggle="true" id="camButt" 
	 * 					click="(camButt.selected) ? camPub.publish() : camPub.stop()"/&gt;
	 * 			&lt;/mx:VBox&gt;
 	 *	&lt;/session:ConnectSessionContainer&gt; </listing>
	 * </p>

	 * @see com.adobe.rtc.collaboration.WebcamSubscriber
	 * @see com.adobe.rtc.pods.WebCamera
 	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */	
	 
   public class  WebcamPublisher extends UIComponent implements ISessionSubscriber
	 {
	 	
	 	/**
	 	 * @private 
	 	 */
	 	protected const ISIGHT_NAME:String = "USB Video Class Video";
	 	
		/**
		 * @private
		 */
		protected var _streamManager:StreamManager;
		
		/**
		 * @private
		 */
		protected var _camera:Camera;
		
		/**
		 * @private
		 */
		protected var _isPaused:Boolean = false;

		/**
		 * @private
		 */
		protected var _cameraNameIndex:String;
		
		/**
		 * @private
		 * Netstream variable
		 */
		protected var _stream:NetStream;
		
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _roomManager:RoomManager;
		
		/**
		 * @private
		 */
		protected var _cameraStreamID:String;
		
		/**
		* @private
		*/		
		protected var _fps:Number = 6;
		
		/**
		* @private
		*/		 
		protected var _quality:Number = 70;
		
		/**
		* @private
		*/		 
		protected var _keyFrameInterval:Number = 18;
		
		/**
		* @private
		*/		 
		protected var _captureWidthHeightFactor:uint = 1;
		
		/**
		 * @private
		 */
		protected var _groupName:String ;
		
		/**
		 * @private
		 */
		 protected var _publisherID:String ;
		
		/**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		
		/**
		 * @private
		 */
		 protected var _camerSettingChanged:Boolean = false ;
		
		/**
		 * @private
		 */
		 protected const invalidator:Invalidator = new Invalidator();
		
		/**
		 * @private
		 */
		 protected var _sharedID:String;
		 
		 /**
		  * @private
		  */
		 protected var _subscribed:Boolean = false ;
		 
		 /**
		  * @private 
		  */		
		 protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent);
		 /**
		 * @private
		 */
		 protected var _recipientIDs:Array ;
		 /**
		 * @private
		 */
		 protected var _bandwidth:Number ;
		 
		
		
		/**
		* Constructor
		*/
		public function WebcamPublisher()
		{
			super();	
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
		}
		
		// FLeX Begin
		/**
		 * @private
		 */
		override public function initialize():void
		{
			super.initialize();
			
			// Creates the stream Manager singleton.
			if ( !_subscribed ) {
        		subscribe();
        		_subscribed = true ;
        	}
			
		}
		// FLeX End
		
		/**
		 * Disposes all listeners to the network and framework classes and assures proper garbage collection of the component.
		 */
		public function close():void
		{
			_connectSession.removeEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
			_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_streamManager.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
			_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamPause);
			_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_streamManager.removeEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
			_roomManager.removeEventListener(RoomManagerEvent.BW_ACTUAL_CHANGE, onBwActualChange);
			
		}

		[Bindable(event="isCameraPublishing")]
		/**
		 * Returns true if the camera is publishing; false if not.
		 */
		public function get isPublishing():Boolean
		{
			return (_cameraStreamID!=null);
		}
		
		
		
		[Bindable (event="streamPause")]
		/**
		 * Returns true if the camera is paused; false if not or if there is no stream.
		 */
		public function get isPaused():Boolean
		{
			return _isPaused;
		}
		
		/**
		 * Returns the camera object associated with this publisher.
		 */
		public function get camera():Camera
		{
			return _camera;
		}
				
		[Inspectable(category="Common", defaultValue="0")]
		/**
		 * Specifies the index of the current camera within the list of cameras.
		 * 
		 * @return 
		 * 
		 */
		public function get cameraNameIndex():String
		{
			return _cameraNameIndex ;
		}
		
		public function set cameraNameIndex(p_cameraNameIndex:String):void
		{
			if (p_cameraNameIndex == _cameraNameIndex ) 
				return ;
			
			_cameraNameIndex = p_cameraNameIndex ;	
		}
		
		[Bindable(event="synchronizationChange")]
		
		/**
		 * Returns whether or not the component is synchronized.
		 */
		public function get isSynchronized():Boolean
		{
			return _streamManager.isSynchronized ;
		}
		
		
		/**
		 * @private
		 */
		public function set groupName(p_groupName:String):void
		{
			
			if ( _groupName != p_groupName ) {
				if ( _streamManager == null ) {
					_groupName = p_groupName ;
					return ;
				}
				// If a user is publishing and is then put in a different group, stop the stream.	
				if ( isPublishing ) {
					stop();
				}
				_groupName = p_groupName ;
			}
		}
		
		/**
		 * Components (pods) are assigned to a group via <code class="property">groupName</code>; if not specified, 
		 * the component is assigned to the default, public group (the room at large). Groups are like separate 
		 * conversations within the room, but each conversation could employ one or more pods; for example, one 
		 * "conversation" may use a web camera, chat, and whiteboard pod, with each pod using different access 
		 * and publish models. Users are members of and can only see components within the group they are assigned. 
		 * Room hosts can see all the groups and all the members in those groups.
		 */
		public function get groupName():String 
		{
			return _groupName ;
		}
		
		
		/**
		 * Gets the NodeConfiguration that defines message permissions and storage policies for the current stream group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration that defines message permissions and storage policies for the current stream group.
		 * 
		 * @param p_nodeConfiguration The current stream groups node configuration.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_streamManager.setNodeConfiguration(p_nodeConfiguration,StreamManager.CAMERA_STREAM,_groupName);
			
		}
		
		/**
		 * Array of Recipient UserIDs for camera streams published by this user.
		 * Throws an error while setting this property if Private Streaming is not allowed i.e. allowPrivateStreams property is false in StreamManager.
		 * Throws an error while setting this property if the Camera Stream for this user is currently published. Stop the stream and then set this property.
		 * Set this property to null if you want to broadcast your camera stream to everyone. This is also the default case.
		 * 
		 * @default null
		 */
		public function get recipientIDs():Array
		{
			return _recipientIDs ;	
		}
		
		/**
		 * @private
		 */
		public function set recipientIDs(p_recipientIDs:Array):void
		{
			if ( isPublishing ) {
				throw new Error("The camera stream is currently publishing. Stop the stream and then set RecipientIDs.");
				return ;
			}
			
			if ( p_recipientIDs == null ) {
				_recipientIDs = null ;
				return ;
			}
			
			if ( !_streamManager.allowPrivateStreams ) {
				throw new Error("Private Streaming is not allowed inside the room.");
				return ;
			}
			
			_recipientIDs = p_recipientIDs ;
		}
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			
			_publishModel = p_publishModel ;
			invalidator.invalidate();
		}
		
		/**
		 * The role required for this component to publish to the group specified by <code class="property">groupName</code>.
		 */
		public function get publishModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).publishModel;
		}
		
		/**
		 * @private
		 */
		public function set accessModel(p_accessModel:int):void
		{	
			_accessModel = p_accessModel ;
			invalidator.invalidate();
		}
		
		/**
		 * The role value required for accessing video streams, for the group this component is assigned to
		 */
		public function get accessModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).accessModel;
		}
		
		/**
		 * Returns the given stream publisher or subscriber's user role within the stream's group.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _streamManager.getUserRole(p_userID,StreamManager.CAMERA_STREAM,_groupName);
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
				
			_streamManager.setUserRole(p_userID,p_userRole,StreamManager.CAMERA_STREAM,_groupName);
		}
		
		
		/**
		 * Quality is the required level of picture quality, as determined 
		 * by the amount of compression being applied to each video frame.
		 * Acceptable quality values range from 1 (lowest quality, maximum compression) 
		 * to 100 (highest quality, no compression).
		 *
		 * @param p_quality
		 * @default 70
		 *
		 */
		public function set quality(p_quality:uint):void
		{
			if ( _quality == p_quality ) 
				return ;
				
			_quality = p_quality ;
			
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.QUALITY_CHANGED));
			
			_camerSettingChanged = true ;
			invalidator.invalidate() ;
		}
		
		/**
		 * @private
		 */
		public function get quality():uint
		{
			return _quality ;
		}
		
		/**
		 * Bandwidth is the maxmimum bandwidth the video feed can take
		 * given other factors like quality. Default is RoomManager's current Bandwidth.
		 * For more, see bandwidth property in flash.media.Camera
		 * The value is in kilobit/sec
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
			
			_camerSettingChanged = true ;
			invalidator.invalidate() ;
		}
		
		/**
		 * @private
		 */
		public function get bandwidth():Number
		{
			return _bandwidth ;
		}
		
		
		/**
		 * Fps is the maximum rate at which the camera can capture data, in frames per second.
		 * The maximum rate possible depends on the capabilities of the camera; this frame rate 
		 * may not be achieved.
		 *
		 * @param p_fps
		 * @default 6
		 *
		 */
		public function set fps(p_fps:uint):void
		{
			if ( _fps == p_fps ) 
				return ;
			
			_fps = p_fps ;
			
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.FPS_CHANGED));
			_camerSettingChanged = true ;
			invalidator.invalidate() ;
		}
		
		
		/**
		 * @private
		 */
		public function get fps():uint
		{
			return _fps ;
		}
		
		
		/**
		 * keyFrameInterval is the number of video frames transmitted in full (called keyframes) 
		 * instead of being interpolated by the video compression algorithm. 
		 * A value of 1 means that every frame is a keyframe. 
		 * The allowed values are 1 through 48.
		 *
		 * @param p_keyFrameInterval
		 * @default 18.
		 * 
		 */
		public function set keyframeInterval(p_keyFrameInterval:uint):void
		{
			if ( _keyFrameInterval == p_keyFrameInterval ) 
				return ;
				
			_keyFrameInterval = p_keyFrameInterval ;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.KEY_FRAME_INTERVAL_CHANGED));
			_camerSettingChanged = true ;
			invalidator.invalidate() ;
				
		}
		
		
		/**
		 * @private
		 */
		public function get keyframeInterval():uint
		{
			return _keyFrameInterval ;	
		}
		
		/**
		 * <strong>Deprecated</strong> Use resolutionFactor.
		 * Specifies the captureHeightWidthFactor settings for the webcamera.
		 * 
		 *
		 * @ param p_captureHeightWidthFactor
		 */
		public function set captureWidthHeightFactor(p_captureWidthHeightFactor:uint):void
		{
			if ( _captureWidthHeightFactor == p_captureWidthHeightFactor ) 
				return ;
				
				
			_captureWidthHeightFactor = p_captureWidthHeightFactor;
			dispatchEvent(new CameraConfigurationEvent(CameraConfigurationEvent.CAPTURE_WIDTH_HEIGHT_FACTOR_CHANGED));
			_camerSettingChanged = true ;
			invalidator.invalidate() ;
			
		}
		
		
		/**
		 * @private
		 */	
		public function get captureWidthHeightFactor():uint
		{
			return _captureWidthHeightFactor ;	
		}
		
		
		/**
		 * @private
		 */
		public function get resolutionFactor():uint
		{
			return _captureWidthHeightFactor ;
		}
		
		/**
		 * Specifies the resolution factor of captured data; ResolutionFactor values range from 1 (lowest resolution) 
		 * to 10 (highest resolution).
		 * Resolution factor gets multiplied by the native width and height of captured camera.
		 * We provide three native width and height values based on aspect ratios. That width and
		 * height when multiplied with this factor, gives the resolution. For higher resolution, use 
		 * a value like 5.
		 *
		 * @ param p_resolutionFactor
		 * @ default 1
		 */
		public function set resolutionFactor(p_resolutionFactor:uint):void
		{
			captureWidthHeightFactor = p_resolutionFactor ;
		}
		
		/**
		 * Defines the logical location of the component on the service; typically this assigns the <code class="property">sharedID</code> of the collectionNode
		 * used by the component. <code class="property">sharedIDs</code> should be unique within a room if they're expressing two 
		 * unique locations. Note that this can only be assigned once before <code>subscribe()</code> is called. For components 
		 * with an <code class="property">id</code> property, <code class="property">sharedID</code> defaults to that value.
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
		 * The IConnectSession with which this component is associated; it defaults to the first 
		 * IConnectSession created in the application.  Note that this may only be set once before 
		 * <code>subscribe()</code> is called, and re-sessioning of components is not supported.
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
				
				if ( !_bandwidth) {
					_bandwidth = _roomManager.getBandwidthCap(_roomManager.bandwidth) ;
				}
   			}
		}
		/**
		 * Begins publishing the stream for the user identified by <code class="property">p_publisherID</code> after prompting the user. 
		 * If the user declines to publish on the first prompt, subsequent attempts to publish invoke a dialog 
		 * that allows the user to change their publish settings. If the user accepts, it notifies other users through the StreamManager
		 * of the new audio stream and begins streaming to the room for consumption by participating subscribers. 
		 * It may also be optionally used for requesting a remote user of a particular <code class="property">p_publisherID</code>.
		 * 
		 * @param p_publisherID - if null (default), publishes the current user, otherwise prompts the specified remote user.
		 * 
		 */
		public function publish(p_publisherID:String=null):void
		{
			if ( connection == null ) {
				return ; // if there is no netconnection , just return ...
			}
			
			if ( !_subscribed  && _connectSession.isSynchronized) {
				subscribe();
				_subscribed = true;
				onInvalidate();
			}
			
			if(p_publisherID==null || p_publisherID == _userManager.myUserID){
				if ( _camera == null ) {
					createMyStream();
				} else {
					if ( !_camera.muted ) {
						createMyStream(true);
					}else {
						Security.showSettings();
					}
				}
			}else{
			 	// Does the current user have permission to configure?  If not, quit.
			 	if(!_streamManager.canUserConfigure(_userManager.myUserID, StreamManager.CAMERA_STREAM,_groupName)) {
					throw new Error("WebcamPublisher: Only Owners have the ability to request/configure streams of other users");
			 		return;
			 	}
				// If the target user doesn't have permission to publish, grant permission.
				if ( _groupName == null || _streamManager.isGroupDefined(_groupName)) {
					if(_streamManager.getUserRole(p_publisherID, StreamManager.CAMERA_STREAM,_groupName) < _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).publishModel) {
						_streamManager.setUserRole(p_publisherID,_streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).publishModel,StreamManager.CAMERA_STREAM,_groupName);
					}
				}
				createMyStream(false, p_publisherID);
			}
		}
		
		/**
		 * Pauses or unpauses the stream specified by p_publisherID; defaults to the current user's stream.
		 * Dispatches a notification event that can be used to notify room members that the streams state has changed.
		 * 
		 * @param p_pause True to pause; false to play.
		 * @param p_publisherID An optional user ID of the user whose stream pause state should change; otherwise, if null,
		 * the current user's stream.
		 * 
		 */
		public function pause(p_pause:Boolean, p_publisherID:String=null):void
		{
			if (p_publisherID==null) {
				p_publisherID = _userManager.myUserID;
			}
			var tmpArray:Array = _streamManager.getStreamsForPublisher(p_publisherID, StreamManager.CAMERA_STREAM,_groupName);
			if (tmpArray.length==0) {
				throw new Error("WebcamPublisher: The stream's pause state cannot be changed because the stream does not exist");
				return;
			}
			_streamManager.pauseStream(StreamManager.CAMERA_STREAM,p_pause,p_publisherID,_groupName,_recipientIDs);
		}
		
		
		/**
		 * Stops publishing the stream published by the user identified by p_publisherID; if the ID is null, it defaults to the current user's stream.
		 * 
		 * @param p_publisherID The user ID of the user whose stream should be stopped. Defaults to the 
		 * current user. Only a room owner can stop a remote user's stream.
		 */
		public function stop(p_publisherID:String=null):void
		{
			if (p_publisherID==null) {
				p_publisherID = _userManager.myUserID;
			}
			
			//this code needs to be removed when we have the stream id from the server
			var streamID:String = p_publisherID+StreamManager.CAMERA_STREAM;

			var tmpArray:Array = _streamManager.getStreamsForPublisher(p_publisherID, StreamManager.CAMERA_STREAM,_groupName);
			if (tmpArray.length==0) {
				throw new Error("Stream Descriptor cannot be paused as it doesnot exist");
				return;
			}
			
			_streamManager.deleteStream(StreamManager.CAMERA_STREAM,p_publisherID,_groupName );
		}
	
		/**
		 * 
		 * @private
		 * Making sure my camera gets turned off if the session closes.
		 */
		protected function onSessionClose(p_evt:ConnectSessionEvent):void
		{
			
			if ( isPublishing ) {
				stop();
			}
			
			deleteCamera();
		}
	
		/**
		 * @private
		 *  Handling the change event from StreamManager
		 */
		 protected function onAspectRatioChange(p_evt:Event):void
		 {
	 		updateCameraSettings();
		 	dispatchEvent(p_evt);
		 }
		
		
		/**
		 *  @private 
		 *  It receives the stream and publishes it.
		 */
		protected function onStreamReceive(p_evt:StreamEvent):void
		{	
			var streamDescriptor:StreamDescriptor;
			var playStream:Boolean=false;
			var event:StreamEvent;
			
			streamDescriptor = p_evt.streamDescriptor ;
			
				// if there is a group, then it will only listen to the streams of that group 
			if ( streamDescriptor.groupName && streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			if(	!streamDescriptor || _userManager.myUserID != p_evt.streamDescriptor.streamPublisherID || streamDescriptor.type != StreamManager.CAMERA_STREAM){
				// If the received stream is not null and it and I have published it and its a camera stream
				return ;
			}	
			
			
			if( _camera==null){
				// If there is no camera , create it and attach it to the stream
				if (_cameraNameIndex==null && Capabilities.os.indexOf("Mac OS 1")!=-1) {
					// it's silly season - let's try to detect iSight cams, if nothing gets specified
					var l:int = Camera.names.length;
					for (var i:int=0; i<l; i++) {
						if (Camera.names[i]==ISIGHT_NAME) {
							_cameraNameIndex = i+"";
							break;
						}
					}
				}
				_camera= Camera.getCamera(_cameraNameIndex);
				if ( _camera != null ) {
					_camera.addEventListener(StatusEvent.STATUS,statusHandler);
					updateCameraSettings();
					dispatchEvent(new Event(Event.CHANGE));
					_stream= new NetStream(connection);
                	_stream.attachCamera(_camera);
					if ( !_camera.muted ) {
						createMyStream(true);
					}else {
						if ( _streamManager.camAudioPermissionDenied ) {
							Security.showSettings(SecurityPanel.PRIVACY);
						}
					}
				} else {
					_streamManager.deleteStream(StreamManager.CAMERA_STREAM, streamDescriptor.streamPublisherID,_groupName);
					dispatchEvent(new StreamEvent(StreamEvent.NO_STREAM_DETECTED));
				}
			} else {
				
				if ( _camera.muted || !p_evt.streamDescriptor.finishPublishing )
					return ;
				else {
					
					if ( _cameraNameIndex && _camera.index != parseInt(_cameraNameIndex) ) {
						_camera= Camera.getCamera(_cameraNameIndex);
						_camera.addEventListener(StatusEvent.STATUS,statusHandler);
						updateCameraSettings();
						dispatchEvent(new Event(Event.CHANGE));
						_stream= new NetStream(connection);
						_stream.attachCamera(_camera);
					} 
										
					if(	streamDescriptor.nativeWidth!=0 && streamDescriptor.nativeHeight!=0) {
						//If I have given permission for using my camera, then create the video and the cameraStreamID
            			if( _stream == null ){
            				_stream= new NetStream(connection);
                			_stream.attachCamera(_camera);
            			}
            			_cameraStreamID = p_evt.streamDescriptor.id;
            			dispatchEvent(new Event("isCameraPublishing"));
	                   	_stream.publish(_cameraStreamID);
						dispatchEvent(p_evt);
                    }
      			}
   			}
		}
		
		
		/**
		 * @private
		 * Returns the Netconnection
		 */
		protected function get connection():NetConnection
		{
			return _connectSession.sessionInternals.session_internal::connection as NetConnection;
		}
		

		/**
		 * @private
		 */
		protected function updateCameraSettings():void
		{
			if (_camera == null) {
				return;
			}
			
			switch (_streamManager.aspectRatio) {
				case StreamManager.AR_STANDARD:
					//trace("#WebCamPublisher# _camera.setMode("+StreamManager.AR_STANDARD_W*_captureWidthHeightFactor+", "+StreamManager.AR_STANDARD_H*_captureWidthHeightFactor+", "+_fps+")");
					_camera.setMode(StreamManager.AR_STANDARD_W*_captureWidthHeightFactor, StreamManager.AR_STANDARD_H*_captureWidthHeightFactor, _fps);
					break;
	 			case StreamManager.AR_PORTRAIT:
					//trace("#WebCamPublisher# _camera.setMode("+StreamManager.AR_PORTRAIT_W*_captureWidthHeightFactor+", "+StreamManager.AR_PORTRAIT_H*_captureWidthHeightFactor+", "+_fps+")");
					_camera.setMode(StreamManager.AR_PORTRAIT_W*_captureWidthHeightFactor, StreamManager.AR_PORTRAIT_H*_captureWidthHeightFactor, _fps);
					break;
				case StreamManager.AR_LANDSCAPE:
					//trace("#WebCamPublisher# _camera.setMode("+StreamManager.AR_LANDSCAPE_W*_captureWidthHeightFactor+", "+StreamManager.AR_LANDSCAPE_H*_captureWidthHeightFactor+", "+_fps+")");
					_camera.setMode(StreamManager.AR_LANDSCAPE_W*_captureWidthHeightFactor, StreamManager.AR_LANDSCAPE_H*_captureWidthHeightFactor, _fps);
					break;
	 		}

			//trace("#WebCamPublisher# _camera.setKeyFrameInterval("+_keyFrameInterval+")");
			_camera.setKeyFrameInterval(_keyFrameInterval);
			setCameraQuality();	//will update the bw used			
		}
			
		/**
		 * @private
		 * @param p_evt
		 * 
		 */
		protected function onBwActualChange(p_evt:RoomManagerEvent=null):void
		{
			_bandwidth = _roomManager.getBandwidthCap(_roomManager.bandwidth);
			setCameraQuality();	
		}
		
		/**
		 * @private
		 */
		protected function setCameraQuality():void
		{
			if (_camera == null) {
				return;
			}			
			_camera.setQuality(_bandwidth*1000/8, _quality);
		}
				
				
		/**
		 * @private
		 * @param p_evt
		 * 
		 */
		protected function onStreamPause(p_evt:StreamEvent):void
		{
				// if there is a group, then it will only listen to the streams of that group 
			if ( p_evt.streamDescriptor.groupName && p_evt.streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			if (p_evt.streamDescriptor.type != StreamManager.CAMERA_STREAM || _userManager.myUserID != p_evt.streamDescriptor.streamPublisherID ) 
				return;
			
			if ( _camera !=null ){
				_isPaused = p_evt.streamDescriptor.pause ;
				dispatchEvent(p_evt);		
			} 	
		}
		
		/**
		 *  @private 
		 *  It receives the stream and deletes it
		 */
		protected function onStreamDelete(p_evt:StreamEvent):void
		{
			// If the stream is deleted, then check if it was published by myself and its a camera stream
			var streamDescriptor:StreamDescriptor = p_evt.streamDescriptor;
			
				// if there is a group, then it will only listen to the streams of that group 
			if ( streamDescriptor.groupName && streamDescriptor.groupName != _groupName ) {
				return ;
			} 
			
			if (streamDescriptor.type != StreamManager.CAMERA_STREAM || _userManager.myUserID != p_evt.streamDescriptor.streamPublisherID ) 
				return;
			
			if ( _camera == null ) {
				return ; // If I am deleting the stream because my camera was not attached
			}
			
			if(_streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM,_groupName)>= _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName ).publishModel){
				//If the user has permission to publish camera
				if(	streamDescriptor.type == StreamManager.CAMERA_STREAM && 
			   		_userManager.myUserID == p_evt.streamDescriptor.streamPublisherID ) 
			   	{
			   		deleteCamera();
            	}
   			} else {
   				// If he does not have permission now on account of role change, and he is still publishing then stop the publishing 
   				deleteCamera();
   			}
          
			dispatchEvent(p_evt);
		}
		/**
		 * @private
		 * Deleting the Camera
		 */		
		protected function deleteCamera():void
		{
			if (_stream != null ) {
				_stream.attachCamera(null);
			   	_stream.close();
			   	_stream=null;
			   	_camera = null ;
				_cameraStreamID = null;
				dispatchEvent(new Event("isCameraPublishing"));
			}
		}
		
		/**
		 * @private
		 * Handles the synchronization change event from the Shared Stream Manager
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if ( !_streamManager.isSynchronized ) {
				deleteCamera();
			}
			
			invalidateDisplayList();
			dispatchEvent(p_evt);	
		}
		
		/**
		 * @private
		 * Handles the user role change event from shared stream manager
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			// If the user has not permission to use camera
			invalidateDisplayList();// update the stage
			dispatchEvent(p_evt);	//bubble it up
		}

		/**
		 * @private
		 * @param p_finishedPublishing
		 * @param p_userID
		 * 
		 */
		protected function createMyStream(p_finishedPublishing:Boolean=false, p_userID:String=null):void
		{
			var w:uint = StreamManager.AR_STANDARD_W;
			var h:uint = StreamManager.AR_STANDARD_H;
			if (_streamManager.aspectRatio == StreamManager.AR_PORTRAIT ) {
				w = StreamManager.AR_PORTRAIT_W;
				h = StreamManager.AR_PORTRAIT_H;
		 	} else if (_streamManager.aspectRatio == StreamManager.AR_LANDSCAPE ) {
		 		w = StreamManager.AR_LANDSCAPE_W;
		 		h = StreamManager.AR_LANDSCAPE_H;
		 	}
			
			var streamDescriptor:StreamDescriptor ;
			
			if ( !p_userID ) {
				_publisherID = _userManager.myUserID ;
			} else {
				_publisherID = p_userID ;
			}
			
			if ( !p_finishedPublishing ) {
				
				streamDescriptor = new StreamDescriptor() ;
				if ( p_userID )
					streamDescriptor.streamPublisherID = p_userID ;
				else 
					streamDescriptor.streamPublisherID = _userManager.myUserID ;
				
				streamDescriptor.type = StreamManager.CAMERA_STREAM ;
				//streamDescriptor.id = StreamManager.CAMERA_STREAM  + streamDescriptor.streamPublisherID ;
				streamDescriptor.groupName = _groupName ;
				streamDescriptor.nativeHeight = h ;
				streamDescriptor.nativeWidth = w ;
				streamDescriptor.recipientIDs = _recipientIDs ;
				_streamManager.createStream(streamDescriptor);
			}else {
				if ( p_userID )
					_streamManager.publishStream(StreamManager.CAMERA_STREAM,p_userID,_groupName,_recipientIDs);
				else 
					_streamManager.publishStream(StreamManager.CAMERA_STREAM,_userManager.myUserID,_groupName,_recipientIDs);
			}
			
		}
		
        /**
         * @private
         * Status handler when we allow or deny the use of camera
         * @param event	StatusEvent
         * 
         */		
        protected function statusHandler(event:StatusEvent):void 
        {
        	
            if( _camera != null){
            	// If the camera is present
            	if(event.code == "Camera.Unmuted" ){
            		// If the camera is allowed and its in publish condition
            		createMyStream(true);
					dispatchEvent(event);
					_streamManager.camAudioPermissionDenied = false ;
            	} else {
            		_streamManager.deleteStream(StreamManager.CAMERA_STREAM,_publisherID,_groupName);
            		_streamManager.camAudioPermissionDenied = true ;
            	}
        	}
        }
        
        
        /**
        * @private
        */
        protected function onInvalidate(p_evt:Event=null):void
        {
        	
        	
        	if ( _camerSettingChanged ) {
        		updateCameraSettings();
        		invalidateDisplayList() ;
        		_camerSettingChanged = false ;
        	}
        	
        	if ( _publishModel != -1 || _accessModel != -1 ) {
				var nodeConf:NodeConfiguration = _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName);
				
				if ( nodeConf.accessModel != _accessModel && _accessModel != -1 ) {
					nodeConf.accessModel = _accessModel ;
					_accessModel = -1 ;
				}
			
				if ( nodeConf.publishModel != _publishModel && _publishModel != -1 ) {
					nodeConf.publishModel = _publishModel ;
					_publishModel = -1 ;
				}
				
				_streamManager.setNodeConfiguration(nodeConf,StreamManager.CAMERA_STREAM,_groupName);	
						
			}
        }
       
       // FLeX Begin
		/**
		 * @private
		 */
		override protected function measure():void
		{
			super.measure();
			
			if ( UIComponentGlobals.designMode ) {
        		minHeight = 40 ;
        		minWidth = 100 ;
        	}else {
        		minHeight = 0 ;
        		minWidth = 0 ;
        	}
		}
        // FLeX End
	}

}
