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
	import com.adobe.rtc.messaging.MessageItem;

	/**
	 * UserQueueEvent describes events dispatched by UserQueue. 
	 * See the constants below for a listing of possible types.
	 * 
	 * @see com.adobe.rtc.sharedModel.UserQueue
	 */	
	
   public class  UserQueueEvent extends Event
	{
		/**
		* Type of event emitted when the an item in the queue is added or dealt with
		*/
		public static const ITEM_UPDATE:String = "queueItemUpdate"; 

		/**
		* Type of event emitted when the queue is cleared
		*/
		public static const CLEAR:String = "queueClear";

		public static const LOG:String = "log";

		/**
		* Type of event dispatched when a user is accepted
		*/
		public static const ACCEPT:String = "accepted";
		/**
		* Type of event emitted when a user cancels a request on the queue
		*/
		public static const CANCEL:String = "cancel";
		/**
		* Type of event emitted when a user is denied a request on the queue
		*/
		public static const DENY:String = "deny";
		
		/**
		* The user ID that submitted the request that was updated
		*/
		public var userID:String;

		/**
		* The reason for clearing the queue
		*/
		public var reason:String;

		public function UserQueueEvent(p_type:String, p_userID:String=null)
		{
			super(p_type);
			if (p_userID!=null) {
				userID = p_userID;
			}
		}

		/**
		 * @private 
		 */
		public override function clone():Event
		{
			return new UserQueueEvent(type, userID);
		}
	}
}