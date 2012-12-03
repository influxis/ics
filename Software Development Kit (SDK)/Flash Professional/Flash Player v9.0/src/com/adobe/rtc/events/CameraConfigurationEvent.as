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

	/**
	 * Emitted by <code>WebcamPublisher and ScreenSharePublisher</code>, this event class notifies changes to camera configuration.
	 * 
	 * @see com.adobe.rtc.collaboration.WebcamPublisher
	 */
	
   public class  CameraConfigurationEvent extends Event
	{
		/**
		 * Event type dispatched to indicate fps has changed.
		 */
		public static const FPS_CHANGED:String = "fpsChanged";

		/**
		 * Event type dispatched to indicate quality level has changed.
		 */
		public static const QUALITY_CHANGED:String = "qualityChanged";
		/**
		 * Event type dispatched to indicate Key Frame Interval Changed.
		 */
		public static const KEY_FRAME_INTERVAL_CHANGED:String = "keyFrameIntervalChanged";
		/**
		 * Event type dispatched to indicate Capturing width height factor changed
		 */
		public static const CAPTURE_WIDTH_HEIGHT_FACTOR_CHANGED:String = "captureWidthHeightFactorChanged";
		/**
		 * Event type dispatched to indicate the bandwidth cap is user changed and user defined
		 */
		public static const BANDWIDTH_CHANGED:String = "bandwidthChanged";
		
		/**
		 * Event type dispatched to indicate performance Changed.
		 */
		public static const PERFORMANCE_CHANGED:String = "performanceChanged";
		
		/**
		 * Event type dispatched to indicate High Fidelity quality setting Changed.
		 */
		public static const HFSS_CHANGED:String = "hfssChanged";
		
		
		public function CameraConfigurationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new CameraConfigurationEvent(type);
		}
		
	}
}