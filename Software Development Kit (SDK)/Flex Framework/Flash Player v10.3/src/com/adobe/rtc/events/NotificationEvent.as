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
package com.adobe.rtc.events
{
	import flash.events.Event;
	import mx.containers.Canvas;
	import com.adobe.rtc.clientManagers.notification.notifiers.SimpleNotifier;

	/**
	 * @private
	 */
	
   public class  NotificationEvent extends Event
	{
		/**
		* Type of event emitted when the Notifications Change
		*/
		public static const NOTIFICATION_ADD:String = "notificationAdd";
		public static const NOTIFICATION_REMOVE:String = "notificationRemove";
		public static const NOTIFICATION_STATE_CHANGE:String = "notificationStateChange";
		public static const NOTIFICATION_CANVAS_UPDATE:String = "notificationCanvasUpdate";
		public static const NOTIFICATION_DEALT_WITH:String = "notificationDealtWith";
//		public static const NOTIFICATION_TIMEOUT:String = "notificationTimeOut";
		
		
		public var id:String;
		public var canvas:SimpleNotifier; 
		
		public function NotificationEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true):void {
			super(type, bubbles, cancelable);
		}
		
	}
}