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
	 * AccountManagerEvent details the set of event types dispatched by an AccountManager, and includes properties
	 * concerning the events.
	 * 
	 * @see com.adobe.rtc.util.AccountManager
	 */
	
   public class  AccountManagerEvent extends Event
	{

		public function AccountManagerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}

		/**
		 * Event type emitted when a call to <code>login</code> to the service has succeeded
		 */
		public static const LOGIN_SUCCESS:String = "loginSuccess";
        /**
         * Event type emitted when a call to <code>login</code> to the service has failed
         */
        public static const LOGIN_FAILURE:String = "loginFailure";
		/**
		 * Event type emitted when a call to <code>requestTemplateList</code> has returned
		 */
		public static const TEMPLATE_LIST_RECEIVE:String = "templateListReceive";
		/**
		 * Event type emitted when a call to <code>requestRoomList</code> has returned
		 */
		public static const ROOM_LIST_RECEIVE:String = "roomListReceive";
		/**
		 * Event type emitted when a call to <code>requestArchiveList</code> has returned
		 */
		public static const ARCHIVE_LIST_RECEIVE:String = "archiveListReceive";		
		/**
		 * Event type emitted when a call to <code>createRoom</code> has returned
		 */
		public static const ROOM_CREATE:String = "roomCreate";
		/**
		 * Event type emitted when a call to <code>deleteRoom</code> has returned
		 */
		public static const ROOM_DELETE:String = "roomDelete";		
		/**
		 * Event type emitted when a call to <code>createTemplate</code> has returned
		 */
		public static const TEMPLATE_CLONE:String = "templateClone";
		/**
		 * Event type emitted when a call to <code>deleteTemplate</code> has returned
		 */
		public static const TEMPLATE_DELETE:String = "templateDelete";
        /**
         * Event type emitted when a request fails (probably because invalid permissions)
         */
        public static const ACCESS_ERROR:String = "accessError";
            
		/**
		 * For TEMPLATE_LIST_RECEIVE or ROOM_LIST_RECEIVE, the list of templates or rooms. This is returned as an array of objects
		 * with details about the rooms or templates.
		 */
		public var list:Array;
		/**
		 * For ROOM_DELETE or ROOM_CREATE, the name of the room affected
		 */
		public var roomName:String;
		/**
		 * For TEMPLATE_CREATE, the name of the template affected
		 */
        public var templateName:String;
	}
}
