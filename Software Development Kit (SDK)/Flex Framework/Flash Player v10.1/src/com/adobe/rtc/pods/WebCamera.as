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
package com.adobe.rtc.pods
{
		import com.adobe.coreUI.localization.ILocalizationManager;
		import com.adobe.coreUI.localization.Localization;
		import com.adobe.rtc.collaboration.WebcamPublisher;
		import com.adobe.rtc.collaboration.WebcamSubscriber;
		import com.adobe.rtc.core.session_internal;
		import com.adobe.rtc.events.CameraModelEvent;
		import com.adobe.rtc.events.CollectionNodeEvent;
		import com.adobe.rtc.events.StreamEvent;
		import com.adobe.rtc.events.UserEvent;
		import com.adobe.rtc.messaging.UserRoles;
		import com.adobe.rtc.pods.cameraClasses.CameraModel;
		import com.adobe.rtc.session.IConnectSession;
		import com.adobe.rtc.session.ISessionSubscriber;
		import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
		import com.adobe.rtc.sharedManagers.StreamManager;
		import com.adobe.rtc.sharedManagers.UserManager;
		import com.adobe.rtc.sharedManagers.descriptors.On2ParametersDescriptor;
		import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
		
		import flash.display.GradientType;
		import flash.display.Graphics;
		import flash.events.Event;
		import flash.events.MouseEvent;
		import flash.media.Camera;
		import flash.net.NetConnection;
		
		import mx.collections.ArrayCollection;
		import mx.containers.Canvas;
		import mx.controls.Button;
		import mx.controls.ComboBox;
		import mx.controls.Label;
		import mx.core.UIComponent;
		import mx.events.DropdownEvent;
		
		
		/**
		 * Dispatched when the NoteModel has fully connected and synchronized with the service
		 * or when it loses that connection.
		 */
		[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	

		/**
	 	* Dispatched when the current user's role changes with respect to this component.
	 	*/
		[Event(name="userRoleChange", type="com.adobe.rtc.events.CollectionNodeEvent")]	
		
		/**
		 * Dispatched when the web camera's aspect ratio display changes. 
		 */
		[Event(name="aspectRatioChange", type="com.adobe.rtc.events.StreamEvent")]
		
		/**
		* Dispatched when the quality value changes.
		*/		
		[Event(name="qualityChange", type="com.adobe.rtc.events.CameraModelEvent")]
		
		/**
		* Dispatched when the layout value changes.
		*/		
		[Event(name="layoutChange", type="com.adobe.rtc.events.CameraModelEvent")]
		
		/**
		 * Dispatched when a new video stream is received to display by the camera.
		 */
		[Event(name="streamReceive", type="com.adobe.rtc.events.StreamEvent")]
		
		/**
	 	* Dispatched when a video stream is stopped and is no longer displayed.
	 	*/
		[Event(name="streamDelete", type="com.adobe.rtc.events.StreamEvent")]	
		
		/**
	 	* Dispatched when a video stream is paused or unpaused.
	 	*/
		[Event(name="streamPause", type="com.adobe.rtc.events.StreamEvent")]


		
		/**
		 * The WebCamera component is a high level "pod" component which allows multiple 
		 * users to publish and display webcam video. In the MVC sense, the WebCamera is the view 
	     * and controller to the NoteModel's model since it consumes user events, drives them 
	     * to the model, accepts model events, and updates the view.
		 * <p>
		 * The component is comprised of a WebcamPublisher and one or more WebcamSubscribers, and resurfaces 
		 * many of the features of these components. In general, users with publisher role and higher 
		 * can publish their webcam streams users with a viewer role can display them. The WebCamera 
		 * features synchronized quality, layout, and aspect ratio settings. 
		 * 
		 * <p> 
		 * Like all stream components, WebCamera has an API for setting and getting a <code>groupName</code>. 
		 * This property can be used to create multiple video groups each with separate and different access/publish models, 
		 * thereby allowing for multiple private conversations. For a subscriber to listen to a particular 
		 * video stream from a publisher, both should have the same assigned <code>groupName</code>.
		 * If no <code>groupName</code> is assigned, the WebCamera defaults to publishing and subscribing to the public group.
		 * </p>
		 * 
		 * TODO: The layout modes are currently undergoing a rewrite.(yes, still)
		 * 
		 * @see com.adobe.rtc.collaboration.WebcamPublisher
		 * @see com.adobe.rtc.collaboration.WebcamSubscriber
		 * @see com.adobe.rtc.sharedManagers.StreamManager
		 * @see com.adobe.rtc.pods.cameraClasses.CameraModel
		 * 
		 */
   public class  WebCamera extends UIComponent implements ISessionSubscriber
		{	
			/**
			 * @private
			 */
			protected const STATE_PLAYING:String = "playing";
			
			/**
			 * @private
			 */
			protected const STATE_PAUSED:String = "paused";
			 
			/**
			 * @private
			 */
 			protected var _lm:ILocalizationManager = Localization.impl;
			
		/**
		 	* @private
		 	*/
		 	protected var _streamManager:StreamManager;
		 	
			/**
		 	* @private
		 	*/
		 	protected var _cameraModel:CameraModel;
			
			/**
			* @private
			*/
			//protected var _muteToggleBtn:Button;

			/**
			* @private 
			*/
			protected var _playingStream:StreamDescriptor;
			
			/**
			* @private 
			*/
			protected var _currentPlayState:String;
			

			/**
			 * @private
			 */
			protected var _startStopBtn:Button;
			
			/**
			 * @private
			 */
			protected static const STATE_START:uint = 0;
			
			/**
			 * @private
			 */
			protected static const STATE_STOP:uint = 1;
			
			/**
			 * @private
			 */
			protected var _startStopState:uint = STATE_START;
			
			/**
			 * @private
			 */
			protected var _cameraPublisher:WebcamPublisher;

			/**
			 * @private
			 */
			protected var _sbsSubscriber:WebcamSubscriber;

			/**
			 * @private
			 */
			protected var _pipMySubscriber:WebcamSubscriber;
			
			/**
			 * @private
			 */
			protected var _pipOthersSubscriber:WebcamSubscriber;

			/**
			 * @private
			 */
			protected var _dataProvider:ArrayCollection;
			
			/**
			 * @private
			 */
			protected var _layoutSetting:String;
			
			/**
			 * @private
			 */
			protected var _noCameraUI:Canvas;
			
			/**
			 * @private
			 */
			protected var _noCameraLabel:Label;
			
			/**
			 * @private
			 */
			protected var _noCameraDetectButton:Button;
			
			/**
			 * @private
			 */
			protected var _cameraList:ComboBox;
			
			/**
			 * @private
			 */
			protected var _noCameraUICloseButton:Button ;

			/**
			 * @private
			 */
			protected var _userManager:UserManager;
			/**
			 * @private
			 */
			protected var _groupName:String ;
			/**
		 	* @private
		 	*/
			protected var _sharedID:String  ;
			/**
		 	* @private
			 */
			 private const DEFAULT_SHARED_ID:String = "default_WebCamera";
			/**
		 	* @private
		 	*/
			protected var _subscribed:Boolean = false ;
			/**
		 	* @private 
		 	*/		
			protected var _connectSession:IConnectSession = new SessionContainerProxy(this as UIComponent) ;
            
            /**
             * @private
             */
            public var sharedModelId:String;
						
			public function WebCamera():void
			{
				super();
			}
			
			/**
			 * Returns true if the current client has started their webcam (i.e. has a widget showing in the pod). 
			 */
			public function get amIsharingMyWebCam():Boolean
			{
				return (_startStopState == STATE_STOP);
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
			 * Specifies the aspect ratio for video display from one of the aspect ratio constants 
			 * provided on StreamManager. 
			 * 
			 * @see com.adobe.rtc.sharedManagers.StreamManager
			 */			
			public function get aspectRatio():String
			{
				return _streamManager.aspectRatio;
			}
			
			/**
			 * @private
			 */			
			public function set aspectRatio(p_ratio:String):void
			{
				_streamManager.aspectRatio = p_ratio;
			}
			
			/**
			 * Specifies the video quality settings for the camera from among the constants 
			 * provided on CameraModel.
			 * 
			 * @see com.adobe.rtc.pods.cameraClasses.CameraModel
			 */			
			public function get imageQuality():String
			{ 
				return _cameraModel.videoSetting;
			}

			/**
			 * @private
			 */
			public function get imageQualityString():String
			{
				return _cameraModel.videoSettingString;
			}
			
			/**
			 * @private
			 * 
			 * @param p_quality
			 */		
			public function set imageQuality(p_quality:String):void
			{
				_cameraModel.videoSetting = p_quality;
			}
			
			/**
			 * Specifies the video layout settings for the display from among the constants 
			 * provided on CameraModel. 
			 * <p>
			 * TODO: Note that this functionality is undergoing a rewrite and results may vary.
			 * 
			 * @see com.adobe.rtc.pods.cameraClasses.CameraModel
			 */			
			public function get layout():String
			{
				return _cameraModel.layoutSetting;
			}
			
			/**
			 * @private
			 * 
			 * @param p_layoutType
			 * 
			 */			
			public function set layout(p_layoutType:String):void
			{
				if ( p_layoutType == _cameraModel.layoutSetting ) {
					return ;
				}
				_cameraModel.layoutSetting = p_layoutType;				
			}
				
				
			/**
			 * Returns the CameraModel associated with this pod.
			 */
			public function get model():CameraModel
			{
				
				return _cameraModel ;
			}
			
			/**
			 * Returns the WebcamPublisher component used within this pod.
			 */
			public function get publisher():WebcamPublisher
			{
				return _cameraPublisher ;
			}
			
			/**
			 * Returns the <code>streamDescriptor</code> for the video stream currently 
			 * this is being published, if any.
			 */
			public function get currentPlayingStream():StreamDescriptor
			{
				return _playingStream ;
			}
			
			
			/**
			 * Assigns a group to the WebCamera. Groups can be thought of as separate "conversations" within the room, each
			 * with different access and publish models. If not specified, it defaults to the public group.
			 */
			public function set groupName(p_groupName:String):void
			{
				_groupName = p_groupName ;
				
				if (_cameraPublisher ) {
					_cameraPublisher.groupName = _groupName ;
				}
				
				if ( _sbsSubscriber ) {
					_sbsSubscriber.groupName = _groupName ;
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
			//**********************************************************************************
			//************************************************************************************
			//**********END OF PROPERTY GETTERS AND SETTERS	
			
			/**
			 *  Sets the role of a given user for video streams that are within this component's assigned group.
			 * 
		 	 * @param p_userRole The role value to set on the specified user.
		 	 * @param p_userID The ID of the user whose role should be set.
			 */
			public function setUserRole(p_userID:String ,p_userRole:int):void
			{
				if ( p_userID == null ) 
					return ;
				
				_cameraModel.setUserRole(p_userID,p_userRole);
				_streamManager.setUserRole(p_userID,p_userRole,StreamManager.CAMERA_STREAM,_groupName);
			}
			
			
			/**
			 *  Returns the role of a given user for video streams that are within this component's assigned group.
			 * 
		 	 * @param p_userID The user ID for the user being queried.
			 */
			public function getUserRole(p_userID:String):int
			{
				if ( p_userID == null ) {
					throw new Error("CameraModel: USerId can't be null");
				}
				
				return _cameraModel.getUserRole(p_userID);
			}
			
		
			
			/**
			 * @private
			 * @param event
			 * setting change from the camers's model
			 * 
			 */			
			protected function onQualityChange(p_evt:CameraModelEvent):void
			{
				
				
				var on2param:Object = _connectSession.streamManager.on2ParamsTable;
				
				if ( on2param[_cameraModel.videoSetting] != null )  {	
					_cameraPublisher.fps = (on2param[_cameraModel.videoSetting] as On2ParametersDescriptor).fps ; 
					_cameraPublisher.quality = (on2param[_cameraModel.videoSetting] as On2ParametersDescriptor).quality ; 
					_cameraPublisher.keyframeInterval = (on2param[_cameraModel.videoSetting] as On2ParametersDescriptor).keyframeInterval ; 
				}
				
					
				var event:CameraModelEvent = new CameraModelEvent(CameraModelEvent.QUALITY_CHANGE);
				dispatchEvent(event);
				
			}
				
			/**
			 * @private
			 * Mouse Click handler for play and pause 
			 * @param event
			 * 
			 */			
			protected function onPlayPauseClick (event:MouseEvent) :void
			{
				if ( _currentPlayState == STATE_PLAYING ) {
					paused = true;
				} else if (_currentPlayState == STATE_PAUSED ) {
					paused = false;
				}
			}
			
			/**
			 * @private
			 */
			public function set paused(p_paused:Boolean):void
			{
				if ( _playingStream == null ) {
					return;
				}
				_cameraPublisher.pause(p_paused);
			}
			
			/**
			 * Specifies whether the published stream (if any) is paused (true) or playing (false).
			 */
			public function get paused():Boolean
			{
				if (_playingStream) {
					return _playingStream.pause;
				}
				return false;
			}

			/**
			 * Helper function which causes the webcamera to start publishing.
			 */
			public function startWebcam():void
			{
				if (_startStopState == STATE_START) {
					deleteNoCameraUI();
					_cameraPublisher.publish(null);				
				}
			}
			
			/**
			 * @private
			 */
			protected function onStartStopClick(p_evt:MouseEvent):void
			{
				if (_startStopState == STATE_START) {
					startWebcam();
				} else if (_startStopState == STATE_STOP) {
					if ( _playingStream != null ) {
						_cameraPublisher.stop(_playingStream.streamPublisherID);
					}
				}
				
				invalidateDisplayList();
			}

			///// THE EVENT LISTENERS FROM PUBLISHRERS
			
			/**
			 * @private
			 * onCameraPublisherChange event received
			 */			
			protected function onCameraPublisherChange(event:Event):void
			{
				if ( _cameraModel.layoutSetting == CameraModel.PICTURE_IN_PICTURE) {
					_pipMySubscriber.webcamPublisher = _cameraPublisher;
				}
				else if ( _cameraModel.layoutSetting == CameraModel.SIDE_BY_SIDE) {
					_sbsSubscriber.webcamPublisher = _cameraPublisher;
				}
			}
			
			/**
			 * @private
			 * @param p_evt
			 * On Stream Receive From Publisher
			 * 
			 */			
			protected function onStreamReceiveFromPublisher(p_evt:StreamEvent):void
			{
				_startStopState = STATE_STOP;
				_startStopBtn.visible = false;
//				_startStopBtn.label = _lm.getString("Stop My Camera");
//				_startStopBtn.selected = true ;
				_currentPlayState = STATE_PLAYING;
				_playingStream = p_evt.streamDescriptor;
				invalidateDisplayList();
				dispatchEvent(p_evt);
			} 
			
			/**
			 * @private
			 * On Stream Pause
			 * @param p_evt
			 * 
			 */			
			protected function onStreamPauseFromPublisher(p_evt:StreamEvent):void
			{
				var streamDescriptor:StreamDescriptor;
				streamDescriptor= p_evt.streamDescriptor ;
				if ( streamDescriptor && p_evt.streamDescriptor.streamPublisherID == _userManager.myUserID) {
					_currentPlayState = (streamDescriptor.pause) ? STATE_PAUSED : STATE_PLAYING;
				}
				invalidateDisplayList();
				dispatchEvent(p_evt);
			}
			/**
			 * @private
			 * on stream delete
			 * @param p_evt
			 * 
			 */			
			protected function onStreamDeleteFromPublisher(p_evt:StreamEvent):void
			{
				if (p_evt.streamDescriptor.streamPublisherID == _userManager.myUserID ) {	
					_startStopState = STATE_START;
				
					if ( _playingStream ) {
						_playingStream = null ;
						
						if ( _startStopBtn ) {
							_startStopBtn.visible = true;
							//_startStopBtn.label = _lm.getString("Start My Camera");
							//_startStopBtn.selected = false ;
						}
					}
					
				}
				dispatchEvent(p_evt);
				invalidateDisplayList();
			}
			
			/**
			 * @private
			 * @param p_evt
			 * This function responds to the event when no Camera is found 
			 */			
			protected function onNoStreamDetectedFromPublisher(p_evt:StreamEvent):void
			{
				createNoCameraUI();
			}
			
			/**
			 * @private
			 */
			protected function createNoCameraUI():void
			{
				if(_cameraPublisher.camera == null ) {
					_startStopBtn.visible = true;
					//_startStopBtn.label = _lm.getString("Start My Camera");
					//_startStopBtn.selected = false ;
					
					if ( !_noCameraUI ) {
						_noCameraUI = new Canvas();
						//_noCameraUI.alpha = 0.7 ;
						addChild(_noCameraUI);
					}
					
					_noCameraUI.setStyle("backgroundColor",0x333333);
					
					
				
					if ( !_noCameraLabel ) {
						_noCameraLabel = new Label();
						_noCameraUI.addChild(_noCameraLabel);
					}
				
					if ( !_noCameraDetectButton ) {
						_noCameraDetectButton = new Button();
						_noCameraDetectButton.label = _lm.getString("Detect");
						_noCameraDetectButton.alpha = 0.7;
						_noCameraUI.addChild(_noCameraDetectButton);
						_noCameraDetectButton.addEventListener(MouseEvent.CLICK,onDetectButtonClick);
					}
					
					if ( !_noCameraUICloseButton ) {
						_noCameraUICloseButton = new Button();
						_noCameraUICloseButton.label = _lm.getString("Close"); ;
						_noCameraUICloseButton.alpha = 0.7; 
						_noCameraUICloseButton.addEventListener(MouseEvent.CLICK,onNoCameraCloseClick);
						_noCameraUI.addChild(_noCameraUICloseButton);
					}
				
				
					displayCameras();
					
				}
			}
			
			/**
			 * @private
			 * @param p_evt
			 * Clicking this button detects all the cameras connected to the system
			 * 
			 */			
			protected function onDetectButtonClick(p_evt:MouseEvent):void
			{
				displayCameras();
				invalidateDisplayList();
			}
			
			
			/**
			 * @private
			 */
			protected function onNoCameraCloseClick(p_evt:MouseEvent):void
			{
				deleteNoCameraUI();
				invalidateDisplayList();
			}
			/**
			 * @private
			 * Displays all the cameras connected to the system.
			 * 
			 */			
			protected function displayCameras():void
			{
				var arr:Array = Camera.names ;
				if (arr.length == 0) {
					_noCameraLabel.htmlText = "<FONT COLOR='#FFFFFF' SIZE='12'><B>"+_lm.getString("No Camera Plugged into your System")+"</B></FONT>" ;
						
				}else {
					_noCameraLabel.htmlText = "<FONT COLOR='#FFFFFF' SIZE='12'><B>"+_lm.getString("Select the camera from the list")+"</B></FONT>";
					removeTwoNoCameraUIButtons();
					
					_cameraList = new ComboBox();
					_cameraList.dataProvider = arr;
					_cameraList.addEventListener(DropdownEvent.CLOSE, onCameraListSelect);
					_noCameraUI.addChild(_cameraList);	
					
				}
				
				invalidateDisplayList();
			}
			
			/**
			 * @private
			 * @param p_evt
			 * Event Handler for the Camera List
			 * 
			 */			
			protected function onCameraListSelect(p_evt:Event):void
			{
				if (p_evt.target == _cameraList ) {
					_cameraPublisher.cameraNameIndex = _cameraList.selectedIndex.toString(); //TODO : why the API doesnot work
					deleteNoCameraUI();
					_cameraPublisher.publish(null);
				}
			
				invalidateDisplayList();
			}
			
			
			/**
			 * @private
			 */
			protected function deleteNoCameraUI():void
			{
				if ( _noCameraUI ) {
					if (_noCameraLabel) {
						_noCameraUI.removeChild(_noCameraLabel);
						_noCameraLabel = null;
					}

					removeTwoNoCameraUIButtons();
					
					if (_cameraList) {
						_noCameraUI.removeChild(_cameraList);
						_cameraList = null;
					}
					removeChild(_noCameraUI);
					_noCameraUI = null;
				}
			}

			/**
			 * @private
			 */
			protected function removeTwoNoCameraUIButtons():void
			{
				if (_noCameraDetectButton) {
					_noCameraUI.removeChild(_noCameraDetectButton);
					_noCameraDetectButton = null;					
				}
					
				if (_noCameraUICloseButton) {
					_noCameraUI.removeChild(_noCameraUICloseButton);
					_noCameraUICloseButton = null;
				}
			} 			 
			
			
			//*******************************************************************
			//*******************************************************************
			///// THE EVENT LISTENERS FROM SUBSCRIBERS
		
			/**
			 * @private 
			 * Dimension Change listener from Subscriber
			 * @param p_evt
			 * 
			 */			
			protected function onStreamSubscriberHandler(p_evt:StreamEvent):void
			{
				invalidateDisplayList();
			}
			
			
			//*******************************************************************
			//*******************************************************************
			///// THE EVENT LISTENERS FROM Stream Manager
			
						
			//--------- END OF EVENT LISTENERS FROM PUBLISHERS AND SUBSCRIBERS
			
			/**
			 * @private
			 */
			override protected function createChildren():void
			{
				super.createChildren();

				if ( !_subscribed ) {
					subscribe();
					_subscribed = true ;
				}

				if ( !_cameraPublisher) {
					_cameraPublisher = new WebcamPublisher();
					_cameraPublisher.addEventListener(StreamEvent.STREAM_DELETE,onStreamDeleteFromPublisher);
					_cameraPublisher.addEventListener(StreamEvent.STREAM_PAUSE,onStreamPauseFromPublisher);	
					_cameraPublisher.addEventListener(StreamEvent.STREAM_RECEIVE,onStreamReceiveFromPublisher);
					_cameraPublisher.addEventListener(StreamEvent.NO_STREAM_DETECTED,onNoStreamDetectedFromPublisher);
					_cameraPublisher.addEventListener(Event.CHANGE, onCameraPublisherChange);
					addChild(_cameraPublisher);
					
					if ( _groupName ) {
						_cameraPublisher.groupName = _groupName ;
					}
				}
				
				
				
				if( !_startStopBtn && _streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM) > UserRoles.VIEWER) {
					addStartStopBtn();
				}
				
				
					
				onSynchronizationChange();
				
				//will create the subscribers if the collection is already synchronized
				
			}
			
			
			/**
			 * @private
			 * The <code>sharedID</code> is the ID of the class 
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
		 	 * The IConnectSession with which this component is associated. 
		 	 * Note that this may only be set once before <code>subscribe()</code>
		 	 * is called; re-sessioning of components is not supported. 
		 	 * Defaults to the first IConnectSession created in the application.
		 	 */
			public function get connectSession():IConnectSession
			{
				return _connectSession;
			}
			
			/**
		 	 * Sets the IConnectSession with which this component is associated. 
		 	 */
			public function set connectSession(p_session:IConnectSession):void
			{
				_connectSession = p_session;
			}
		
		/**
		 * Tells the component to begin synchronizing with the service. 
		 * For UIComponent-based components such as this one,
		 * <code>subscribe()</code> is called automatically upon being added to the <code>displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
			public function subscribe():void
			{
				if ( !_streamManager ) {
					_streamManager = _connectSession.streamManager;
					_streamManager.addEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
					_streamManager.addEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
				}
					
				if ( !_userManager ) {
					_userManager = _connectSession.userManager;
				}
				
				if (!_cameraModel ) {
					if ( id == null ){
						if ( sharedID == null ) {
							sharedID = DEFAULT_SHARED_ID ;
						}
					}else {
						if ( sharedID == null ) {
							sharedID = id ;
						}
					}
					_cameraModel = new CameraModel();
					_cameraModel.sharedID = sharedID ;
					_cameraModel.connectSession = _connectSession ;
					_cameraModel.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
					_cameraModel.addEventListener(CameraModelEvent.QUALITY_CHANGE, onQualityChange);
					_cameraModel.addEventListener(CameraModelEvent.LAYOUT_CHANGE, onLayoutChange);
					_cameraModel.subscribe();
				}
			}
			
			/**
			 * Disposes all listeners to the network and framework classes. 
			 * Recommended for proper garbage collection of the component.
			 */
			public function close():void
			{
				if (_noCameraDetectButton) {
					_noCameraDetectButton.removeEventListener(MouseEvent.CLICK,onDetectButtonClick);
				}
				if (_cameraList) {
					_cameraList.removeEventListener(DropdownEvent.CLOSE, onCameraListSelect);
				}
				if (_cameraModel) {
					_cameraModel.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
					_cameraModel.removeEventListener(CameraModelEvent.QUALITY_CHANGE, onQualityChange);
					_cameraModel.removeEventListener(CameraModelEvent.LAYOUT_CHANGE, onLayoutChange);
					_cameraModel.close();
				}
			
	   			if (_cameraPublisher) {
					_cameraPublisher.removeEventListener(StreamEvent.STREAM_DELETE,onStreamDeleteFromPublisher);
					_cameraPublisher.removeEventListener(StreamEvent.STREAM_PAUSE,onStreamPauseFromPublisher);	
					_cameraPublisher.removeEventListener(StreamEvent.STREAM_RECEIVE,onStreamReceiveFromPublisher);
					_cameraPublisher.removeEventListener(StreamEvent.NO_STREAM_DETECTED,onNoStreamDetectedFromPublisher);
					_cameraPublisher.removeEventListener(Event.CHANGE, onCameraPublisherChange);
					_cameraPublisher.close();
	   			}
	   			if (_noCameraUICloseButton) {
					_noCameraUICloseButton.removeEventListener(MouseEvent.CLICK,onNoCameraCloseClick);
	   			}
	   			if (_pipOthersSubscriber) {
					_pipOthersSubscriber.removeEventListener(StreamEvent.STREAM_SELECT,updateNewPipDataProviders);
					_pipOthersSubscriber.removeEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
					_pipOthersSubscriber.removeEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
					_pipOthersSubscriber.close();
	   			}
	   			if (_pipMySubscriber) {
					_pipMySubscriber.removeEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
					_pipMySubscriber.removeEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
					_pipMySubscriber.close();
	   			}
	   			if (_streamManager) {
					_streamManager.removeEventListener(CollectionNodeEvent.USER_ROLE_CHANGE, onUserRoleChange);
					_streamManager.removeEventListener(StreamEvent.ASPECT_RATIO_CHANGE, onAspectRatioChange);
					_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, updatePipDataProviders);
					_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, updateAllPipDataProviders);
	   			}
	   			if (_sbsSubscriber) {
	   				_sbsSubscriber.close();
	   			}
			}
			
			/**
			 * @private 
			 */		
			protected function onSynchronizationChange(event:CollectionNodeEvent=null): void 
			{
				if (_cameraModel && _cameraModel.isSynchronized) {
					recreateSubscribers();
					invalidateDisplayList();
					addStartStopBtn();
				}
				
				if (_startStopBtn) {
					if ( _connectSession.sessionInternals.session_internal::connection as NetConnection == null ) {
						_startStopBtn.enabled = false ;
					} else { 
						_startStopBtn.enabled = _cameraModel.isSynchronized;
					}
				}
				
				

				if ( event != null ) {
					dispatchEvent(event);
                }
                
                if ( _cameraModel && !_cameraModel.isSynchronized ) {
                	if ( _startStopBtn ) {
                		_startStopBtn = null ;
                		_startStopState = STATE_START ;
                	}
                }
			}
			
			/**
			 * @private
			 */
			protected function onLayoutChange(p_evt:CameraModelEvent):void
			{
				
				recreateSubscribers();
				
				var event:CameraModelEvent = new CameraModelEvent(CameraModelEvent.LAYOUT_CHANGE);
				dispatchEvent(event);
			}
			
			//this is called when the model get synchronized and when the layout setting changes
			/**
			 * @private
			 */
			protected function recreateSubscribers():void
			{
				if (_cameraModel.layoutSetting == _layoutSetting) {
					return;
				}
				
				if ( _cameraModel ) {
					_layoutSetting = _cameraModel.layoutSetting;
				}
				//remove all subscribers
				//remove the _sbsSubscriber
				if (_sbsSubscriber && contains(_sbsSubscriber)) {
					_sbsSubscriber.removeEventListener(StreamEvent.DIMENSIONS_CHANGE, onStreamSubscriberHandler);
					_sbsSubscriber.removeEventListener(StreamEvent.STREAM_DELETE, onStreamSubscriberHandler);
					_sbsSubscriber.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamSubscriberHandler);
					_sbsSubscriber.removeEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
					_sbsSubscriber.removeEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
					//_sbsSubscriber.removeEventListener("numberOfStreamsChange", onNumberOfStreamsChange);

					removeChild(_sbsSubscriber);
					_sbsSubscriber.webcamPublisher = null;
					_sbsSubscriber = null;
				}

				if ( _pipMySubscriber && contains(_pipMySubscriber)) {
					removeChild(_pipMySubscriber);
					_pipMySubscriber.removeEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
					_pipMySubscriber.removeEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
					_pipMySubscriber.webcamPublisher = null ;
					_pipMySubscriber = null;
				}
				
				if ( _pipOthersSubscriber && contains(_pipOthersSubscriber)) {
					removeChild(_pipOthersSubscriber);
					_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, updatePipDataProviders);
					_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, updateAllPipDataProviders);
					_pipOthersSubscriber.removeEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
					_pipOthersSubscriber.removeEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
					_pipOthersSubscriber = null;
				}
				
				//now create the appropriate ones
				switch (_layoutSetting) {
					case CameraModel.PICTURE_IN_PICTURE:
						_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, updatePipDataProviders);
					
						_pipOthersSubscriber = new WebcamSubscriber();
						_pipOthersSubscriber.showBackground = false;
						_pipOthersSubscriber.id = "pipOthersSubscriber";
						_pipOthersSubscriber.contextMenu = contextMenu;
						_pipOthersSubscriber.layout = _layoutSetting ;
						addChild(_pipOthersSubscriber);
						
						if ( _groupName ) {
							_pipOthersSubscriber.groupName = _groupName ;
						}

						_pipMySubscriber = new WebcamSubscriber();
						_pipMySubscriber.showBackground = false;
						_pipMySubscriber.id = "pipMySubscriber";
						_pipMySubscriber.contextMenu = contextMenu;
						_pipMySubscriber.layout = _layoutSetting ;
						addChild(_pipMySubscriber);
						
						if (_cameraPublisher && _cameraPublisher.camera) {
							_pipMySubscriber.webcamPublisher = _cameraPublisher;
						}
						
						if ( _groupName ) {
							_pipMySubscriber.groupName = _groupName ;
						}
						
						updatePipDataProviders();
						
						break;
					case CameraModel.NEW_PICTURE_IN_PICTURE:
					
						_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, updateAllPipDataProviders);
					
						_pipOthersSubscriber = new WebcamSubscriber();
						_pipOthersSubscriber.showBackground = false;
						_pipOthersSubscriber.addEventListener(StreamEvent.STREAM_SELECT,updateNewPipDataProviders);
						_pipOthersSubscriber.addEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
						_pipOthersSubscriber.addEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
						_pipOthersSubscriber.id = "pipOthersSubscriber";
						_pipOthersSubscriber.contextMenu = contextMenu;
						_pipOthersSubscriber.layout = _layoutSetting ;
						
						if ( _groupName ) {
							_pipOthersSubscriber.groupName = _groupName ;
						}
						

						_pipMySubscriber = new WebcamSubscriber();
						_pipMySubscriber.showBackground = false;
						_pipMySubscriber.addEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
						_pipMySubscriber.addEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
						_pipMySubscriber.id = "pipMySubscriber";
						_pipMySubscriber.contextMenu = contextMenu;
						_pipMySubscriber.layout = _layoutSetting ;
						
						if ( _groupName ) {
							_pipMySubscriber.groupName = _groupName ;
						}
						
						addChild(_pipMySubscriber);
						addChild(_pipOthersSubscriber);
						
						if (_cameraPublisher && _cameraPublisher.camera) {
							_pipOthersSubscriber.webcamPublisher = _cameraPublisher;
							_pipMySubscriber.webcamPublisher = _cameraPublisher;
						}
						
						updateAllPipDataProviders();
						
						break;
					case CameraModel.SIDE_BY_SIDE:
						_sbsSubscriber = new WebcamSubscriber();
						_sbsSubscriber.showBackground = false;
						_sbsSubscriber.addEventListener(StreamEvent.DIMENSIONS_CHANGE, onStreamSubscriberHandler);
						_sbsSubscriber.addEventListener(StreamEvent.STREAM_DELETE, onStreamSubscriberHandler);
						_sbsSubscriber.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamSubscriberHandler);
						_sbsSubscriber.addEventListener(UserEvent.USER_BOOTED,onMyCameraClose);
						_sbsSubscriber.addEventListener(UserEvent.STREAM_CHANGE,onCameraPause);
						//_sbsSubscriber.addEventListener("numberOfStreamsChange", onNumberOfStreamsChange);
						_sbsSubscriber.contextMenu = contextMenu;
						_sbsSubscriber.layout = _layoutSetting ;
						addChild(_sbsSubscriber);
						
						if ( _groupName ) {
							_sbsSubscriber.groupName = _groupName ;
						}
						
						if (_cameraPublisher && _cameraPublisher.camera) {
							_sbsSubscriber.webcamPublisher = _cameraPublisher;
						}						
						break;
				}
				
				invalidateDisplayList();
			}

			
			/**
			 * @private
			 */
			protected function updatePipDataProviders(p_evt:StreamEvent=null):void
			{
				var streamDescriptors:Object = _streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
				var myDataProvider:ArrayCollection = new ArrayCollection();
				var othersDataProvider:ArrayCollection = new ArrayCollection();
				
				for (var id:String in streamDescriptors) {
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					if ( streamDescriptor.finishPublishing ) {
						if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
							myDataProvider.addItem(streamDescriptor);
						} else {
							othersDataProvider.addItem(streamDescriptor);
						}
					}
				}
//				_pipMySubscriber.dataProvider = myDataProvider;
//				_pipOthersSubscriber.dataProvider = othersDataProvider;				
			}
			
			
			/**
			 * @private
			 */
			protected function updateAllPipDataProviders(p_evt:StreamEvent=null):void
			{
				var streamDescriptors:Object = _streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
				var othersDataProvider:ArrayCollection = new ArrayCollection();
				var myDataProvider:ArrayCollection = new ArrayCollection();
				
				if (_cameraPublisher && _cameraPublisher.camera) {
					_pipOthersSubscriber.webcamPublisher = _cameraPublisher;
					_pipMySubscriber.webcamPublisher = _cameraPublisher;
				}
				
				for (var id:String in streamDescriptors) {
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					if ( streamDescriptor.finishPublishing ) {
						othersDataProvider.addItem(streamDescriptor); 
						
					}
				}
//				_pipMySubscriber.dataProvider = myDataProvider;	
//				_pipOthersSubscriber.dataProvider = othersDataProvider;			
			}
			
			/**
			 * @private
			 */
			protected function updateNewPipDataProviders(p_evt:StreamEvent=null):void
			{
				var streamDescriptors:Object = _streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
				var myDataProvider:ArrayCollection = new ArrayCollection();
				var othersDataProvider:ArrayCollection = new ArrayCollection();
				
				
				for (var id:String in streamDescriptors) {
					var streamDescriptor:StreamDescriptor = streamDescriptors[id];
					if ( streamDescriptor.finishPublishing ) {
						if (p_evt == null ) {
							othersDataProvider.addItem(streamDescriptor); 
						}
						else {
							if ( streamDescriptor.id == p_evt.streamDescriptor.id ) {
								myDataProvider.addItem(streamDescriptor);
							} else {
								othersDataProvider.addItem(streamDescriptor);
							}
						}
					}
				}
//				_pipMySubscriber.dataProvider = myDataProvider;
//				_pipOthersSubscriber.dataProvider = othersDataProvider;				
			}
			
			
			
			//****************************************
			//*****************************************
					
			/**
			 * @private
			 */
			override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
			{
				super.updateDisplayList(unscaledWidth,unscaledHeight);
				
				
				if (_startStopBtn) {
					_startStopBtn.setActualSize(_startStopBtn.measuredWidth,_startStopBtn.measuredHeight);
					_startStopBtn.move(width/2-_startStopBtn.width/2, unscaledHeight-_startStopBtn.measuredHeight);
				}				
				
				if (_noCameraUI) {
					_noCameraUI.setActualSize(unscaledWidth, unscaledHeight - _startStopBtn.height);
				}
				
				if (_noCameraLabel) {
					_noCameraLabel.setActualSize(_noCameraLabel.measuredWidth, _noCameraLabel.measuredHeight);
				}
	
				var theY:uint;
				
				if (_noCameraLabel && _noCameraDetectButton && _noCameraUICloseButton) {
					_noCameraDetectButton.setActualSize(_noCameraDetectButton.measuredWidth, _noCameraDetectButton.measuredHeight);
					_noCameraUICloseButton.setActualSize(_noCameraUICloseButton.measuredWidth, _noCameraUICloseButton.measuredHeight);

					var theX:uint = Math.round((unscaledWidth-(_noCameraDetectButton.measuredWidth+4+_noCameraUICloseButton.measuredWidth))/2);
					theY = Math.round((unscaledHeight-(_noCameraLabel.measuredHeight+_noCameraDetectButton.measuredHeight+10))/2);

					_noCameraLabel.move((unscaledWidth-_noCameraLabel.measuredWidth)/2, theY);
					_noCameraDetectButton.move(theX, theY + _noCameraLabel.measuredHeight + 10);
					_noCameraUICloseButton.move(theX+_noCameraDetectButton.measuredWidth+4, _noCameraDetectButton.y);
				}
				
				if (_cameraList) {
					theY = Math.round((unscaledHeight-(_noCameraLabel.measuredHeight+_cameraList.measuredHeight+10))/2);
					_noCameraLabel.move((unscaledWidth-_noCameraLabel.measuredWidth)/2, theY);
					_cameraList.setActualSize(_cameraList.measuredWidth+35, _cameraList.measuredHeight);
					_cameraList.move(Math.round((unscaledWidth-_cameraList.measuredWidth)/2), _noCameraLabel.y+_noCameraLabel.measuredHeight+10);
				}
				
				
				
				//layout subscribers
				switch (_cameraModel.layoutSetting) {
					case CameraModel.PICTURE_IN_PICTURE :	
						if (_pipOthersSubscriber) {
							_pipOthersSubscriber.setActualSize(unscaledWidth, unscaledHeight);
						}
						
						if (_pipMySubscriber) {
							_pipMySubscriber.setActualSize(Math.min(unscaledWidth*0.35, 120), Math.min(unscaledHeight*0.35, 120));
							_pipMySubscriber.move(unscaledWidth-_pipMySubscriber.measuredWidth, unscaledHeight-_pipMySubscriber.measuredHeight);
						} 
						break;
					case CameraModel.NEW_PICTURE_IN_PICTURE:	
						
						if (_pipOthersSubscriber) {
							//_pipOthersSubscriber.setActualSize(unscaledWidth,_startStopBtn.y- _pipMySubscriber.y - _pipMySubscriber.height - _startStopBtn.height/2);
							if ( unscaledWidth > unscaledHeight ) { 
								_pipOthersSubscriber.setActualSize(Math.min(unscaledWidth*0.35,120), unscaledHeight);
							//	_pipOthersSubscriber.y =  _pipMySubscriber.y + _pipMySubscriber.height - _startStopBtn.height/2+5;
								_pipOthersSubscriber.move(_pipMySubscriber.x + _pipMySubscriber.width, _pipMySubscriber.y);
							} else {
								_pipOthersSubscriber.setActualSize(unscaledWidth, Math.min(unscaledHeight*0.35,120));
								_pipOthersSubscriber.move(_pipMySubscriber.x, _pipMySubscriber.y + _pipMySubscriber.height);
							}
							
							if (_pipMySubscriber) {
							
								if ( unscaledWidth > unscaledHeight ) {
									_pipMySubscriber.setActualSize(unscaledWidth - _pipOthersSubscriber.width , unscaledHeight);
								}else {
									_pipMySubscriber.setActualSize(unscaledWidth , unscaledHeight - _pipOthersSubscriber.height);
								}

							} 
						}
						break;
					case CameraModel.SIDE_BY_SIDE:
						if (_sbsSubscriber) {
							if ( _startStopBtn && _startStopBtn.visible) {
								_sbsSubscriber.setActualSize(unscaledWidth, unscaledHeight - _startStopBtn.height);
							} else {
								_sbsSubscriber.setActualSize(unscaledWidth, unscaledHeight);
							}
							var videoStreams:Object = _streamManager.getStreamsOfType(StreamManager.CAMERA_STREAM,_groupName);
							var numStreams:Number = 0;
							for ( var id:String in videoStreams ) {
								numStreams++ ;
							}
							var g:Graphics = graphics ;
							if ( numStreams > 0 ) {
								g.clear();
								g.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000],[0.7,0.7],[0,255]);
								g.drawRect(0, 0, unscaledWidth,unscaledHeight);
								g.endFill();
							} else {
								g.clear();
								//g.beginGradientFill(GradientType.LINEAR, [0x686868, 0x535353],[1,1],[0,255]);
								//g.drawRect(0, 0, unscaledWidth,unscaledHeight);
								//g.endFill();
							}
						}
						break;
				}
				
				if (_startStopBtn) {
					setChildIndex(_startStopBtn, numChildren-1);
				}				
			}
			
			
		
			/**
		 	* @private
		 	* Handles the user role change event from shared stream manager
		 	*/
			protected function onUserRoleChange(p_evt:CollectionNodeEvent):void
			{
				// If the user has not permission to use camera
				// the UI changes are only if its you ..
				if ( p_evt.userID == _userManager.myUserID) {
					if(_streamManager.getUserRole(p_evt.userID,StreamManager.CAMERA_STREAM) < _streamManager.getNodeConfiguration(StreamManager.CAMERA_STREAM,_groupName).publishModel){
						if ( _startStopBtn ) {
							_startStopBtn.removeEventListener(MouseEvent.CLICK,onStartStopClick);
							removeChild(_startStopBtn);
							_startStopBtn = null ;
						}
						deleteNoCameraUI();
					}else {
						if( !_startStopBtn ) {
							addStartStopBtn();
						}
					}
				}
				
				invalidateDisplayList();// update the stage
				dispatchEvent(p_evt);	//bubble it up
			}

			/**
			 * @private
			 */
			protected function onAspectRatioChange(p_evt:StreamEvent):void
			{
				dispatchEvent(p_evt);
			}
	
			/**
			 * @private
			 */
			protected function addStartStopBtn():void
			{
				if ( ! _startStopBtn  && _streamManager.getUserRole(_userManager.myUserID,StreamManager.CAMERA_STREAM) >= UserRoles.PUBLISHER ) { 
					_startStopBtn = new Button();
					//_startStopBtn.toggle = true;
					if ( _connectSession.sessionInternals.session_internal::connection as NetConnection == null ) {
						_startStopBtn.enabled = false ;
					}
					_startStopBtn.label = _lm.getString("Start My Camera");
					_startStopBtn.addEventListener(MouseEvent.CLICK,onStartStopClick);
					addChild(_startStopBtn);
				}
			}
			
			/**
			 * @private
			 */
			protected function onMyCameraClose(p_evt:UserEvent):void
			{
				var userStreams:Array = _streamManager.getStreamsForPublisher(p_evt.userDescriptor.userID,StreamManager.CAMERA_STREAM,_groupName);
				for (var i:int = 0; i< userStreams.length ; i++ ) {
					if (userStreams[i].type == StreamManager.CAMERA_STREAM ) {
						_streamManager.deleteStream(StreamManager.CAMERA_STREAM,userStreams[i].streamPublisherID,_groupName);
						break;
					}
				}
			}
			
			/**
			 * @private
			 */
			protected function onCameraPause(p_evt:UserEvent):void
			{
				var userStreams:Array = _streamManager.getStreamsForPublisher(p_evt.userDescriptor.userID,StreamManager.CAMERA_STREAM,_groupName);
				
				if (userStreams.length == 0) {
					return;
				}
				
				for (var i:int = 0; i< userStreams.length ; i++ ) {
					if (userStreams[i].type == StreamManager.CAMERA_STREAM ) {
						break;
					}
				}
				
				var streamDescriptor:StreamDescriptor = userStreams[i];
				if ( streamDescriptor.streamPublisherID == _userManager.myUserID ) {
					_streamManager.pauseStream(StreamManager.CAMERA_STREAM,!streamDescriptor.pause,streamDescriptor.streamPublisherID,_groupName);
				}else {
					if ( !streamDescriptor.pause ) {
						_sbsSubscriber.pausePlayStreamLocally(streamDescriptor.type,streamDescriptor.streamPublisherID);
					}
				}
			}
			/**
			 * @private
			 * Specifying a minimum width
			 */
			override protected function measure():void
			{
				super.measure() ;
				// minimum width setting for the components to be made available in the design view
				minWidth = 250 ;
				minHeight = 200 ;
			}
			
		}
}