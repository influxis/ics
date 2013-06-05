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
package com.adobe.rtc.clientManagers.notification.notifiers
{
	import mx.containers.Canvas;
	import mx.controls.LinkButton;
	import com.adobe.rtc.events.NotificationEvent;
	import flash.events.MouseEvent;
	//import com.adobe.meeting.clientManagers.NotificationManager;
	import flash.events.Event;
	//import com.adobe.meeting.clientManagers.notification.NotificationDescriptor;
	import mx.controls.Text;

	/**
	 * @private
	 * Default Base class for all notifiers
	 * @author hibasu
	 * 
	 */	
   public class  SimpleNotifier extends Canvas
	{
		public static var HIDING:String = "hiding";
		
		public static const NOTIFICATION_ID:String = "override me";
		public static const DEFAULT_STATE:String = HIDING;

		protected var _message:Text;
		protected var _linkButton:LinkButton;
		
		protected var _messageStr:String;
		protected var _linkButtonStr:String;
		
		protected var _customData:*;
		
		public function SimpleNotifier()
		{
			super();
		}
		
		public function close():void
		{
			//override me and remove your listeners!
			if (_linkButton) {
				_linkButton.removeEventListener(MouseEvent.CLICK, onLinkClick);
			}
		}
		
		override public function initialize():void
		{
			super.initialize();
		}
		
		/**
		 * @private
		 * It overrides createchildren create a linkbutton and a text field
		 * 
		 */		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if ( !_linkButton ) {
				_linkButton = new LinkButton();
				_linkButton.label = _linkButtonStr;
				_linkButton.addEventListener(MouseEvent.CLICK, onLinkClick);
				addChild(_linkButton);
			}
			
			if ( !_message ) {
				_message = new Text();
				_message.width = 175-13;
				_message.setStyle("styleName", "NotifierTitle");
				_message.text = _messageStr;
				_message.selectable = false;
				addChild(_message);
			}			
		}
		
		/**
		 * @private
		 * On link button click, it dispatches an event that is received by the Notification Area
		 * @param p_evt
		 * 
		 */		
		protected function onLinkClick(p_evt:MouseEvent):void
		{	
			dispatchEvent(new Event(Event.CHANGE));	//TODO: come up with a better event?
		}

		/**
		 * The respective pods gets the current data using this function
		 * @return 
		 * 
		 */		
		public function getData():Object 
		{
			var dataObj:Object = new Object();
			if (_linkButton) {
				dataObj.link = _linkButton.label;
			}
			if (_message) {
				dataObj.text = _message.text;
			}
			dataObj.customData = _customData;
			return dataObj;
		}	
			
		//called by the 
		public function set value(p_object:Object):void
		{
			if (p_object != null) {
				if (p_object["message"] != null) {
					_messageStr = p_object.message;
					if (_message) {
						_message.text = _messageStr;
						_message.setStyle("fontFamily", "Arial");
					}
				}
				if (p_object["link"] != null) {
					_linkButtonStr = p_object.link;
					if (_linkButton) {
						_linkButton.label = _linkButtonStr;
					}
				}
				if (p_object["customData"] != null) {
					_customData = p_object.customData;
				}
			}
			invalidateProperties();
			invalidateDisplayList();
		}
		/**
		 * @private
		 * Overridding measure
		 * 
		 */			
		override protected function measure():void
		{
			super.measure();
		
			//measuredHeight is it's preferred size
			_message.validateSize();
			if (_linkButton) {
				_linkButton.validateSize();
			} else {
				return;	//not a good time to measure
			}
			
			measuredMinWidth = measuredWidth = 200;			
			measuredMinHeight = measuredHeight = _message.measuredMinHeight+5+_linkButton.measuredMinHeight;			
		}
		
		/**
		 * Overridding UnscaledWidth and UnscaledHeight
		 * @param unscaledWidth
		 * @param unscaledHeight
		 * 
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);	

			var theY:uint = 0;
						
			if (_message) {
				_message.setActualSize(175-13, _message.measuredHeight);
				theY+=_message.height;
			}
			
			if (_linkButton) {
				theY+=5;
				_linkButton.setActualSize(_linkButton.measuredWidth, _linkButton.measuredHeight);
				_linkButton.move(unscaledWidth-_linkButton.measuredWidth, theY);
			}
		}
		
	}
}