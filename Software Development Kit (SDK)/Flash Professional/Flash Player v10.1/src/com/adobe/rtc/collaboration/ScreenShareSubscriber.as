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
	import com.adobe.coreUI.util.StringUtils;
 
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.ScreenShareSubscriberCursor;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ScreenShareEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.managers.SessionManagerBase;
import flash.display.Sprite; //FlashOnlyReplacement 
 import flash.display.Shape; //FlashOnlyReplacement
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	import com.adobe.rtc.sharedModel.CollectionNode;
	import com.adobe.rtc.util.Invalidator;
	
	import flash.events.Event;
	import flash.events.IMEEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	 
	
	/**
	 * Dispatched when screensharing has started
	 */
	[Event(name="screenShareStarted", type="com.adobe.rtc.events.ScreenShareEvent")]

	/**
	 * Dispatched when screensharing has ended
	 */
	[Event(name="screenShareStopped", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * Dispatched when screensharing has been paused
	 */
	[Event(name="screenSharePaused", type="com.adobe.rtc.events.ScreenShareEvent")]

	/**
	 * Dispatched when screensharing is about to start (a publishing user is choosing the screen to share)
	 */
	[Event(name="screenShareStarting", type="com.adobe.rtc.events.ScreenShareEvent")]

	/**
	 * Dispatched when a user has begun controlling the shared screen
	 */
	[Event(name="controlStarted", type="com.adobe.rtc.events.ScreenShareEvent")]

	/**
	 * Dispatched when a user has stopped controlling the shared screen
	 */
	[Event(name="controlStopped", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="videoPercentageChange", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * @private 
	 */
	[Event(name="videoSnapShot", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]

    
	/**
	 * ScreenShareSubscriber is the foundation class for receiving and displaying screen share in a meeting room. By default,  
	 * ScreenShareSubscriber simply subscribes to StreamManager notifications and plays screen share in the room with default publisherID
	 * or it can also accept an <code class="property">publisherID</code> which restricts the screen share publisher that 
	 * can publish to this subscriber.
	 * 
	 * ScreenShareSubscriber is a basic screen share subscriber component, it does the minmum needed to subscribe to the screen share. 
	 * Use ScreenShareSubscriberComplex to enhance the feature with zoom and annotations.
	 *
	 * Example:
	 * _ssSubscriber = new ScreenShareSubscriber();	
	 * _ssSubscriber.publisherID = myScreenSharePublisherID; //OPTIONAL, if there is only one publisher in the room, then that publisherID is default.
	 * _ssSubscriber.connectSession = _cSession;
	 * _ssSubscriber.graphics.drawRect(0, 0, stage.width, stage.height);
	 * addChild(_ssSubscriber);	
	 * 
	 * 
	 * @see com.adobe.rtc.collaboration.ScreenSharePublisher
	 * @see com.adobe.rtc.collaboration.ScreenShareSubscriberComplex
	 * @see com.adobe.rtc.pods.WebCamera
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */
	
public class ScreenShareSubscriber extends Sprite implements ISessionSubscriber //FlashOnlyReplacement, IFocusManagerComponent
	{
		public static const SCALE_TO_FIT:uint = 0;
		public static const FIT_TO_WIDTH:uint = 1;
		public static const ACTUAL_SIZE:uint = 100;
		
		public static const RIGHT_MOUSE_DOWN:String = "rightMouseDown";
		public static const RIGHT_MOUSE_UP:String = "rightMouseUp";
		
		/**
		 * @private
		 */
		protected const PHASE_IDLE:uint = 0;
		/**
		 * @private
		 */
		protected const PHASE_I_AM_PREPARING_TO_SHARE:uint = 1;
		/**
		 * @private
		 */
		protected const PHASE_I_AM_SHARING:uint = 2;
		/**
		 * @private
		 */
		protected const PHASE_SOMEONE_ELSE_PREPARING:uint = 3;
		/**
		 * @private
		 */
		protected const PHASE_SOMEONE_ELSE_SHARING:uint = 4;
		/**
		 * @private
		 */
		protected var _fitToWidthPercent:Number = 0 ;
		/**
		 * @private
		 */
		protected var _scaleToFitPercent:Number = 0 ;
		
		/**
		 * @private
		 */
		protected var _streamID:String;
		/**
		 * @private
		 */
		protected var _controlStreamID:String;
		/**
		 * @private
		 */
		protected var _screenShareNet_streamIDchanged:Boolean = false;
		
		/**
		 * @private
		 */
		//replace with flashonly
 
		
		/**
		 * @private
		 */
		//replace with flashonly
		protected var _videoComponent:VideoComponent;
		
		/**
		 * @private
		 */
		protected var _screenShareDescriptor:StreamDescriptor;
		/**
		 * @private
		 */
		protected var _videoPercentage:Number;	//between 0 and 1
		/**
		 * @private
		 */
		protected var _invShowMyStream:Boolean = false;
		/**
		 * @private
		 */
		protected var _showMyStream:Boolean = false;
		
		/**
		 * @private
		 */
		protected var _streamManager:StreamManager;
		/**
		 * @private
		 */
		protected var _userManager:UserManager;
		/**
		 * @private
		 */
		protected var _screenShareNetStream:NetStream;
		
		/**
		 * @private
		 */
		protected var _controlOutStream:NetStream;
		/**
		 * @private
		 */
		protected var _isControlling:Boolean;
		/**
		 * @private
		 */
		protected var _remoteControlDescriptor:StreamDescriptor;
		/**
		 * @private
		 */
		protected var _remoteControlNetStream:NetStream;
		
		
		/**
		 * @private
		 */
		protected var _requestStreamName:String;
		/**
		 * @private
		 */
		protected var _sharerUserID:String;
		/**
		 * @private
		 */
		protected var _publisherID:String;
		
		/**
		 * @private
		 */
		protected var _phase:uint = PHASE_IDLE;
		
		/**
		 * @private
		 */
		protected var _zoomMode:uint = FIT_TO_WIDTH;
		/**
		 * @private
		 */
		protected var _zoomModeChanged:Boolean = true;
		
		/**
		 * @private
		 */
		// replace with flashonly
 
		/**
		 * @private
		 */
		protected var _shareCursor:ScreenShareSubscriberCursor;
		
		/**
		 * @private
		 */
		protected var _ignoreAutoScrollTimer:Timer;
		/**
		 * @private
		 */
		protected var _autoHideCursorTimer:Timer;
		/**
		 * @private
		 */
		protected var _lastCursorData:Object ;
		/**
		 * @private
		 */
		protected var _lastX:Number ;
		/**
		 * @private
		 */
		protected var _lastY:Number ;
		/**
		 * @private
		 */
		protected var _lastPositionSet:Boolean = false ;

		
		/**
		 * Determines whether or not the publisher's mouse should be shown.
		 */
		public var showMouse:Boolean = true;
		
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
		  //set to null when it is flashOnly version
		 protected var _connectSession:IConnectSession= null;
		/**
		 * @private
		 * Group Names
		 */
		protected var _groupName:String;
		
		
		public function ScreenShareSubscriber()
		{
super(); 
 this.addEventListener(Event.ADDED_TO_STAGE, onAddTOStage);  //FlashOnlyReplacement
			// addToStage for flashOnly
		}
		
		/**
		 * @private
		 */
		protected function doInitialSetup():void
		{
			_streamManager.addEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
			_streamManager.addEventListener(StreamEvent.STREAM_DELETE, onStreamDelete);
			_streamManager.addEventListener(StreamEvent.STREAM_PAUSE, onStreamPause);
			_streamManager.addEventListener(StreamEvent.DIMENSIONS_CHANGE,onDimensionsChange);
			_streamManager.addEventListener(ScreenShareEvent.CONTROL_REQUEST_CANCELED, onReceiveCancelControl);

			//look into it and set myself up properly
			var desc:StreamDescriptor ;
			
			var screenShareStreams:Object = _streamManager.getStreamsOfType(StreamManager.SCREENSHARE_STREAM,_groupName) ;
				
			for ( var id:String in screenShareStreams ) {
				
				if(_publisherID!= null && 
					(screenShareStreams[id].streamPublisherID != _publisherID 
					&& screenShareStreams[id].originalScreenPublisher != _publisherID) )
					continue;
				
				desc = screenShareStreams[id] ;
				
				_streamID = desc.id ;
				_requestStreamName = _streamID+"_controlStream";
				break ;
				
			}
			
			if (desc!=null) {
				setUpFromDescriptor(desc);
			}	
		
		}

	
		/**
		 * @private
		 * replace with onAddTOStage(p_evt:Event) for flashonly
		 */		
public function onAddTOStage(p_evt:Event):void
		{
			
			if ( !_subscribed ) {
				subscribe();
				_subscribed = true ;
			}
			
			if (!_autoHideCursorTimer) {
				_autoHideCursorTimer = new Timer(2*1000, 1);
				_autoHideCursorTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoHide);
			}

			 
			
			if (_streamManager && _streamManager.isSynchronized) {
				doInitialSetup();
			}
			
			 
			
		}

	
		
		
		 
		
		
		/**
		 * @private
		 */
		protected function onAutoHide(p_evt:TimerEvent):void
		{
			if (_shareCursor) {
				_shareCursor.visible = false;
			}
		}
		
		 
		
		/**
		 * returns the userID of the user currently in control of the screen, if any. 
		 */
		public function get controllerUserID():String
		{
			if(_remoteControlDescriptor) {
				return _remoteControlDescriptor.streamPublisherID;
			}
			return null;
		}
		
		/**
		 * Tells the component to begin synchronizing with the service. For UIComponent-based components such as this one,
		 * this is called automatically upon being added to the <code class="property">displayList</code>. 
		 * For "headless" components, this method must be called explicitly.
		 */
		public function subscribe():void
		{
			if (!_streamManager ) {
				_streamManager = _connectSession.streamManager;
				_streamManager.addEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
			}
			
			if ( !_userManager ) {
				_userManager = _connectSession.userManager;
			}
			// _userManager.addEventListener(UserEvent.USER_USERICONURL_CHANGE, onUserUsericonURLChange);
									
		}
		
		/**
		 * To be called when the current user would like to begin controlling the screen currently displayed. Note that the publisher of that screen
		 * needs to accept the request to control before this functionality is activated.
		 */
		public function startControlling():void
		{
			var streamDesc:StreamDescriptor ;
			
			streamDesc = _streamManager.getStreamDescriptor(StreamManager.REMOTE_CONTROL_STREAM, _userManager.myUserID, _groupName);
			
			if ( streamDesc == null ) {
				streamDesc = new StreamDescriptor();
				streamDesc.type = StreamManager.REMOTE_CONTROL_STREAM ;
				streamDesc.groupName = _groupName ;
				streamDesc.streamPublisherID = _userManager.myUserID ;
				_streamManager.createStream(streamDesc);
			}else{
				_streamManager.publishStream(StreamManager.REMOTE_CONTROL_STREAM, _userManager.myUserID, _groupName);
			}
			
			if ( _shareCursor )
				_shareCursor.visible = false;
			
 
			
			 
		}
		
		/** 
		 * Stops the controlling user's ability to control the screen
		 */
		public function stopControlling():void
		{
			if(_isControlling)
				_streamManager.deleteStream(StreamManager.REMOTE_CONTROL_STREAM, _userManager.myUserID , _groupName);			
		}
		
		/**
		 * To be called when the current user would like to begin controlling the screen currently displayed. Note that the publisher of that screen
		 * needs to accept the request to control before this functionality is activated.
		 */
		public function requestControlling(p_userID:String=null):void
		{
			
			if(!canIControl()) return;
			
			var streamDesc:StreamDescriptor ;
			
			streamDesc = _streamManager.getStreamDescriptor(StreamManager.REMOTE_CONTROL_STREAM, _userManager.myUserID, _groupName);
			
			if ( streamDesc == null ) {
				streamDesc = new StreamDescriptor();
				streamDesc.type = StreamManager.REMOTE_CONTROL_STREAM ;
				streamDesc.groupName = _groupName ;
				streamDesc.streamPublisherID = _userManager.myUserID ;
				streamDesc.requestControl = true;
				/*no need for specifying recipients because only one publisher per subscriber*/
				_streamManager.createStream(streamDesc);
			}else{
				streamDesc.requestControl = true;
				/*no need for specifying recipients because only one publisher per subscriber*/
				_streamManager.publishStream(StreamManager.REMOTE_CONTROL_STREAM, _userManager.myUserID, _groupName);
			}
			
			if ( _shareCursor )
				_shareCursor.visible = false;
			
 
			
			 

		}
		
		/**
		 * returns true if the current user can ask for control of the screen, false if not.
		 */
		public function canIControl():Boolean
		{
			return _streamManager.canUserPublish(_userManager.myUserID, StreamManager.REMOTE_CONTROL_STREAM,_groupName);
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
		 * setting the publisher id for whom you like to view their screen share stream
		 */		
		public function set publisherID(p_id:String):void
		{
			_publisherID = StringUtils.trim(p_id);
		}
		
		/**
		 * getting the publisher id for whom you like to view their screen share stream
		 */
		public function get publisherID():String
		{
			return _publisherID;
		}

		/**
		 * return the connectSession object 
		 * @return 
		 * 
		 */
		public function get connectSession():IConnectSession
		{
			return _connectSession;
		}
		
		/**
		 * @private
		 */
		public function set connectSession(p_session:IConnectSession):void
		{
			_connectSession = p_session;
		}
		
		/**
		 * returns true if the current user is sharing
		 */
		public function get iAmSharing():Boolean
		{
			return (_phase == PHASE_I_AM_SHARING);
		}
		
		/**
		 * returns true if the current user is preparing to share
		 */
		public function get iAmPreparingToShare():Boolean
		{
			return (_phase == PHASE_I_AM_PREPARING_TO_SHARE);
		}

		/**
		 * returns true if if someone else is preparing to share their screen
		 */
		public function get someoneElseIsPreparingToShare():Boolean
		{
			return (_phase == PHASE_SOMEONE_ELSE_PREPARING);
		}

		/**
		 * returns true if someone else is sharing their screen
		 */
		public function get someoneElseIsSharing():Boolean
		{
			return (_phase == PHASE_SOMEONE_ELSE_SHARING);
		}
		
		/**
		 * returns the userID of the user currently publishing the screen 
		 */
		public function get sharerUserID():String
		{
			if(_screenShareDescriptor) {
				if(_screenShareDescriptor.originalScreenPublisher != null) 
					return _screenShareDescriptor.originalScreenPublisher;
				else
					return _screenShareDescriptor.streamPublisherID;
			}
			return null;
		}

		
		/**
		 * @private 
		 */
		public function get videoPercentage():Number
		{
			return _videoPercentage;
		}
		
		/**
		 * @private 
		 */
		public function get scaleToFitPercent():Number
		{
			return _scaleToFitPercent*100
		}
		
		/**
		 * @private 
		 */
		public function get fitToWidthPercent():Number
		{
			return _fitToWidthPercent*100 ;
		}
		
		
		/**
		 * @private
		 */
		public function set showMyStream(p_show:Boolean):void
		{
			if (p_show!=_showMyStream) {
				_showMyStream = true;
				_invShowMyStream = true;
 
			}
		}
		
		/**
		 * if true, the subscriber will show the stream, even if the current user is the user publishing it. Defaults to false, in order to conserve bandwidth.
		 */
		public function get showMyStream():Boolean
		{
			return _showMyStream;
		}
		
		
		/**
		 * @deprectad
		 */
		public function set groupName(p_groupName:String):void
		{
			if ( _groupName != p_groupName ) {
				
				if ( _streamManager == null || !_streamManager.isSynchronized ) {
					return ;
				}
				
				
				if ( _isControlling ) {
					stopControlling() ;
				}
				
				cleanUpVideo();
				
				_groupName = p_groupName ;
				doInitialSetup();
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
		

		[Bindable(event="synchronizationChange")]
		public function get isSynchronized():Boolean
		{
			return _streamManager.isSynchronized;
		}



		/**
		 * @private
		 */
		protected function onSynchronizationChange(p_evt:CollectionNodeEvent):void
		{
			if (_streamManager.isSynchronized) {
				doInitialSetup();
			} else {
				_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.removeEventListener(StreamEvent.STREAM_DELETE, onStreamDelete);
				_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE, onStreamPause);
				cleanUpVideo();
			}
			dispatchEvent(p_evt);	
		}

		
		
		/**
		 * @private
		 */
		protected function onStreamReceive(p_evt:StreamEvent):void
		{
			// Play the stream in the video.
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if ( desc.groupName && desc.groupName != _groupName ) {
				return ;
			} 
			
			if ( desc.type == StreamManager.SCREENSHARE_STREAM || desc.type == StreamManager.REMOTE_CONTROL_STREAM) {
				
				if(_publisherID!= null && (desc.streamPublisherID != _publisherID && desc.originalScreenPublisher != _publisherID) )
					return;
			
				if(desc.type == StreamManager.SCREENSHARE_STREAM) {
					_streamID = desc.id ;
				}else if (desc.type == StreamManager.REMOTE_CONTROL_STREAM){
					_controlStreamID = desc.id;
				}
				
				_requestStreamName = desc.id+"_controlStream";
				
				
			} else {
				return ;
			}
			
			setUpFromDescriptor(desc);
		}
		
		/**
		 * @private
		 */
		protected function onStreamPause(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if ( desc.groupName && desc.groupName != _groupName ) {
				return ;
			} 
			
			if ( desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM) {
				return ;
			}
			
			// 
			if	(desc.streamPublisherID ==_userManager.myUserID || desc.originalScreenPublisher == _userManager.myUserID) {
				// don't listen to my own pauses
				return;
			}
			//dealWithStreamPause(desc);	
 	
			var event:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.SCREEN_SHARE_PAUSED);
			event.streamDescriptor = desc;
			dispatchEvent(event);	
		}
		
	
		/**
		 * Handles the StreamDelete event.  When a stream descriptor is deleted, the video stream
		 * it described should disappear from view.
		 * 
		 * @private
		 */
		protected function onStreamDelete(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if ( desc.groupName && desc.groupName != _groupName ) {
				return ;
			} 
			
			
			if ( desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM) {
				return ;
			}
			
			if (desc.type == StreamManager.SCREENSHARE_STREAM &&
				desc.id == _streamID)
			{
				
				cleanUpVideo();
				_phase = PHASE_IDLE;
				_streamID = null;
				
				// Dispatch event.
				var event:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.SCREEN_SHARE_STOPPED);
				event.streamDescriptor = _screenShareDescriptor;
				_screenShareDescriptor = null;
				dispatchEvent(event);
				
				if (_isControlling) {
					stopControlling();
				}				
				
				
 
			}
			else if (p_evt.streamDescriptor.type == StreamManager.REMOTE_CONTROL_STREAM)
			{				
				if (_isControlling) {
					_isControlling = false;
					_controlOutStream.publish(null);
					_controlOutStream.close();
					
					if(_shareCursor && !_shareCursor.visible){
						_shareCursor.visible = true;
					}
					
					if (_videoComponent) {
						_videoComponent.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
						_videoComponent.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
						_videoComponent.removeEventListener(RIGHT_MOUSE_DOWN, onRightMouseDown);
						_videoComponent.removeEventListener(RIGHT_MOUSE_UP, onRightMouseUp);
						_videoComponent.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
						_videoComponent.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
						_videoComponent.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
						
					}
					
					System.ime.removeEventListener(IMEEvent.IME_COMPOSITION,onIMEComposition);

					//if (_imeTextField ) 
					//_imeTextField.removeEventListener(Event.CHANGE,onImeInput);
					deleteIME();
					
					 					
				}
				
				_remoteControlDescriptor = null;
				dispatchEvent(new ScreenShareEvent(ScreenShareEvent.CONTROL_STOPPED));
 
			}
		}
		
		/**
		 * @private
		 */
		protected function onDimensionsChange(p_evt:StreamEvent):void
		{
			var desc:StreamDescriptor = p_evt.streamDescriptor;
			
			if ( desc.groupName && desc.groupName != _groupName ) {
				return ;
			} 
			
			if ( desc.type != StreamManager.SCREENSHARE_STREAM && desc.type != StreamManager.REMOTE_CONTROL_STREAM) {
				return ;
			}
		
			if	(desc.streamPublisherID ==_userManager.myUserID || desc.originalScreenPublisher == _userManager.myUserID) {
				// don't listen to my own pauses
				return;
			}else {
				_screenShareDescriptor = p_evt.streamDescriptor ;
 
			}
			
			dispatchEvent(p_evt);
		}
		
		/**
		 * @private
		 */
		protected function setUpFromDescriptor(p_desc:StreamDescriptor):void
		{
			var event:ScreenShareEvent;
			
			if (p_desc.type != StreamManager.REMOTE_CONTROL_STREAM 
					&& (p_desc.streamPublisherID ==  _userManager.myUserID 
						|| p_desc.originalScreenPublisher == _userManager.myUserID)
					&& !_showMyStream ) {

					return;
			}

			if	(p_desc.type == StreamManager.SCREENSHARE_STREAM)
			{				
				if(p_desc.originalScreenPublisher != null)
					_sharerUserID = p_desc.originalScreenPublisher;
				else 
					_sharerUserID = p_desc.streamPublisherID;
				
				if (p_desc.finishPublishing) {
					_screenShareDescriptor = p_desc;
					
					var sessionManager:SessionManagerBase = _connectSession.sessionInternals.session_internal::sessionManager;
					_screenShareNetStream = sessionManager.session_internal::getAndPlayAVStream(p_desc.id);

					_screenShareNetStream.client = this;
					
_videoComponent = new VideoComponent();  
 _videoComponent.graphics.drawRect(0, 0, width, height); 

					_videoComponent.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
					_videoComponent.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
					_videoComponent.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
addChild(_videoComponent); 

	
					_videoComponent.attachNetStream(_screenShareNetStream);
	
	
					// create the cursor
					if(!_shareCursor && showMouse) {
_shareCursor = new ScreenShareSubscriberCursor(); 
 _shareCursor.connectSession = _connectSession; 

						//_shareCursor.controllingUserID = p_desc.streamPublisherID;
addChild(_shareCursor); 

					}
								
					dealWithStreamPause(p_desc);
								
					_phase = (p_desc.streamPublisherID == _userManager.myUserID || p_desc.originalScreenPublisher == _userManager.myUserID) ? PHASE_I_AM_SHARING : PHASE_SOMEONE_ELSE_SHARING;
					// Dispatch event.
					event = new ScreenShareEvent(ScreenShareEvent.SCREEN_SHARE_STARTED);
					event.streamDescriptor = p_desc;
					dispatchEvent(event);
				} else {
					_phase = (p_desc.streamPublisherID == _userManager.myUserID || p_desc.originalScreenPublisher == _userManager.myUserID) ? PHASE_I_AM_PREPARING_TO_SHARE : PHASE_SOMEONE_ELSE_PREPARING;

					// Dispatch event.
					event = new ScreenShareEvent(ScreenShareEvent.SCREEN_SHARE_STARTING);
					event.streamDescriptor = p_desc;
					dispatchEvent(event);
					
				}
			}
			else if (p_desc.type == StreamManager.REMOTE_CONTROL_STREAM)
			{
				if (p_desc.streamPublisherID == _userManager.myUserID)
				{
					//I need to start controlling
					_controlOutStream = new NetStream(_connectSession.sessionInternals.session_internal::connection as NetConnection);
					_controlOutStream.publish(_requestStreamName);
					
					// Register input listeners.
					_videoComponent.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
					_videoComponent.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
					_videoComponent.addEventListener(RIGHT_MOUSE_DOWN, onRightMouseDown);
					_videoComponent.addEventListener(RIGHT_MOUSE_UP, onRightMouseUp);
					
					_videoComponent.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
					_videoComponent.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
					
					 
					
					_isControlling = true;
					
					 
				}
				
				_remoteControlDescriptor = p_desc;
				event = new ScreenShareEvent(ScreenShareEvent.CONTROL_STARTED);
				event.streamDescriptor = p_desc;
				dispatchEvent(event);
			}
			
			
 			
		}
		
		/**
		 * @private 
		 */
		public function onReceiveCancelControl(p_evt:ScreenShareEvent):void
		{
			if(_isControlling && (p_evt.streamDescriptor.originalScreenPublisher == _sharerUserID ||
				p_evt.streamDescriptor.streamPublisherID == _sharerUserID) )
			{
				stopControlling();
			}
		}
		
		/**
		 * @private
		 */
		public function cursorData(p_x:Number, p_y:Number, p_type:Number, p_isDown:Boolean):void
		{
			if ( _shareCursor ) {
				if ( _lastCursorData == null 
				|| _lastCursorData.x != p_x 
				|| _lastCursorData.y != p_y 
				|| _lastCursorData.isDown != p_isDown ) {
					_shareCursor.visible = true;
				}
			
				_shareCursor.clicking = p_isDown;
			}

			if (_autoHideCursorTimer) {
				_autoHideCursorTimer.reset();
				_autoHideCursorTimer.start();
			}
			
			if ( _lastCursorData == null ) {
				_lastCursorData = new Object();
			}
			
			_lastCursorData.x = p_x ;
			_lastCursorData.y = p_y ;
			_lastCursorData.type = p_type ;
			_lastCursorData.isDown = p_isDown ;
			
			if (_shareCursor != null) {
_shareCursor.x = _videoComponent.x + _videoComponent.width * (p_x /_screenShareDescriptor.nativeWidth); 
 _shareCursor.y =  _videoComponent.y + _videoComponent.height * (p_y / _screenShareDescriptor.nativeHeight); 

			
				 
			}
		}
		
		/**
		 * @private 
		 */
		public function onMetaData(p_obj:*=null):void
		{
			
		}
		
		/**
		 * @private 
		 */
		public function onPlayStatus(p_obj:*=null):void
		{
			
		}
		//Setting the cursor data to this function doesn't send the cursor positions
		//
		/**
		 * @private 
		 */
		public function cursorDataNull(p_x:Number, p_y:Number, p_type:Number, p_isDown:Boolean):void
		{
			//no-op
		}
    
		/**
		 * @private 
		 */
		protected function onMouseOver(p_evt:MouseEvent):void
		{
			
		}
		
		/**
		 * @private 
		 */
		protected function onMouseMove(p_evt:MouseEvent):void
		{
			if(_isControlling) {				
				// Send over the percentage location to be resolution-independent.
				sendMouseEvent(MouseEvent.MOUSE_MOVE, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			}
		}
		/**
		 * @private 
		 */
		protected function onMouseOut(p_evt:MouseEvent):void
		{
			
		}
		
		/**
		 * @private 
		 */
		protected function onMouseUp(p_evt:MouseEvent):void
		{
			if(_isControlling ){//&& focusManager.getFocus()==this) {
				sendMouseEvent(MouseEvent.MOUSE_UP, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			}
		}
		
		/**
		 * @private 
		 */
		protected function onMouseDown(p_evt:MouseEvent):void
		{
			//no-op, let the complex component take over because of the flex only feature
			if(_isControlling ) {
				sendMouseEvent(MouseEvent.MOUSE_DOWN, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			} 
		}
		
		/**
		 * @private 
		 */
		protected function onRightMouseDown(p_evt:MouseEvent):void
		{
			if(_isControlling) {
				//if(focusManager.getFocus()!=this) {
				//	focusManager.setFocus(this);
				//}
				p_evt.preventDefault();			
				sendMouseEvent(RIGHT_MOUSE_DOWN, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);	
			}
		}
		
		/**
		 * @private 
		 */
		protected function onRightMouseUp(p_evt:MouseEvent):void
		{
			if(_isControlling ){//&& focusManager.getFocus()==this) {
				p_evt.preventDefault();
				sendMouseEvent(RIGHT_MOUSE_UP, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			}
		}
		
		/**
		 * @private 
		 */
		protected function dealWithStreamPause(p_desc:StreamDescriptor):void
		{
			
		}
		
		//Really Nasty hack :(
		// There is a bug in the addins playerGlobal .
		//Just implementing the hack as its faster
		
		//More abt the hack
		//The keyDown for a key is not working when it is pressed with the ctrl key, so for ctrl+a only ctrl key value
		//was dispatched for keydown
		
		//So the hack is, a key up for a key has to be preceded by a keydown event. So I recreate the keydown event and dispatch
		//it again during the keyUpEvent
		
		//For some weird reason Shift key worked. So had to handle only the ctrl key
		/**
		 * @private 
		 */
		protected var _specialKeyPressed:Boolean = false;
		/**
		 * @private 
		 */
		protected var _specialKeyReleased:Boolean = false;
		/**
		 * @private 
		 */
		protected function onKeyDown(p_evt:KeyboardEvent):void
		{
			
			if(_isControlling && p_evt.keyCode != 4294967295) {
				var isCtrlKeyPressed:Boolean = getNextKey(p_evt);
				var ctrlKeyCode:uint = 17;
				trace("Sending key down from keyDown method " + _specialKeyPressed);
				if (_specialKeyPressed && _specialKeyReleased && p_evt.keyCode == ctrlKeyCode) {
					_specialKeyPressed = isCtrlKeyPressed = false;
					//return;
					sendKeyboardEvent(KeyboardEvent.KEY_UP, ctrlKeyCode);
				}
				
				if (_specialKeyPressed && _specialKeyReleased && p_evt.keyCode != ctrlKeyCode) {
					//_specialKeyPressed = isCtrlKeyPressed;
					//sendKeyboardEvent(KeyboardEvent.KEY_DOWN, ctrlKeyCode);
					return;
				}
				
				_specialKeyPressed = isCtrlKeyPressed;
				//_specialKeyReleased = !_specialKeyPressed;
				sendKeyboardEvent(KeyboardEvent.KEY_DOWN, p_evt.keyCode);
			}
		}
		
		/**
		 * @private 
		 */
		protected var _toggleSpecialKey:Boolean = false;
		/**
		 * @private 
		 */
		protected function onKeyUp(p_evt:KeyboardEvent):void
		{
			if(_isControlling && p_evt.keyCode != 4294967295) {
				var isCtrlKeyPressed:Boolean = getNextKey(p_evt);
				var ctrlKeyCode:uint = 17;
				if (_specialKeyPressed && p_evt.keyCode !=ctrlKeyCode) {
					_specialKeyPressed = false;
					trace("Sending key down from keyUp method");
					sendKeyboardEvent(KeyboardEvent.KEY_DOWN, p_evt.keyCode);
					if (_toggleSpecialKey) {
						_toggleSpecialKey = false;
						sendKeyboardEvent(KeyboardEvent.KEY_UP, ctrlKeyCode);
					}
				} else if (_specialKeyPressed && p_evt.keyCode ==ctrlKeyCode) {
					_specialKeyReleased = true;
					_toggleSpecialKey = true;
					return;
				}
				sendKeyboardEvent(KeyboardEvent.KEY_UP, p_evt.keyCode);
			}
		}
		
		/**
		 * @private 
		 */
		protected function getNextKey(p_event:KeyboardEvent):Boolean
		{
			var key:int = -1;
			if (p_event.ctrlKey || p_event.altKey || p_event.shiftKey) {
				return true;				
			}else {
				return false;
			}
		}
		
		/**
		 * @private 
		 */
		protected function onIMEComposition(event:IMEEvent):void
		{
			
			_controlOutStream.send("imeInput", event.text );
			sendKeyboardEvent(KeyboardEvent.KEY_DOWN, Keyboard.ENTER);
			
			deleteIME();
			
		}
		
		/**
		 * @private 
		 */
		protected function deleteIME():void
		{
			
		}
		
		
		/**
		 * @private 
		 */
		protected function sendMouseEvent(p_eventName:String, p_x:Number, p_y:Number):void
		{
			_controlOutStream.send("mouseEvent", p_eventName, p_x, p_y);
		}
		
		/**
		 * @private 
		 */
		protected function sendKeyboardEvent(p_eventName:String, p_keyCode:uint):void
		{
			//trace("Sending keyboardEvent" + p_eventName, p_keyCode);
			_controlOutStream.send("keyboardEvent", p_eventName, p_keyCode);
		}
		
		/* NetStream remote methods
		---------------------------------------------------------------------------------------*/

		 
		
		public function get zoomMode():uint
		{
			return _zoomMode;
		}

		public function set zoomMode(p_value:uint):void
		{
/*			if(p_value != ACTUAL_SIZE && p_value != SCALE_TO_FIT) {
				throw new Error("zoomMode: That value is not valid.  You may only use the zoom mode constants defined in ScreenShareSubscriber.");
				return;
			}
*/			
			if(p_value != _zoomMode) {
				_zoomMode = p_value;
				_zoomModeChanged = true;
 
			}
		}
	
			
		
		/**
		 * @private 
		 */
		protected function cleanUpVideo():void
		{
			if(_videoComponent) {
				_videoComponent.attachNetStream(null);
				_videoComponent.clear();
				_videoComponent.close();
removeChild(_videoComponent);
				_videoComponent = null;
				_scaleToFitPercent = 0 ;
				_fitToWidthPercent = 0 ;
			}
			if (_screenShareNetStream) {
				_screenShareNetStream.close();
			}
			
			/*if (autoScroll) {
				autoScroll = false;
			}*/
			
			if(_shareCursor) {
removeChild(_shareCursor);
				_shareCursor = null;
			}
			
			/*if (_annotationWB) {
				clearAnnotation();
			}	*/		
		}
		
		/**
		 * Disposes of all listeners to the network and framework classes and assures the proper garbage collection of the component.
		 */
		public function close():void
		{
			cleanUpVideo();
		
			if (_autoHideCursorTimer) {
				_autoHideCursorTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAutoHide);
			}
			 
			if (_streamManager ) {
				_streamManager.removeEventListener(CollectionNodeEvent.SYNCHRONIZATION_CHANGE, onSynchronizationChange);
				_streamManager.removeEventListener(StreamEvent.STREAM_RECEIVE, onStreamReceive);
				_streamManager.removeEventListener(StreamEvent.STREAM_DELETE, onStreamDelete);
				_streamManager.removeEventListener(StreamEvent.STREAM_PAUSE, onStreamPause);
				_streamManager.removeEventListener(StreamEvent.DIMENSIONS_CHANGE,onDimensionsChange);
			}
			
			if (_videoComponent ) {
			
				_videoComponent.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				_videoComponent.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_videoComponent.removeEventListener(RIGHT_MOUSE_DOWN, onRightMouseDown);
				_videoComponent.removeEventListener(RIGHT_MOUSE_UP, onRightMouseUp);
				
				_videoComponent.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
				_videoComponent.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
				
			}
			
			 
		}
		

	}
}
