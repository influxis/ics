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
	 * Emitted by <code>RoomTemplater</code>, this event class notifies saves of a Room to a Template.
	 * 
	 * @see com.adobe.rtc.util.RoomTemplater
	 */
	
   public class  RoomTemplateEvent extends Event
	{

		/**
		 * Event type dispatched to indicate a room has been saved to a template
		 */
		public static const TEMPLATE_SAVE:String = "templateSave";
		

		public function RoomTemplateEvent(type:String, p_templateName:String)
		{
			templateName = p_templateName;
			super(type, false, false);
		}
		
		/**
		 * The name of the newly-saved template 
		 */
		public var templateName:String;
	}
}