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
	 * The event class for constants relating to com.adobe.rtc.pods.Note. 
	 *
	 * @see com.adobe.rtc.pods.Note
	 */
	
   public class  NoteEvent extends Event
	{
		
		/**
		 * Dispatched when the selection in the note changes.
		 */
		public static const SELECTION_CHANGE:String = "selectionChange";
		/**
		 * Dispatched when the scroll position of the note changes.
		 */
		public static const CLICK_INDEX_CHANGE:String = "clickIndexChange";
		/**
		 * Dispatched when the note is saved.
		 */
		public static const SAVE:String = "save" ;

		/**
		 * Dispatched when the note font size is increased.
		 */
		public static const INCREASE_FONT:String = "increaseFont" ;
		/**
		 * Dispatched when the note font size is decreased.
		 */
		public static const DECREASE_FONT:String = "decreaseFont" ;
		/**
		 * @private
		 */		
		public static const TITLE_MENU_CREATED:String = "titleMenuCreated" ;

		public function NoteEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}

		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new NoteEvent(type, bubbles, cancelable);
		}
		
	}
}