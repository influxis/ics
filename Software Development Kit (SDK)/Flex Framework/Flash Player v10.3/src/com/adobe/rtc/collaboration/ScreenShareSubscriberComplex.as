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
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapesToolBar;
	import com.adobe.coreUI.events.WBCanvasEvent;
	import com.adobe.coreUI.events.WBToolBarEvent;
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.ScreenShareCanvas;
	import com.adobe.rtc.collaboration.screenShareSubscriberClasses.ScreenShareSubscriberCursor;
	import com.adobe.rtc.core.session_internal;
	import com.adobe.rtc.events.CollectionNodeEvent;
	import com.adobe.rtc.events.ScreenShareEvent;
	import com.adobe.rtc.events.StreamEvent;
	import com.adobe.rtc.pods.SharedWhiteBoard;
	import com.adobe.rtc.session.IConnectSession;
	import com.adobe.rtc.session.ISessionSubscriber;
	import com.adobe.rtc.session.sessionClasses.SessionContainerProxy;
	import com.adobe.rtc.sharedManagers.StreamManager;
	import com.adobe.rtc.sharedManagers.UserManager;
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	
	import flash.display.BitmapData;
	import flash.events.IMEEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.system.Capabilities;
	import flash.system.IMEConversionMode;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.controls.TextArea;
	import mx.core.Application;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Tween;
	import mx.effects.easing.Linear;
	import mx.events.ScrollEvent;
	import mx.managers.CursorManager;
	import mx.skins.halo.HaloFocusRect;
	
	[Event(name="screenShareStarted", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="screenShareStopped", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	[Event(name="screenSharePaused", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="screenShareStarting", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="controlStarted", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="controlStopped", type="com.adobe.rtc.events.ScreenShareEvent")]

	[Event(name="videoPercentageChange", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	[Event(name="videoSnapShot", type="com.adobe.rtc.events.ScreenShareEvent")]
	
	/**
	 * Dispatched when the component either loses its connection to the session or regains it
	 * and has finished re-synchronizing itself to the rest of the room.
	 */
	[Event(name="synchronizationChange", type="com.adobe.rtc.events.CollectionNodeEvent")]

	/**
	 * ScreenShareSubscriberComplex is the foundation class for receiving and displaying screen share in a meeting room. By default,  
	 * ScreenShareSubscriberComplex simply subscribes to StreamManager notifications and plays screen share in the room with default publisherID
	 * or it can also accept an <code class="property">publisherID</code> which restricts the screen share publisher that 
	 * can publish to this subscriber.
	 * 
	 * ScreenShareSubscriberComplex is a advance screen share subscriber component, it does ScreenShareSubscriber's task of subscribing to the screen share. 
	 * but ScreenShareSubscriberComplex also has feature to add with zoom and annotations white board.
	 *
	 * Example:
	 * _ssSubscriber = new ScreenShareSubscriberComplex();	
	 * _ssSubscriber.publisherID = myScreenSharePublisherID; //OPTIONAL, if there is only one publisher in the room, then that publisherID is default.
	 * _ssSubscriber.connectSession = _cSession;
	 * _ssSubscriber.graphics.drawRect(0, 0, stage.width, stage.height);
	 * addChild(_ssSubscriber);	
	 * 
	 * 
	 * @see com.adobe.rtc.collaboration.ScreenSharePublisher
	 * @see com.adobe.rtc.collaboration.ScreenShareSubscriber
	 * @see com.adobe.rtc.pods.WebCamera
	 * @see com.adobe.rtc.sharedManagers.StreamManager
	 * @see com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor
	 */
	
	
   public class  ScreenShareSubscriberComplex extends ScreenShareSubscriber 
	{	
		public static const SCALE_TO_FIT:uint = 0;
		public static const FIT_TO_WIDTH:uint = 1;
		public static const ACTUAL_SIZE:uint = 100;
		
		public static const IME_INPUT:String = "imeInput" ;
		public static const IME_POSITION:String = "imePosition" ;
		public static const IME_CARET_FREQUENCY:String = "imeCaretMessageFrequency" ;

		[Embed (source = 'screenShareSubscriberAssets/hand_open.png')]
		protected var CURSOR_HAND_OPEN:Class;
		[Embed (source = 'screenShareSubscriberAssets/hand_closed.png')]
		protected var CURSOR_HAND_CLOSED:Class;
				
		protected var _autoscrollTween:Tween;
		
		protected var _annotationWB:SharedWhiteBoard;

		protected var _annotationPropsBar:UIComponent;
		protected var _lastPropsBarPt:Point;
		protected var _annotationShapesBar:UIComponent;
		protected var _focusRect:HaloFocusRect;
		
		public var annotateOnPause:Boolean = false;
		public var allowSave:Boolean = true;
		public var autoScroll:Boolean = false;
		
		protected var _imeTextField:TextArea;

		
		/**
		 * Constructor.
		 * 
		 * @param The unique ID of the stream to receive.
		 */		
		public function ScreenShareSubscriberComplex():void
		{
			super();
		}
		
		//Call this BEFORE addChild!
		/*public function set streamID(p_id:String):void
		{
			_streamID = p_id;
			_requestStreamName = _streamID+"_controlStream";
		}*/
		
		/**
		 * @private
		 */
		override protected function measure():void
		{
			measuredMinWidth = 0;
			measuredMinHeight = 0;
			
			measuredHeight = 240;
			measuredWidth = 320;
			
			super.measure();
		}

		override protected function commitProperties():void
		{
			super.commitProperties();
			
			
/*
			// TODO : finish implementing this if we're asked for this feature;
			if (_invShowMyStream) {
				_invShowMyStream = false;
				
				var desc:StreamDescriptor = _streamManager.getStreamDescriptor(StreamManager.SCREENSHARE_STREAM, _streamID);
				if (desc!=null) {
					setUpFromDescriptor(desc);
				}
				
			}
*/

		}

		
		
		override protected function calculateZoom(zoomType:Number,p_width:Number,p_height:Number,p_isAdvanceCalculate:Boolean=false):void
		{
			
			if ( _screenShareDescriptor == null ) {
				return ;	
			}	
			var nativeW:Number = _screenShareDescriptor.nativeWidth;
			var nativeH:Number = _screenShareDescriptor.nativeHeight;
			
			var subscriberAspectRatio:Number = p_width / p_height;
			var streamAspectRatio:Number = nativeW / nativeH;

			var theW:Number;
			var theH:Number;
			var theX:Number;
			var theY:Number;
			
			if (zoomType == SCALE_TO_FIT) {
				_background.verticalScrollPolicy = ScrollPolicy.OFF;
				_background.horizontalScrollPolicy = ScrollPolicy.OFF;
				_background.horizontalScrollPosition = 0;
				_background.verticalScrollPosition = 0;
				
				// The subscriber is wider.  Center horizontally.
				if (subscriberAspectRatio > streamAspectRatio) {
					theH = p_height; //Math.min(unscaledHeight, nativeH);
					theW = theH*streamAspectRatio;
				}
				// The subscriber is taller, or they're the same.  Center vertically.
				else {
					theW = p_width;	//Math.min(unscaledWidth, nativeW);
					theH = theW / streamAspectRatio;
				}

				_videoPercentage = (theW/nativeW);	//w or h is the same here
				
				
				if ( _videoPercentage != _scaleToFitPercent ) {
					_scaleToFitPercent = _videoPercentage ;
					dispatchEvent(new ScreenShareEvent(ScreenShareEvent.SCALE_TO_FIT_CHANGE));
				}
				
				if ( p_isAdvanceCalculate ) {
					return ;
				}

				theX = Math.max(0, (p_width-theW)/2);
				theY = Math.max(0, (p_height-theH)/2);
				

			} else if (zoomType == FIT_TO_WIDTH) {
				if (subscriberAspectRatio > streamAspectRatio) {
					theW = Math.min(p_width-20, nativeW);
					theH = theW/streamAspectRatio;

					_videoPercentage = (theW/nativeW);

					_background.horizontalScrollPolicy = ScrollPolicy.OFF;
					_background.verticalScrollPolicy = ScrollPolicy.AUTO;
				}
				else {
					theH = Math.min(p_height-20, nativeH);
					theW = theH*streamAspectRatio;

					_videoPercentage = (theH/nativeH);

					_background.horizontalScrollPolicy = ScrollPolicy.AUTO;
					_background.verticalScrollPolicy = ScrollPolicy.OFF;
				}					
				_background.horizontalScrollPosition = 0;
				_background.verticalScrollPosition = 0;
				theX = Math.max(0, (p_width-theW)/2);
				theY = Math.max(0, (p_height-theH)/2);
				
				if ( _videoPercentage != _fitToWidthPercent) {
					_fitToWidthPercent = _videoPercentage ;
					dispatchEvent(new ScreenShareEvent(ScreenShareEvent.FIT_TO_WIDTH_CHANGE));
				}
				
				if ( p_isAdvanceCalculate ) {
					return ;
				}
			}
			else {
				_background.verticalScrollPolicy = ScrollPolicy.AUTO;
				_background.horizontalScrollPolicy = ScrollPolicy.AUTO;
				_background.horizontalScrollPosition = 0;
				_background.verticalScrollPosition = 0;
				
				theW = nativeW * _zoomMode/100;
				theH = nativeH * _zoomMode/100;
				theX = Math.max(0, (p_width-theW)/2);
				theY = Math.max(0, (p_height-theH)/2);

				_videoPercentage = _zoomMode/100;
				
				
			}

			
			dispatchEvent(new ScreenShareEvent(ScreenShareEvent.VIDEO_PERCENTAGE_CHANGE));
							
			_videoComponent.width = theW;
			_videoComponent.height = theH;
			_videoComponent.move(theX, theY);
			_background.validateNow();
			
			if (_annotationWB) {
				_annotationWB.move(theX, theY);
				_annotationWB.zoomLevel = theW/nativeW;
				_annotationWB.width = nativeW * Math.max(_annotationWB.zoomLevel, 1);
				_annotationWB.height = nativeH * Math.max(_annotationWB.zoomLevel, 1);
				
			}

		}
		
		
		/* Public functions
		---------------------------------------------------------------------------------------*/
		
		
		/**
		 * Returns the ID of the current sharer, or null if there is none.
		 */
		
		//removing this function as this duplicate of controllerUserID
		/*public function get currentController():String
		{
			if(_remoteControlDescriptor) {
				return _remoteControlDescriptor.streamPublisherID;
			}
			return null;
		}*/
		
	
		override protected function onStreamPause(p_evt:StreamEvent):void
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
			dealWithStreamPause(desc);	
			invalidateDisplayList();	
			var event:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.SCREEN_SHARE_PAUSED);
			event.streamDescriptor = desc;
			dispatchEvent(event);	
		}
		
		
		override protected function dealWithStreamPause(p_desc:StreamDescriptor):void
		{
			// if the stream is paused, annotate
			if (p_desc.pause) {
				if (!_annotationWB) {
					annotateOnPause = true;
					_annotationWB=new SharedWhiteBoard();
					_annotationWB.isStandalone=false;
					_annotationWB.sessionDependent=true;
					_annotationWB.allowSave=allowSave;
					_annotationWB.focusManager=focusManager;
					_annotationWB.setStyle("backgroundAlpha", 0);
					_annotationWB.id="annotation_WB";
					_annotationWB.popupPropertiesToolBar=false;
					_annotationWB.popupShapesToolBar=false;
					_annotationWB.addEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_ADD, onPropertiesToolBarChange);
					_annotationWB.addEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_REMOVE, onPropertiesToolBarChange);
					_background.addChild(_annotationWB);
					_annotationShapesBar=_annotationWB.shapesToolBar;
					_annotationShapesBar.addEventListener(WBToolBarEvent.TOOL_BAR_CLICK, onWBToolBarClick);
					addChild(_annotationShapesBar);
					invalidateDisplayList();
					callLater(setShapeBarPosition);
//						_annotationShapesBar.setActualSize(200, 500)
				}
			} else {
				clearAnnotation();
			}
		}
		
		protected function setShapeBarPosition():void
		{
			if ( _annotationShapesBar ) {
				_annotationShapesBar.move(50,50);
			}
		}
		
		protected function onWBToolBarClick(p_evt:WBToolBarEvent):void
		{
			if (p_evt.item.command!=WBShapesToolBar.COMMAND_SAVE) {
				return;
			}
			var shapesVis:Boolean;
			var propsVis:Boolean;
			if (_annotationShapesBar) {
				shapesVis = _annotationShapesBar.visible;
				_annotationShapesBar.visible = false;
			}
			if (_annotationPropsBar) {
				propsVis = _annotationPropsBar.visible;
				_annotationPropsBar.visible = false;
			}
			_annotationWB.hideSelection();
			VideoComponent.prepareForBitmapCapture();
			var bData:BitmapData = new BitmapData(width, height, true, 0xffffff);
	 		bData.draw(this, null, null, null, null, true);
	 		VideoComponent.endBitmapCapture();
			if (_annotationShapesBar) {
				_annotationShapesBar.visible = shapesVis;
			}
			if (_annotationPropsBar) {
				_annotationPropsBar.visible = propsVis;
			}
			_annotationWB.showSelection();
	 		var evt:ScreenShareEvent = new ScreenShareEvent(ScreenShareEvent.VIDEO_SNAPSHOT);
	 		evt.bitmapData = bData;
	 		dispatchEvent(evt);
		}
		
		protected function clearAnnotation():void
		{
			annotateOnPause = false;
			if (_annotationWB) {
				if (_screenShareDescriptor.streamPublisherID==_userManager.myUserID || 
					_screenShareDescriptor.originalScreenPublisher == _userManager.myUserID) {
					if ( _annotationWB.model ) {
						_annotationWB.model.removeAllShapes();
					}
				}
				_annotationWB.close();
				_background.removeChild(_annotationWB);
				_annotationWB.removeEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_ADD, onPropertiesToolBarChange);
				_annotationWB.removeEventListener(WBCanvasEvent.PROPERTIES_TOOLBAR_REMOVE, onPropertiesToolBarChange);
				_annotationWB = null;
				_annotationShapesBar.removeEventListener(WBToolBarEvent.TOOL_BAR_CLICK, onWBToolBarClick);
				
				removeChild(_annotationShapesBar);
				_annotationShapesBar = null;
				if (_annotationPropsBar) {
					removeChild(_annotationPropsBar);
					_annotationPropsBar = null;
				}
			}
		}
		
		protected function onPropertiesToolBarChange(p_evt:WBCanvasEvent):void
		{
			if (_annotationPropsBar) {
				//_lastPropsBarPt = new Point(_annotationPropsBar.x, _annotationPropsBar.y);
				removeChild(_annotationPropsBar);
				_annotationPropsBar = null;
			}
			if (_annotationWB.currentPropertiesToolBar) {
				var tmpVPos:int = _background.verticalScrollPosition;
				var tmpHPos:int = _background.horizontalScrollPosition;
				_annotationPropsBar = UIComponent(_annotationWB.currentPropertiesToolBar);
				addChild(_annotationPropsBar);
				_annotationPropsBar.validateNow();
				_annotationPropsBar.setActualSize(_annotationPropsBar.measuredWidth, _annotationPropsBar.measuredHeight);
				if (_lastPropsBarPt) {
					_annotationPropsBar.move(_lastPropsBarPt.x, _lastPropsBarPt.y);
				} else {
					_annotationPropsBar.move(_annotationShapesBar.x+_annotationShapesBar.width+2, _annotationShapesBar.y);
				}
				validateNow();
				_background.verticalScrollPosition = tmpVPos;
				_background.horizontalScrollPosition = tmpHPos;
			}
		}
			
		
		override protected function onMouseOver(p_evt:MouseEvent):void
		{
			if ( _zoomMode == SCALE_TO_FIT ) {
				CursorManager.removeAllCursors();
				return ;
			}
			if (_background.maxHorizontalScrollPosition>0 || _background.maxVerticalScrollPosition>0 ) {
				cursorManager.setCursor(CURSOR_HAND_OPEN);
			}
		}
		
		override protected function onMouseOut(p_evt:MouseEvent):void
		{
			cursorManager.removeAllCursors();
		}
		
		override protected function cleanUpVideo():void
		{
			if(_videoComponent) {
				_videoComponent.attachNetStream(null);
				_videoComponent.clear();
				_videoComponent.close();
				_background.removeChild(_videoComponent);
				_videoComponent = null;
				_scaleToFitPercent = 0 ;
				_fitToWidthPercent = 0 ;
			}
			if (_screenShareNetStream) {
				_screenShareNetStream.close();
			}
			
			if (autoScroll) {
				autoScroll = false;
			}
			
			if(_shareCursor) {
				_background.removeChild(_shareCursor);
				_shareCursor = null;
			}
			
			if (_annotationWB) {
				clearAnnotation();
			}			
		}
		

		
		/*
		protected function onUserUsericonURLChange(p_evt:UserEvent):void
		{
			if(_shareCursor) {
				_shareCursor.controllingUserID = p_evt.userDescriptor.userID;
			}
		}
		*/
		
		override public function cursorData(p_x:Number, p_y:Number, p_type:Number, p_isDown:Boolean):void
		{
			
			
			if(_shareCursor && !_isControlling && !_annotationWB) {
				// Choose the appropriate cursor.
				
				// if the last cursor data is not the same as current or it is the first time, then show the cursor
				if ( _lastCursorData == null || _lastCursorData.x != p_x || _lastCursorData.y != p_y || _lastCursorData.isDown != p_isDown ) {
					_shareCursor.visible = true;
				}
				
				
				_shareCursor.clicking = p_isDown;
				_autoHideCursorTimer.reset();
				_autoHideCursorTimer.start();
				
				if ( _lastCursorData == null ) {
					_lastCursorData = new Object();
				}
				_lastCursorData.x = p_x ;
				_lastCursorData.y = p_y ;
				_lastCursorData.type = p_type ;
				_lastCursorData.isDown = p_isDown ;
				
				// Move it to the right place.

				_shareCursorMove = new Move();
				_shareCursorMove.target = _shareCursor;
				_shareCursorMove.xTo = _videoComponent.x + _videoComponent.width * (p_x /_screenShareDescriptor.nativeWidth);
				_shareCursorMove.yTo = _videoComponent.y + _videoComponent.height * (p_y/ _screenShareDescriptor.nativeHeight);
				
				_shareCursorMove.play();

				// lastX and lastY gets set when we scroll the background....
				//if we set the last X and lastY such that after which the presenter's cursor hasnt moved 
				//then we stay there 
				if ( _lastX == _shareCursor.x && _lastY == _shareCursor.y) {
					
					if ( !_ignoreAutoScrollTimer.running ) {
						_ignoreAutoScrollTimer.reset();
						_ignoreAutoScrollTimer.start();
						_lastPositionSet = false ;
					}
				}else {
					// we go back if the presenter starts again... 
					//lastPositionSet is used to honour the timing such that if the presenter has moved after the time duration
					// of the background scroll, we start moving immediately instead of waiting....
					if ( !_lastPositionSet && _ignoreAutoScrollTimer.running ) {
						_ignoreAutoScrollTimer.stop();
					}
				
				}
				
				// AUTOSCROLLING
				// If the endpoint is farther right than 3/4 of the way across the screen,
				//   scroll until it isn't or we hit the max scroll position.		
				if (autoScroll && _zoomMode != SCALE_TO_FIT && !_ignoreAutoScrollTimer.running) {
					// Calculate the vertical and horizontal lines beyond which we should autoscroll.
					
					// Threshholds are based on _videoComponent instead of _background because _background's size can change
					//   if the mouse cursor image is on the far right or bottom.
					
					var X:Number ;
					var Y:Number ;
					if ( _zoomMode == 200 ) {
						X = 2*p_x ;
						Y = 2*p_y ;
					}else if ( _zoomMode == 400 ) {
						X = 4*p_x ;
						Y = 4*p_y ;
					}else {
						X = p_x ;
						Y = p_y ;
					}
					
					var topThreshhold:Number = _background.verticalScrollPosition + .25 * _videoComponent.height;
					var bottomThreshhold:Number = _background.verticalScrollPosition + .75 * _videoComponent.height;
					var leftThreshhold:Number = _background.horizontalScrollPosition + .25 * _videoComponent.width;
					var rightThreshhold:Number = _background.horizontalScrollPosition + .75 * _videoComponent.width;
	
					// Tween if necessary.  There are two sets of tween functions, vertical and horizontal, which can run simultaneously
					//   for diagonal autoscrolling.
					
					
					
					
					if(Y < topThreshhold && _background.verticalScrollPosition != 0) {
						_autoscrollTween = new Tween(this, _background.verticalScrollPosition, Y - .25 * _background.height, 500);
						_autoscrollTween.easingFunction = mx.effects.easing.Linear.easeInOut;
						_autoscrollTween.setTweenHandlers(onVerticalTweenUpdate, onVerticalTweenEnd);
					}
					else if(Y > bottomThreshhold && _background.verticalScrollPosition != _background.maxVerticalScrollPosition) {
						_autoscrollTween = new Tween(this, _background.verticalScrollPosition, Y - .75 * _background.height, 500);
						_autoscrollTween.easingFunction = mx.effects.easing.Linear.easeInOut;
						_autoscrollTween.setTweenHandlers(onVerticalTweenUpdate, onVerticalTweenEnd);
					}
	
					if(X < leftThreshhold && _background.horizontalScrollPosition != 0) {
						_autoscrollTween = new Tween(this, _background.horizontalScrollPosition, X - .25 * _background.width, 500);
						_autoscrollTween.easingFunction = mx.effects.easing.Linear.easeInOut;
						_autoscrollTween.setTweenHandlers(onHorizontalTweenUpdate, onHorizontalTweenEnd);
					}
					else if(X > rightThreshhold && _background.horizontalScrollPosition != _background.maxHorizontalScrollPosition) {
						_autoscrollTween = new Tween(this, _background.horizontalScrollPosition, X - .75 * _background.width, 500);
						_autoscrollTween.easingFunction = mx.effects.easing.Linear.easeInOut;
						_autoscrollTween.setTweenHandlers(onHorizontalTweenUpdate, onHorizontalTweenEnd);
					}
				}
					
				//invalidateDisplayList();
			}else if ( _shareCursor && _isControlling && p_type == 5 ) {
				
				if ( flash.system.Capabilities.hasIME  ) {
					createTextField();
					var scaleX:Number = _videoComponent.width / _screenShareDescriptor.nativeWidth ;
					var scaleY:Number = _videoComponent.height / _screenShareDescriptor.nativeHeight ;
					if ( _imeTextField ) {
						var localPt:Point = stage.globalToLocal(new Point(p_x*scaleX,p_y*scaleY));
						_imeTextField.x = localPt.x ;
						_imeTextField.y = localPt.y ;
					}
					
				}else {
					
					System.ime.removeEventListener(IMEEvent.IME_COMPOSITION,onIMEComposition);
				}
			}else {
				deleteIME();
			}
		}
		
		
		
		public function createTextField():void
		{
			if ( flash.system.Capabilities.hasIME  ) {
				
				if ( (flash.system.IME.conversionMode == flash.system.IMEConversionMode.CHINESE )||
					  ( flash.system.IME.conversionMode	==	flash.system.IMEConversionMode.JAPANESE_HIRAGANA ) ||
					   ( flash.system.IME.conversionMode	==	flash.system.IMEConversionMode.JAPANESE_KATAKANA_FULL ) ||
						( flash.system.IME.conversionMode ==	flash.system.IMEConversionMode.JAPANESE_KATAKANA_HALF ) || 
						( flash.system.IME.conversionMode ==	flash.system.IMEConversionMode.KOREAN ) ){
					if ( !_imeTextField && focusManager.getFocus() == this) {
						_imeTextField = new TextArea();
						addChild(_imeTextField);
						_imeTextField.setStyle("borderThickness", 1 ) ;
						_imeTextField.setStyle("focusThickness", 0 ) ;
						_imeTextField.setStyle("focusAlpha" , 0.2);
						_imeTextField.width = 200 ;
						_imeTextField.height = 30 ;
						_imeTextField.setFocus() ;
						System.ime.addEventListener(IMEEvent.IME_COMPOSITION,onIMEComposition);
					}else {
						if ( _imeTextField )
							_imeTextField.setFocus();
					}
				}
			}
		}
		
		public function onVerticalTweenUpdate(p_value:Number):void {
			_background.verticalScrollPosition = p_value;
		}
		
		public function onHorizontalTweenUpdate(p_value:Number):void {
			_background.horizontalScrollPosition = p_value;
		}
		
		public function onVerticalTweenEnd(p_value:Number):void
		{
		}
		
		public function onHorizontalTweenEnd(p_value:Number):void
		{
		}
		
		
		
		/* Remote control event handlers
		---------------------------------------------------------------------------------------*/
			
		protected var _initialDragPt:Point;
		protected var _initialScrollPos:Point;
		
		override protected function onMouseDown(p_evt:MouseEvent):void
		{
			if(_isControlling && focusManager.getFocus()==this) {
				sendMouseEvent(MouseEvent.MOUSE_DOWN, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
				
			} else if (_isControlling) {
				var bounds:Rectangle = getBounds(this);
				if (bounds.contains(mouseX, mouseY)) {
					focusManager.setFocus(this);
				}
			} else if (_background.maxHorizontalScrollPosition>0 || _background.maxVerticalScrollPosition>0) {
				// not controlling, could be an attempt to drag
				cursorManager.removeAllCursors();
				if ( _zoomMode != SCALE_TO_FIT ) {
					cursorManager.setCursor(CURSOR_HAND_CLOSED);
					_initialDragPt = new Point(mouseX, mouseY);
					_initialScrollPos = new Point(_background.horizontalScrollPosition, _background.verticalScrollPosition);
					_videoComponent.addEventListener(MouseEvent.MOUSE_MOVE, onDragVideo);
					stage.addEventListener(MouseEvent.MOUSE_UP, onReleaseVideo);
				}
			}
		}
		
		protected function onDragVideo(p_evt:MouseEvent):void
		{
			var deltaX:Number = Math.round(mouseX-_initialDragPt.x);
			_background.horizontalScrollPosition = Math.max(0, Math.min(_initialScrollPos.x - deltaX, _background.maxHorizontalScrollPosition));
			var deltaY:Number = Math.round(mouseY-_initialDragPt.y);
			_background.verticalScrollPosition = Math.max(0, Math.min(_initialScrollPos.y - deltaY, _background.maxVerticalScrollPosition));
			if (_background.horizontalScrollPosition==_background.maxHorizontalScrollPosition
				|| _background.horizontalScrollPosition==0) {
				_initialDragPt.x = mouseX;
				_initialScrollPos.x = _background.horizontalScrollPosition;
			}
			if (_background.verticalScrollPosition==_background.maxVerticalScrollPosition
				|| _background.verticalScrollPosition==0) {
				_initialDragPt.y = mouseY;
				_initialScrollPos.y = _background.verticalScrollPosition;
			}
			onBackgroundScroll();
		}
		
		protected function onReleaseVideo(p_evt:MouseEvent):void
		{
			_videoComponent.removeEventListener(MouseEvent.MOUSE_MOVE, onDragVideo);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onReleaseVideo);
			cursorManager.removeAllCursors();
			if (getBounds(this).contains(mouseX, mouseY) ) {
				cursorManager.setCursor(CURSOR_HAND_OPEN);
			}
		}
		
		override protected function onMouseUp(p_evt:MouseEvent):void
		{
			if(_isControlling && focusManager.getFocus()==this) {
				sendMouseEvent(MouseEvent.MOUSE_UP, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			}
		}
		
		override protected function onRightMouseDown(p_evt:MouseEvent):void
		{
			if(_isControlling) {
				if(focusManager.getFocus()!=this) {
					focusManager.setFocus(this);
				}
				p_evt.preventDefault();			
				sendMouseEvent(RIGHT_MOUSE_DOWN, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);	
			}
		}
		
		override protected function onRightMouseUp(p_evt:MouseEvent):void
		{
			if(_isControlling && focusManager.getFocus()==this) {
				p_evt.preventDefault();
				sendMouseEvent(RIGHT_MOUSE_UP, p_evt.localX / _videoComponent.width, p_evt.localY / _videoComponent.height);
			}
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
		//protected var _specialKeyPressed:Boolean = false;
		//protected var _specialKeyReleased:Boolean = false;
		override protected function onKeyDown(p_evt:KeyboardEvent):void
		{
			
			if(_isControlling && focusManager.getFocus()==this && p_evt.keyCode != 4294967295) {
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
		
		//protected var _toggleSpecialKey:Boolean = false;
		override protected function onKeyUp(p_evt:KeyboardEvent):void
		{
			if(_isControlling && focusManager.getFocus()==this && p_evt.keyCode != 4294967295) {
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
		
		
		override protected function deleteIME():void
		{
			if ( _imeTextField ) {
				removeChild(_imeTextField);
				_imeTextField = null ;
				validateDisplayList();
				validateNow();
			}
		}
		
		
		public function get isScrollable():Boolean
		{
			if (_background && (_videoComponent.width>_background.width || _videoComponent.height>_background.height) ) {
				return true;
			}
			return false;
		}
		
		
	}
}
