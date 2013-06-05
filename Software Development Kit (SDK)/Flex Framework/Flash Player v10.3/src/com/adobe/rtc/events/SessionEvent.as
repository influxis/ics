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
	 * These events are emitted by various Session classes 
	 * 
	 * @see com.adobe.rtc.session.ConnetSession
	 * 
	 */
	
   public class  SessionEvent extends Event
	{
		
		/**
		* The type of event emitted when the session gains or loses synchronization with its source.
		*/
		public static const SYNCHRONIZATION_CHANGE:String = "synchronizationChange"; 

		/**
		* Type of event emitted when the server encounters an error.
		*/
		public static const ERROR:String = "error";
		/**
		* Type of event emitted when the session is logged in.
		*/
		public static const LOGIN:String = "login";
		/**
		* Type of event emitted when the session is disconnected.
		*/
		public static const DISCONNECT:String = "disconnect"; 
		/**
		* Type of event emitted when the session pings, and connection statistics are returned.
		*/
		public static const PING:String = "ping";
		/**
		* Type of event emitted when the connection status changes .
		*/
		public static const CONNECTION_STATUS_CHANGE:String = "connectionStatusChange";
		/**
		 * @private
		 */
		public static const TEMPLATE_SAVE:String = "templateSave";
		
		/**
		 * @private 
		 */
		public var userDescriptor:*;
		/**
		 * @private 
		 */
		public var ticket:String;
		/**
		 * When a sessionEvent of type error is dispatched, the source error for that event.
		 */
		public var error:Error;
		
		/**
		 * The latency of the connection, in seconds 
		 */
		public var latency:uint;
		/**
		 * The upload bandwidth currently used, in bits/second
		 */
		public var bwUp:uint;
		/**
		 * The download bandwidth currently used, in bits/second
		 */
		public var bwDown:uint;
		/**
		 * A formatted string for printing out latency
		 */
		public var latencyString:String;
		/**
		 * A formatted string for printing out bandwidth up
		 */
		public var bwUpString:String;
		/**
		 * A formatted string for printing out bandwidth down
		 */
		public var bwDownString:String;
		/**
		 * A raw object for holding various stats about the connection - see http://livedocs.adobe.com/flashmediaserver/3.0/hpdocs/help.html?content=00000263.html
		 */
		public var rawPingData:Object;
		
		
		/**
		 * A string representing the status of the connection - one of "connectionGood", "connectionFair", or "connectionReconnecting"
		 */
		public var connectionStatus:String;
		/**
		 * @private 
		 */
		public var templateName:String;
		
		public function SessionEvent(p_type:String)
		{
			super(p_type);
		}
		
		/**
		 * @private
		 */
		public override function clone():Event
		{
			var e:SessionEvent = new SessionEvent(type);
			e.userDescriptor = userDescriptor;
			e.ticket = ticket;
			e.error = error;
			e.latency = latency;
			e.bwUp = bwUp;
			e.bwDown = bwDown;
			e.latencyString = latencyString;
			e.bwUpString = bwUpString;
			e.bwDownString;
			e.connectionStatus = connectionStatus;
			e.rawPingData = rawPingData;
			return e;
		}
		
	}
}