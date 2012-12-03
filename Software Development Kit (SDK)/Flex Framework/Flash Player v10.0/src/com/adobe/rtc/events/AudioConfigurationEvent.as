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
	 * Emitted by <code>AudioPublisher</code>, this event class notifies changes to audio configuration.
	 * 
	 * @see com.adobe.rtc.collaboration.AudioPublisher
	 */
	
   public class  AudioConfigurationEvent extends Event
	{
		/**
		 * Event type dispatched to indicate gain has changed.
		 */
		public static const GAIN_CHANGED:String = "gainChanged";

		/**
		 * Event type dispatched to indicate silence level has changed.
		 */
		public static const SILENCE_LEVEL_CHANGED:String = "silenceLevelChanged";
		/**
		 * Event type dispatched to indicate silence Timeout has changed.
		 */
		public static const SILENCE_TIMEOUT_CHANGED:String = "silenceTimeoutChanged";
		/**
		 * Event type dispatched to indicate echoSuppression has changed.
		 */
		public static const ECHO_SUPPRESSION_CHANGED:String = "echoSuppressionChanged";
		
		public function AudioConfigurationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new AuthenticationEvent(type);
		}
		
	}
}