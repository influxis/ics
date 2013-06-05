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

	import com.adobe.coreUI.controls.CameraUserBar;
	import com.adobe.coreUI.controls.VideoComponent;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ConnectSessionEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.events.UserEvent;
	import com.adobe.rtc.messaging.NodeConfiguration;
	import com.adobe.rtc.messaging.UserRoles;
	import com.adobe.rtc.pods.cameraClasses.CameraModel;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.managers.SessionManagerBase;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedManagers.descriptors.UserDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Camera;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	
	import mx.core.UIComponent;

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
	 * Dispatched when a new webcam stream is received by this component.
	 */
	[Event(name="streamReceive", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when a webcam stream is deleted and is no longer displayed by this component.
	 */
	[Event(name="streamDelete", type="com.adobe.rtc.events.StreamEvent")]	

	/**
	 * Dispatched when a webcam stream has its native width or height change.
	 */
	[Event(name="dimensionsChange", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when a webcam stream is paused.
	 */
	[Event(name="streamPause", type="com.adobe.rtc.events.StreamEvent")]
	
	/**
	 * Dispatched when a webcam is closed.
	 */
	[Event(name="userBooted", type="com.adobe.rtc.events.UserEvent")]
	
	/**
	 * Dispatched when a stream is changed.
	 */
	[Event(name="streamChange", type="com.adobe.rtc.events.UserEvent")]
	
	/**
	* @private
	*/
	[Event(name="close", type="flash.events.Event")]

	/**
	* Dispatched when the number of webcam streams displayed by the component changes.
	*/
	[Event(name="numberOfStreamsChange", type="flash.events.Event")]
	
	/**
	 * WebcamSubscriber is the foundation class for receiving and displaying webcam video in a meeting room. By default,  
	 * WebcamSubscriber simply subscribes to StreamManager notifications and plays all webcam video present in the room. 
	 * It can also accept an array of <code class="property">userIDs</code> which restricts the list of publishers that 
	 * can publish to this subscriber.
	 *
	 * Note that this is a lower level component aimed at making the display of one or more webcam videos simple. 
	 * For a higher-level control with UI controls, see com.adobe.rtc.pods.WebCamera.
	 * 
	 * <p> 
	 * Like all stream components, WebcamSubscriber has an API for setting and getting a <code class="property">groupName</code>. 
	 * This property can be used to create multiple and separate video groups with different access/publish models, 
	 * thereby allowing for multiple private conversations. For a subscriber to listen to a particular video stream from 
	 * a publisher, both should have the same assigned <code class="property">groupName</code>.
	 * If no <code class="property">groupName</code> is assigned, the publisher defaults to publishing to the public group.
	 * </p>
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
	 * 							click="(camButt.selected) ? camPub.publish() : camPub.stop()"/&gt;
	 * 			&lt;/mx:VBox&gt;
 	 *	&lt;/session:ConnectSessionContainer&gt;
	 * </listing>
	 * 
	 * @see com.adobe.rtc.collaboration.WebcamSubscriber
	 * @see com.adobe.rtc.pods.WebCamera
 	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */
	
   public class  WebcamSubscriber extends UIComponent implements ISessionSubscriber
	{
		/**
		 * @private
		 */
		 protected var _streamManager:StreamManager;
		
		 /**
		 * @private
		 */
		protected var _cam:Camera;
		
		/**
		 * @private
		 * UserManager variable
		 */
		protected var _userManager:UserManager;
		
		/**
		 * @private
		 */
		protected var _cameraStreamID:String;
		
		/**
		 * @private
		 */
		protected var _stream:NetStream;
		
		/**
		 * @private
		 */
		protected var _videoTable:Object;
		
		/**
		 * @private
		 */
		protected var _netStreamTable:Object;

		/**
		 * @private
		 */
		protected var _streamDescriptorTable:Object = new Object();

		/**
		* @private
		*/		
		protected var _cameraUserBarObj:Object;
		
		/**
		 * @private 
		 */
		protected var _publisherIDs:Array = new Array();
		
		/**
		 * @private 
		 */
		protected var _publisherIDTable:Object = new Object();
		
		/**
		 * @private
		 */
		protected var _publisher:WebcamPublisher;
		
		/**
		 * @private
		 */
		protected var _userDisclosureContainer:Object;
		
		/**
		 * @private
		 */
		protected var _layout:String = CameraModel.SIDE_BY_SIDE ;
		
		/**
		 * @private
		 */
		 protected var _groupName:String ;
		 
		 /**
		 * @private
		 */
		protected var _accessModel:int = -1 ;
		
		/**
		 * @private
		 */
		protected var _publishModel:int = -1 ;
		
		 /**
		 * [read-only] Returns the number of streams currently displayed by the subscriber.
		 */
		public var streamCount:int = 0;

		 /**
		 * @private
		 */
		 protected const invalidator:Invalidator = new Invalidator();

 		 /**
		 * @private
		 */
		 protected const displayInvalidator:Invalidator = new Invalidator();

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
		 protected var _isMyPaused:Boolean = false ;
		 /**
		 * @private
		 */
		 protected var _subscriberId:String;
		 /**
		 * @private
		 */
		 protected var _width:Number;
		 /**
		 * @private
		 */
		 protected var _height:Number;
		 /**
		 * @private
		 */
		 protected var _isMyStream:Boolean = false ;
		 /**
		  * @private
		  */
		 protected var _waitingUserDescriptorList:Object = new Object();
		
		
		/**
		 * Constructor
		 */
		public function WebcamSubscriber()
		{
			super();
			
			invalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE,onInvalidate);
			displayInvalidator.addEventListener(Invalidator.INVALIDATION_COMPLETE, updateSubscribersDisplay);
			
			_videoTable=new Object();
   			_netStreamTable=new Object();
   			_cameraUserBarObj= new Object();
		}
		
		// FLeX Begin
		/**
		 * @private
		 */
		override public function initialize():void
		{
			super.initialize();
       		subscribe();
		}
		// FLeX End
	
		
		[Inspectable(enumeration="false,true", defaultValue="true")]
		/**
		* Determines whether the user bar above video streams is displayed. By default, the user bar is displayed (true).
		*
		*/
		public var displayUserBars:Boolean = true;

		/**
		 * Disposes of all listeners to the network and framework classes and assures the proper garbage collection of the component.
		 */
		public function close():void
		{
			for (var streamID:String in _streamDescriptorTable) {
				deleteStream(_streamDescriptorTable[streamID] as StreamDescriptor);
			}
			_connectSession.removeEventListener(ConnectSessionEvent.CLOSE, onSessionClose);
			_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
			_streamManager.removeEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
			_streamManager.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
			_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamPause);
			_streamManager.removeEventListener(StreamEvent.DIMENSIONS_CHANGE,onDimensionsChange);
			_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_userManager.removeEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
		}
		
		/**
		 * @private
		 * 
		 * Supplies a local camera (e.g. from a WebcamPublisher) to the subscriber in order to play the local video.
		 *
		 * @param p_camera The local camera to display.
		 */
		protected function set webCamera(p_camera:Camera):void
		{
			if ( p_camera == null ) {
				return ;
			}
			_cam = p_camera;
			
			if ( !_cam.muted ) {
				playStreams();
				displayInvalidator.invalidate();
			}
		}
			
		/**
		 * Specifies a WebcamPublisher whose video should be displayed if a local camera video display is desired.
		 */
		public function get webcamPublisher():WebcamPublisher
		{
			return _publisher;
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
		public function set webcamPublisher(p_publisher:WebcamPublisher):void
		{
			if (_publisher) {
				_publisher.removeEventListener(Event.CHANGE, onCameraReceive);
			}
			_publisher = p_publisher;
			if (p_publisher==null) {
				webCamera = null;
				return;
			}
			if (p_publisher.camera) {
				webCamera = p_publisher.camera;
			} else {
				p_publisher.addEventListener(Event.CHANGE, onCameraReceive);
			}
		}
		
		/**
		 * @private
		 */
		public function set groupName(p_groupName:String):void
		{
			
			if ( _groupName != p_groupName ) {
				// Set intially  if groupName and streamManager have not been initialized.
				if ( _streamManager == null ) {
					_groupName = p_groupName ;
					return ;
				}
				
				var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
				for(var id:String in streamDescriptors){
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					deleteStream(streamDescriptor);
 				}
				
				_groupName = p_groupName ;
				
				playStreams();
		
				invalidator.invalidate();
				displayInvalidator.invalidate();
				
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
		 * Gets the NodeConfiguration on a specific camera stream group. 
		 */
		public function getNodeConfiguration():NodeConfiguration
		{	
			return _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).clone();
		}
		
		/**
		 * Sets the NodeConfiguration.
		 * @param p_nodeConfiguration The node configuration of the group of camera stream.
		 * 
		 */
		public function setNodeConfiguration(p_nodeConfiguration:NodeConfiguration):void
		{	
			_streamManager.setNodeConfiguration(p_nodeConfiguration,StreamManager.CAMERA_STREAM,_groupName);
			
		}
		
		/**
		 * @private
		 */
		public function set publishModel(p_publishModel:int):void
		{	
			
			_publishModel = p_publishModel ;
			invalidator.invalidate();
			// invalidateProperties() ;	
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
			// invalidateProperties() ;
		}
		
		/**
		 * The role value required for accessing video streams for this component's group.
		 */
		public function get accessModel():int
		{
			return _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).accessModel;
		}
		 
		/**
		 * Returns the role of a given user for video streams within this component's group.
		 * 
		 * @param p_userID The user ID of the user whose role we should get.
		 */
		public function getUserRole(p_userID:String):int
		{
			return _streamManager.getUserRole(p_userID,StreamManager.CAMERA_STREAM,_groupName);
		}
		
		/**
		 * Sets the role of a given user for subscribing to the component's group
		 * specified by <code class="property">groupName</code>.
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
		 * @private
		 * 
		 * LCCS does not support multiple layouts <code>layout()</code> always returns SIDE_BY_SIDE.
		 * However, developers can extend and make custom layouts.
		 *
		 * @return 
		 * 
		 */
		public function get layout():String
		{
			return _layout ;
		}
		
		/**
		 * @private
		 * 
		 * LCCS does not support multiple layouts <code>layout()</code> always returns SIDE_BY_SIDE.
		 * However, developers can extend and make custom layouts.
		 *
		 * @return 
		 * 
		 */
		public function set layout(p_layout:String):void
		{
			if (_layout == p_layout ) 
				return ;
			
			_layout = p_layout ;	
		}
		
		/**
		 * @private
		 */
		public function set publisherIDs(p_publishers:Array):void
		{
			
			for(var id:String in _streamDescriptorTable){
				deleteStream(_streamDescriptorTable[id]);
 			}

			_publisherIDTable = new Object();
			_publisherIDs = p_publishers;
			var l:int = _publisherIDs.length;
			for (var i:int=0; i<l; i++) {
				_publisherIDTable[_publisherIDs[i]] = true;
			}

			playStreams();
			dispatchEvent(new Event("numberOfStreamsChange"));
			displayInvalidator.invalidate();
		}
		
		/**
		 * An array of <code class="property">userIDs</code>, used for restricting the list of publishers 
		 * that this subscriber should display videos for. 
		 * If the length is zero, all publishers' streams are displayed.
		 */
		public function get publisherIDs():Array
		{
			return _publisherIDs;
		}
		
		/**
		 * Defines the logical location of the component on the service; typically this assigns 
		 * the <code class="property">sharedID</code> of the collectionNode
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
		 * The IConnectSession with which this component is associated, the default being the first IConnectSession 
		 * created in the application. Note that this may only be set once before <code>subscribe()</code>
		 * is called; re-sessioning of components is not supported.
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

			if (_subscribed) {
				return;
			} else {
				_subscribed = true;
			}

			if ( !_userManager ) {
   				_userManager = _connectSession.userManager;
				_userManager.addEventListener(UserEvent.USER_CREATE,onUserDescriptorFetch);
   			}
   			
			if ( !_streamManager ) {
				_streamManager = _connectSession.streamManager;
				_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_streamManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
				_streamManager.addEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
				_streamManager.addEventListener(StreamEvent.STREAM_DELETE,onStreamDelete);
				_streamManager.addEventListener(StreamEvent.STREAM_PAUSE,onStreamPause);
				_streamManager.addEventListener(StreamEvent.DIMENSIONS_CHANGE,onDimensionsChange);
			}	
			
			_connectSession.addEventListener(ConnectSessionEvent.CLOSE, onSessionClose);

   			if (_streamManager.isSynchronized && _userManager.isSynchronized) {
   				playStreams();
   				displayInvalidator.invalidate();
   			}
			
		}
		/**
		 * @private
		 * 
		 * Plays the user specified streams or all the streams under certain conditions. 
		 * If the user has provided a set of streams it compares them with 
		 * the streams in streamManager; if they are available, it plays them.
		 * If the user has not provided any stream, then it plays all the streams available in the streamManager.
		 */
		protected function playStreams():void
		{
			if ( _streamManager == null ) {
				return ;
			}
			
			var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
			var id:String;
			var streamDescriptor:StreamDescriptor;
		
			for( id in streamDescriptors){
				 streamDescriptor=streamDescriptors[id];
				 if (shouldDisplayStream(streamDescriptor)) {
					 if ( streamDescriptor.pause ) {
					 	pauseStream(streamDescriptor.type,streamDescriptor.streamPublisherID);
					 } else {
					 	playStream(streamDescriptor.streamPublisherID); 
					 }
				 }
			}
			dispatchEvent(new Event("numberOfStreamsChange"));
		}
		
		/**
		 * @private
		 * @param p_evt
		 * 
		 */
		protected function onCameraReceive(p_evt:Event):void
		{
			_publisher.removeEventListener(Event.CHANGE, onCameraReceive);
			webCamera = _publisher.camera;
		}
		
		/**
		 *  @private 
		 */
		protected function shouldDisplayStream(p_desc:StreamDescriptor):Boolean
		{
			return (_publisherIDs.length==0 || _publisherIDTable[p_desc.streamPublisherID]==true);
		}
		
		/**
		 *  @private 
		 * Receives the stream and publishes it.
		 */
		protected function onStreamReceive (p_evt:StreamEvent):void
		{	
			var streamDescriptor:StreamDescriptor;
			
			streamDescriptor = p_evt.streamDescriptor ;

			if (streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			}

			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}
			
			
			if (streamDescriptor.finishPublishing && streamDescriptor.type == StreamManager.CAMERA_STREAM ){
				if ( streamDescriptor.nativeWidth!=0 && streamDescriptor.nativeHeight!=0){	       	
        			playStream(streamDescriptor.streamPublisherID);
    			}
    			dispatchEvent(new Event("numberOfStreamsChange"));
				dispatchEvent(p_evt);
				displayInvalidator.invalidate();
            }
            
		}
		
		
				
		/**
		 *  @private 
		 *  It receives the stream and pauses it
		 */
		protected function onStreamPause(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;

			if (streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			}

			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}

			if (streamDescriptor.finishPublishing){
				if(streamDescriptor.type==StreamManager.CAMERA_STREAM)	{
					pauseStream(streamDescriptor.type,streamDescriptor.streamPublisherID);
					dispatchEvent(p_evt);
    				displayInvalidator.invalidate();
    			}
            }
		}
		
		/**
		 *  @private 
		 *  Receives the stream and then delete it.
		 */
		protected function onStreamDelete(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor=p_evt.streamDescriptor;

			if (streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			}

			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}
			
			if (streamDescriptor.finishPublishing){
				if (streamDescriptor.type==StreamManager.CAMERA_STREAM)	{	
					deleteStream(streamDescriptor);
    				dispatchEvent(new Event("numberOfStreamsChange"));
					dispatchEvent(p_evt);
    			
					displayInvalidator.invalidate();
    			}
            }
		}
		
		/**
		 * @private
		 * 
		 * Handles the dimension change from the Shared Stream Manager.
		 */
		protected function onDimensionsChange(p_evt:StreamEvent):void
		{
			var streamDescriptor:StreamDescriptor = p_evt.streamDescriptor;

			if (streamDescriptor==null || (streamDescriptor.groupName && streamDescriptor.groupName != _groupName) ) {
				return ;
			}
			
			if (!shouldDisplayStream(streamDescriptor)) {
				// Don't display the stream if it is not in the list.
				return;
			}

			if (streamDescriptor.finishPublishing){
				if(streamDescriptor.type==StreamManager.CAMERA_STREAM && streamDescriptor.nativeWidth!=0 && streamDescriptor.nativeHeight!=0){	
					displayInvalidator.invalidate();
					dispatchEvent(p_evt);
					layoutCameraStreams();
    			}
			}
		}
		
		// Playing and delete and pause functions.
		
		/**
		 * Plays the stream with the given stream type and stream's publisher ID
		 * 
		 * @param p_streamPublisherID The stream publisher's ID.
		 */
		public function playStream(p_streamPublisherID:String):void
		{
			
			var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.CAMERA_STREAM,p_streamPublisherID,_groupName);
			
			if ( streamDescriptor != null ) {
				_streamDescriptorTable[streamDescriptor.id] = streamDescriptor;
				if ( streamDescriptor.streamPublisherID != _userManager.myUserID || _isMyPaused) {
					var sessionManager:SessionManagerBase = _connectSession.sessionInternals.session_internal::sessionManager;
					_netStreamTable[streamDescriptor.id]= sessionManager.session_internal::getAndPlayAVStream(streamDescriptor.id);
    			}else {
    				 if ( _cam && _cam.muted )
    					return;
    				
    			}
   			}
   			var vC:VideoComponent;
            if(_videoTable[streamDescriptor.id] == null ) {
            	vC = new VideoComponent();
            	addChild(vC);
            	_videoTable[streamDescriptor.id] = vC;
				streamCount++;
            }
            vC = _videoTable[streamDescriptor.id];
            if (streamDescriptor.streamPublisherID != _userManager.myUserID || _isMyPaused) { 
            	vC.attachNetStream(_netStreamTable[streamDescriptor.id]); 
            } else {
            	vC.attachCamera(_cam);
            }
            
            // FLeX Begin
            // If I am an ownder or if I am a publisher and It is my stream 
            if (!_cameraUserBarObj[streamDescriptor.id] && displayUserBars) {
            	var cBar:CameraUserBar = new CameraUserBar();
               	cBar.addEventListener(Event.CLOSE,onMyCameraClose);
            	cBar.addEventListener(Event.CHANGE,onCameraPause);
            	cBar.pause = streamDescriptor.pause ;            	
           		cBar.showStopPauseBtn = (_streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM,_groupName) == UserRoles.OWNER || (_streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM, _groupName) == UserRoles.PUBLISHER && streamDescriptor.streamPublisherID == _userManager.myUserID));	
            	addChild(cBar);
            	_cameraUserBarObj[streamDescriptor.id] = cBar;
            	displayInvalidator.invalidate();
            }
            // FLeX End
         
		}	
	
	
		/**
		 * @private
		 */
		protected function onCameraPause(p_evt:Event):void
		{
			var userDescriptors:Array = _userManager.userCollection.source ; 
			for ( var i:int = 0 ; i< userDescriptors.length ; i++ ) {
				if ( userDescriptors[i].userID == p_evt.target.cameraUserID ) {
					var event:UserEvent = new UserEvent(UserEvent.STREAM_CHANGE);
					event.userDescriptor = userDescriptors[i] ;
					dispatchEvent(event);
					break;
				}
			}
		}
	
		/**
		 * @private
		 */
		protected function onMyCameraClose(p_evt:Event):void
		{
			var userDescriptors:Array = _userManager.userCollection.source ; 
			for ( var i:int = 0 ; i< userDescriptors.length ; i++ ) {
				if ( userDescriptors[i].userID == p_evt.target.cameraUserID ) {
					var event:UserEvent = new UserEvent(UserEvent.USER_BOOTED);
					event.userDescriptor = userDescriptors[i] ;
					dispatchEvent(event);
					break;
				}
			}
			
		}
	
		/**
		 *  @private
		 *	Deletes the stream with the given stream ID. For local use. 
		 */
		protected function deleteStream(p_stream:StreamDescriptor):void
		{			
			var vC:VideoComponent = _videoTable[p_stream.id];
			if (!vC) {
				return;
			}
			if (p_stream.streamPublisherID == _userManager.myUserID ) {
//				_netStreamTable[p_stream.id].attachCamera(null);
				vC.attachCamera(null);
			} 
			var stream:NetStream = _netStreamTable[p_stream.id] as NetStream;
			if (stream) {
				stream.close();
			}
			delete _netStreamTable[p_stream.id];
			
			if (vC) { 
				vC.clear();
				vC.close();
				removeChild(vC);
				delete _videoTable[p_stream.id];
			}
			
			// FLeX Begin
			if ( displayUserBars ) {
				removeChild(_cameraUserBarObj[p_stream.id]);
				delete _cameraUserBarObj[p_stream.id];
			}
			// FLeX End
			delete _streamDescriptorTable[p_stream.id];
			streamCount--;
			
		}

		/**
		 * @private
		 */
		protected function pauseStream(p_streamType:String,p_streamPublisherID:String) :void
		{
			
			if ( p_streamType != StreamManager.CAMERA_STREAM ) {
				return ;
			}
			
			var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(p_streamType,p_streamPublisherID,_groupName);
			var vC:VideoComponent = _videoTable[streamDescriptor.id];
			
			if (streamDescriptor.pause) {
				if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
					deleteStream(streamDescriptor);
					_isMyPaused = true ;
					playStream(streamDescriptor.streamPublisherID);
					_isMyStream = true ;
					_netStreamTable[streamDescriptor.id].addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
					
				} else {
					
					if ( _netStreamTable[streamDescriptor.id] == null ) {
						playStream(streamDescriptor.streamPublisherID);
						_netStreamTable[streamDescriptor.id].addEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
					}else {
						_netStreamTable[streamDescriptor.id].pause();	
					}
				}
			} else {
				if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
					deleteStream(streamDescriptor);
					_isMyPaused = false ;
                	playStream(streamDescriptor.streamPublisherID);
                	displayInvalidator.invalidate();
				} else {
					playStream(streamDescriptor.streamPublisherID);
				}
			}
			
		  if (_cameraUserBarObj[streamDescriptor.id] && _cameraUserBarObj[streamDescriptor.id].pause != streamDescriptor.pause) {
            	_cameraUserBarObj[streamDescriptor.id].pause = streamDescriptor.pause;
          }   
		}
		
		
		/**
		 * @private //TODO ????
		 */
		public function pausePlayStreamLocally(p_streamType:String,p_streamPublisherID:String):void
		{
			
			if ( p_streamType != StreamManager.CAMERA_STREAM ) {
				return ;
			}
			
			var streamDescriptor:StreamDescriptor = _streamManager.getStreamDescriptor(p_streamType,p_streamPublisherID,_groupName);
			var vC:VideoComponent = _videoTable[streamDescriptor.id];
			
			if (_cameraUserBarObj[streamDescriptor.id] == null) {
			 	return;
			}
			
			if ( _cameraUserBarObj[streamDescriptor.id].pause ) {
				playStream(streamDescriptor.streamPublisherID);
			}else {
				_netStreamTable[streamDescriptor.id].pause();
				vC.attachNetStream(null);
			}
			
			_cameraUserBarObj[streamDescriptor.id].pause = !_cameraUserBarObj[streamDescriptor.id].pause ;
		}
		
		
		// Functions for computing the layouts
		/**
		 * @private
		 */
		protected function computeArea_Rows(p_numberOfStreams:Number,p_numRows:Number):Array
		{
			var ar:Number = _streamManager.aspectRatioValue;
			var theW:Number = width/Math.ceil(p_numberOfStreams/p_numRows);
			var theH:Number = theW/ar;
			if (theH > (height/p_numRows)) {
				theH = (height/p_numRows);
				theW = theH*ar;
			}
			var dimensionArray:Array=new Array();
			dimensionArray.push(Math.round(theW));
			dimensionArray.push(Math.round(theH));
			dimensionArray.push(Math.round(theW)*Math.round(theH));
			return dimensionArray;
		}

		/**
		 * @private
		 */
		protected function computeArea_Columns(p_numberOfStreams:Number,p_numColumns:Number):Array
		{
			var ar:Number = _streamManager.aspectRatioValue;
			var theH:Number = height/Math.ceil(p_numberOfStreams/p_numColumns);
			var theW:Number = theH*ar;
			if (theW > (width/p_numColumns)) {
				theW = (width/p_numColumns);
				theH = theW/ar;
			}
			var dimensionArray:Array=new Array();
			dimensionArray.push(Math.round(theW));
			dimensionArray.push(Math.round(theH));
			dimensionArray.push(Math.round(theW)*Math.round(theH));
			return dimensionArray;
		}

		
		/**
		 * @private
		 * It lays out all the streams
		 */
		protected function layoutCameraStreams():void
		{
			//var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM);
		
			switch (_layout) {
				
				case CameraModel.PICTURE_IN_PICTURE:
				case CameraModel.SIDE_BY_SIDE:
					var areasH:Array = new Array();
					areasH.push(computeArea_Rows(streamCount,1));	// 0 - 1 row
					areasH.push(computeArea_Rows(streamCount,2));	// 1 - 2 rows
					areasH.push(computeArea_Rows(streamCount,3));	// 2 - 3 rows
					areasH.push(computeArea_Rows(streamCount,4));	// 3 - 4 rows
			
					var maxHArea:Number = 0;
					var maxHAreaIndex:Number = 0;
			
					for (var i:int=0; i<areasH.length; i++) {
						var tempHArr:Array = areasH[i];
						if (tempHArr[2] > maxHArea) {
							maxHArea = tempHArr[2];
							maxHAreaIndex = i;
						}
					}

					var areasV:Array = new Array();
					areasV.push(computeArea_Columns(streamCount,1));	// 0 - 1 col
					areasV.push(computeArea_Columns(streamCount,2));	// 1 - 2 cols
					areasV.push(computeArea_Columns(streamCount,3));	// 2 - 3 cols
					areasV.push(computeArea_Columns(streamCount,4));	// 3 - 4 cols
			
					var maxVArea:Number = 0;
					var maxVAreaIndex:Number = 0;
					for (i=0; i<areasV.length; i++) {
						var tempVArr:Array = areasV[i];
						if ( tempVArr[2] > maxVArea) {
							maxVArea = tempVArr[2];
							maxVAreaIndex = i;
						}
					}

					var maxArea:Number = Math.max(maxHArea, maxVArea);
					var array:Array;
					var theW:Number;
					var theH:Number;
					var theNum:Number;
					var orientation:String;
					if (maxArea == maxHArea) {
						var arrayH:Array=areasH[maxHAreaIndex];
						theW = arrayH[0];
						theH = arrayH[1];
						theNum = maxHAreaIndex+1;
						orientation = "horizontal";
					} else {
						var arrayV:Array=areasV[maxVAreaIndex];
						theW = arrayV[0];
						theH =  arrayV[1];
						theNum = maxVAreaIndex+1;
						orientation = "vertical";
					}
			
					var c:Number = Math.ceil(streamCount/theNum);
					var xOffset:Number = (orientation == "horizontal") ? (width-theW*c)/2 : (width-theW*theNum)/2;
					var yOffset:Number = (orientation == "horizontal") ? (height-theH*theNum)/2 : (height-theH*c)/2;
					var counter:int = 0;
					for (var id:String in _streamDescriptorTable) {
						
						if( _videoTable[id] != null) {
							var vC:VideoComponent = _videoTable[id];
							var f:Number = Math.floor(counter/c);
							if (orientation == "horizontal") {
								vC.x = theW * (counter%c) + xOffset;
								vC.y = theH * f + yOffset ;
							} else {
								vC.x = theW * f + xOffset;
								vC.y = theH * (counter%c) + yOffset ;
							}
				 	
				 			vC.width=theW;
				 			vC.height=theH  ;//With new spec , label on top as overlay-userNameBarHeight;
				 			// FLeX Begin
				 			if (displayUserBars) {
								var d:StreamDescriptor = _streamDescriptorTable[id];
								if (d) {
									var publisherID:String = d.streamPublisherID;
									var ud:UserDescriptor = _userManager.getUserDescriptor(publisherID);
									if (ud) {
							 			var cBar:CameraUserBar = _cameraUserBarObj[id]; 
										cBar.x = vC.x;
										cBar.y = vC.y; //Note: with new spec , the name should be on top+ vC.height;
										cBar.setActualSize(vC.width, cBar.measuredHeight);
										cBar.cameraUserLabel = ud.displayName;	
										cBar.cameraUserID = ud.userID ;
										cBar.invalidateDisplayList();
									}else {
										//Lazysubscription might have been set. So call the function again after 
										//the UserManager fetches the UserDescriptor
										_waitingUserDescriptorList[publisherID] = id;
									}
								}
							}
							// FLeX End
						}
						counter++;
					}
					break;
			}
		}
		
		/**
		 * @private
		 */
		protected function onUserDescriptorFetch(p_evt:UserEvent):void
		{
			if (_waitingUserDescriptorList[p_evt.userDescriptor.userID]) {
				// FLeX Begin
				if (displayUserBars) {
					var d:StreamDescriptor = _streamDescriptorTable[_waitingUserDescriptorList[p_evt.userDescriptor.userID]];
					var vC:VideoComponent = _videoTable[_waitingUserDescriptorList[p_evt.userDescriptor.userID]];
					if (d && vC) {
						var publisherID:String = d.streamPublisherID;
						var ud:UserDescriptor = _userManager.getUserDescriptor(publisherID);
						if (ud) {
							var cBar:CameraUserBar = _cameraUserBarObj[d.id]; 
							cBar.x = vC.x;
							cBar.y = vC.y; //Note: with new spec , the name should be on top+ vC.height;
							cBar.setActualSize(vC.width, cBar.measuredHeight);
							cBar.cameraUserLabel = ud.displayName;	
							cBar.cameraUserID = ud.userID ;
							cBar.invalidateDisplayList();
						}
					}
				}
				// FLeX End
				delete _waitingUserDescriptorList[p_evt.userDescriptor.userID];
			}
		}

		/**
		 * @private
		 */
		 protected function onAspectRatioChange(p_evt:Event):void
		 {
		 	displayInvalidator.invalidate();
		 	dispatchEvent(p_evt);
		 }
		
		// FLeX Begin
		 /**
		 *  @private
		 *  overridding the protected function measure
		 */
		override protected function measure():void
		{
			super.measure();
			minHeight = 120 ;
			minWidth = 160 ;
			measuredMinHeight=120;
			measuredMinWidth=160;
		}
		
		/**
		 * @private
		 *  overridding the protected method updateDisplayList
		 */		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			if ( !_subscribed){
				return ;
			}
			layoutCameraStreams();
		}
	
		
		// FLeX End
		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if (_streamManager.isSynchronized) {
				playStreams();
				displayInvalidator.invalidate();
			}else {
				var streamDescriptors:Object=_streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
				for(var id:String in streamDescriptors){
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					deleteStream(streamDescriptor);
 				}
			}
			dispatchEvent(p_evt);	
		}
		
		/**
		 * @private 
		 */
		protected function onNetStatus(e:NetStatusEvent):void
		{
			if (e.info.code == "NetStream.Play.Start" )
			{
				var stream:NetStream = e.currentTarget as NetStream ;	
				stream.pause();
				stream.removeEventListener(NetStatusEvent.NET_STATUS,onNetStatus);
				
				if ( _isMyStream ) {
					dispatchEvent(new Event("numberOfStreamsChange"));
					displayInvalidator.invalidate();
					_isMyStream = false ;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function onSessionClose(p_evt:ConnectSessionEvent):void
		{
			var streams:Array = _streamManager.getStreamsForPublisher(_userManager.myUserID, StreamManager.CAMERA_STREAM,_groupName);
			if (streams.length!=0) {
				var strDesc:StreamDescriptor = streams[0] as StreamDescriptor;
				if(strDesc != null) {
					var v:VideoComponent = _videoTable[strDesc.id];
					if(v != null) {
						v.attachCamera(null);
					}
				}
				
			}
			
		}
		
		/**
		 * @private
		 */
		protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
		{
			var i:int = 0;
			var id:String;
			// FLeX Begin
			// the UI changes are only if its you ..
			if ( p_evt.userID == _userManager.myUserID) {
				if ( _streamManager.getUserRole(p_evt.userID,StreamManager.CAMERA_STREAM) == UserRoles.OWNER ) {
					for (id in _streamDescriptorTable) {
						if ( _cameraUserBarObj[id] ) {
							(_cameraUserBarObj[id] as CameraUserBar).showStopPauseBtn = true ;
						}
					}
				} else if ( _streamManager.getUserRole(p_evt.userID,StreamManager.CAMERA_STREAM) == UserRoles.PUBLISHER ) {
					for (id in _streamDescriptorTable) {
						if ( _cameraUserBarObj[id] ) {
							if ( _userManager.myUserID == StreamDescriptor(_streamDescriptorTable[id]).streamPublisherID ){
								(_cameraUserBarObj[id] as CameraUserBar).showStopPauseBtn = true ;	
							}else {
								(_cameraUserBarObj[id] as CameraUserBar).showStopPauseBtn = false ;	
							}
						}
					}
				} else if ( _streamManager.getUserRole(p_evt.userID,StreamManager.CAMERA_STREAM) == UserRoles.VIEWER ) {
					for (id in _streamDescriptorTable) {
						if ( _cameraUserBarObj[id] ) {
							(_cameraUserBarObj[id] as CameraUserBar).showStopPauseBtn = false ;
						}
					}
				}
			}
			// FLeX End
			dispatchEvent(p_evt);	//bubble it up
		}
        
        /**
        * @private
        */
        protected function onInvalidate(p_evt:Event):void
        {
        	
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
        
        /**
        * @private
        */
        protected function updateSubscribersDisplay(p_evt:Event):void
        {
			layoutCameraStreams();        	
        }
        
		override public function set width(p_width:Number):void
		{
			if (p_width != _width) {
				// FLeX Begin
				super.width = p_width;
				// FLeX End
				_width = p_width;
			}
		}
		

		
		override public function set height(p_height:Number):void
		{
			if (p_height != _height) {
				// FLeX Begin
				super.height = p_height;
				// FLeX End
				_height = p_height;
			}
		}		
		
		// FLeX Begin
		[PercentProxy("percentWidth")]
		// FLeX End
		override public function get width():Number
		{
			return _width;
		}		
		
		// FLeX Begin
		[PercentProxy("percentHeight")]
		// FLeX End
		override public function get height():Number
		{
			return _height;
		}	    

		override public function set id(p_id:String):void
		{
			_subscriberId = p_id;
		}
		
		override public function get id():String
		{
			return _subscriberId;
		}
		
		override public function get measuredWidth():Number
		{
			return 0;
		}
		
		override public function get measuredHeight():Number
		{
			return 0;
		}
		
		override public function setActualSize(p_w:Number, p_h:Number):void
		{
			var changed:Boolean = false;
			if (_width != p_w) {
				_width = p_w;
				changed = true;
			}
			
			if (_height != p_h) {
				_height = p_h;
				changed = true;
			}	
			if (changed) {
				// FLeX Begin
				super.setActualSize(p_w, p_h);
				// FLeX End
				displayInvalidator.invalidate();
			}
		}

		/**
		*  @private
		*/
		public function onMetaData(info:Object):void
		{
			
		}
		
		override public function move(p_x:Number, p_y:Number):void
		{
			var changed:Boolean = false;
			if (p_x != super.x) {
				super.x = p_x;
				changed = true;
			}
			
			if (p_y != super.y) {
				super.y = p_y;
				changed = true;
			}
			if (changed) {
				// FLeX Begin
				super.move(p_x, p_y);
				// FLeX End
				displayInvalidator.invalidate();
			}
		}
		
	}
}
