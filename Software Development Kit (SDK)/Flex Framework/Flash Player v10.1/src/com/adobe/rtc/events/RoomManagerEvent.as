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
	 * The event class dispatched by the RoomManager.
	 * @see com.adobe.rtc.sharedManagers.RoomManager
	 */
	
   public class  RoomManagerEvent extends Event
	{
		// uploading
		/**
		 * Dispatched when the room's bandwidth is changed manually by a user.
		 */
		public static const BW_SELECTION_CHANGE:String = "bwSelectionChange";
		
		/**
		 * Dispatched when the room's bandwidth is changed due to automatically detecting 
		 * the bandwidth of each participant and determining that a higher (or lower) bandwidth 
		 * throttle should be employed.
		 */
		public static const BW_ACTUAL_CHANGE:String = "bwActualChange";
		
		/**
		 * Dispatched when the RoomManager's <code>autoPromote</code> setting is changed.
		 */
		public static const AUTO_PROMOTE_CHANGE:String = "autoPromoteChange";
		
		/**
		 * Dispatched when the RoomManager's <code>roomState</code> setting is changed.
		 */
		public static const ROOM_STATE_CHANGE:String = "roomStateChange";
		
		/**
		 * Dispatched when the RoomManager's <code>guestsHaveToKnock</code> setting is changed.
		 */
		public static const GUESTS_HAVE_TO_KNOCK_CHANGE:String = "guestsHaveToKnockChange";
		
        /**
         * @private
         */
        public static const ROOM_NAME_CHANGE:String = "roomNameChange";
                      
		/**
		 * @private
		 */
		public static const RECORDING_CHANGE:String = "recordingChange";

		/**
         * @private
         */
        public static const SERVICE_LEVEL_CHANGE:String = "serviceLevelChange";

		/**
         * @private
         */
		public static const AUTO_DISCONNECT_WARNING:String = "autoDisconnectWarning";
		
		/**
		 * @private
		 */
		public static const AUTO_DISCONNECT_WARNING_TICK:String = "autoDisconnectWarningTick";
		
		/**
		 * @private
		 */
		public static const AUTO_DISCONNECT_DISCONNECTED:String = "autoDisconnectDisconnected";
		
		/**
		 * @private
		 */
		public static const AUTO_DISCONNECT_CANCELED:String = "autoDisconnectCanceled";
		
		/**
		 * @private
		 */
		public static const NO_HOST_WARNING:String = "noHostWarning";
		
		/**
		 * @private
		 */
		public static const NO_HOST_WARNING_TICK:String = "noHostWarningTick";
		
		/**
		 * @private
		 */
		public static const NO_HOST_DISCONNECTED:String = "noHostDisconnected";
		
		/**
		 * @private
		 */
		public static const NO_HOST_CANCELED:String = "noHostCanceled";
		
		/**
		 * Dispatched when the meeting ended message is changed
		 */
		public static const END_MEETING_MESSAGE_CHANGE:String = "endMeetingMessageChange";	
		
		/**
		 * @private
		 */
		public static const CONNECTION_SPEED_SETTINGS_CHANGE:String = "connectionSpeedSettingsChange";	
		/**
		 * Dispatched when the locked state of the room is changed.
		 */
		public static const ROOM_LOCK_CHANGE:String = "roomLockChange";
		/**
		 * Dispatched when guests not allowed parameter is changed.
		 */
		public static const ROOM_GUESTS_NOT_ALLOWED_CHANGE:String = "roomGuestsNotAllowedChange";
		/**
		 * Dispatched when the user limit of a room changes.
		 */
		public static const ROOM_USER_LIMIT_CHANGE:String = "roomUserLimitChange";
		/**
		 * Dispatched when the time out of a room changes.
		 */
		public static const ROOM_TIME_OUT_CHANGE:String = "roomTimeOutChange";
		
		/**
		 * @private
		 */
		public var recordingState:Object;
		
		/**
		 * Constructor.
		 */
		public function RoomManagerEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = true):void {
			super(type, bubbles, cancelable);
		}

		/**
		 * @private 
		 */
		public override function clone():Event
		{
			return new RoomManagerEvent(type, bubbles, cancelable);
		}
	}
}