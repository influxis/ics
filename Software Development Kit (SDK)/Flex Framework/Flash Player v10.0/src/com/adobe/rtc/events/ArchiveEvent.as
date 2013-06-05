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

	public class ArchiveEvent extends Event
	{
		public function ArchiveEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Event type emitted when the current time in playback has changed.
		 */
		public static const CURRENT_TIME_CHANGE:String = "currentTimeChange";
        /**
         * Event type emitted when the total playback time has changed
         */
        public static const TOTAL_TIME_CHANGE:String = "totalTimeChange";
        /**
		 * Event type emitted when the recording changes i.e. starts/stops.
		 */
		public static const RECORDING_CHANGE:String = "recordingChange";
        /**
         * Event type emitted when the playback change i.e. starts/stops.
         */
        public static const PLAYBACK_CHANGE:String = "playbackChange";		
        
        
		/**
		 * @private 
		 */
		public override function clone():Event
		{
			return new ArchiveEvent(type);
		}		
	}
}