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
	import com.adobe.rtc.sharedManagers.descriptors.StreamDescriptor;
	
	import flash.display.BitmapData;
	import flash.events.Event;

	/**
	 * @private
	 */
	
   public class  ScreenShareEvent extends Event
	{
		public static const SCREEN_SHARE_STARTED:String = "screenShareStarted";
		public static const SCREEN_SHARE_PAUSED:String = "screenSharePaused";
		public static const SCREEN_SHARE_STARTING:String = "screenShareStarting";
		public static const SCREEN_SHARE_STOPPED:String = "screenShareStopped";
		public static const SCREEN_SHARE_PUSHED:String = "screenSharePushed";
		public static const CONTROL_REQUESTED:String = "controlRequested";
		public static const CONTROL_REQUEST_REMOVED:String = "controlRequestRemoved";
		public static const CONTROL_STARTED:String = "controlStarted";
		public static const CONTROL_STOPPED:String = "controlStopped";
		public static const VIDEO_PERCENTAGE_CHANGE:String = "videoPercentageChange";
		public static const SCALE_TO_FIT_CHANGE:String = "scaleToFitChange";
		public static const FIT_TO_WIDTH_CHANGE:String = "fitToWidthChange";
		public static const VIDEO_SNAPSHOT:String = "videoSnapShot";
		public static const CONTROL_REQUEST_CANCELED:String = "receivedCancelControl";

		/**
		* The descriptor associated with the stream being shared.
		*/
		public var streamDescriptor:StreamDescriptor;
		
		/**
		* The ID of the requester.
		*/
		public var requesterID:String;
		
		/**
		* If this is a snapshot event, the associated bitmapData.
		*/
		public var bitmapData:BitmapData;

		public function ScreenShareEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true):void {
			super(type, bubbles, cancelable);
		}

		public override function clone():Event
		{
			return new ScreenShareEvent(type, bubbles, cancelable);
		}
	}
}