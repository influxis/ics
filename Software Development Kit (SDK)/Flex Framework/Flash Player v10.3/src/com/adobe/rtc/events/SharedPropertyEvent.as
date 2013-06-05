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
	 * The event class sent for events sent by SharedProperty. 
	 * 
	 * @see com.adobe.rtc.events.SharedPropertyEvent
	 */
	
   public class  SharedPropertyEvent extends Event
	{
		/**
		 * Dispatched when the shared property changes
		 */
		public static const CHANGE:String = "change"; 

		/**
		 * The body of the Shared Property
		 */
		public var value:*;
		/**
		 * The Publisher ID of the shared property
		 */ 
		public var publisherID:String  ;
		
		
		/**
		 *  Constructor
		 */
		public function SharedPropertyEvent(p_type:String, p_publisherID:String=null)
		{
			super(p_type);
			
			if (p_publisherID ) {
				publisherID = p_publisherID;
			}
		}

		/**
		* @private
		*/
		public override function clone():Event
		{
			return new SharedPropertyEvent(type, publisherID);
		}		
		
	}
}