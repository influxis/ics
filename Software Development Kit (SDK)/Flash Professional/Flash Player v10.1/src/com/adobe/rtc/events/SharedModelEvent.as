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
	 * The event class dispatched by SharedProperties and BatonProperty.
	 * @see com.adobe.rtc.sharedModel.BaronProperty
	 */
	
   public class  SharedModelEvent extends Event
	{
		/**
		 * Dispatched when the baton holder changes.
		 */
		public static const BATON_HOLDER_CHANGE:String = "batonHolderChange";
		/**
		 * Dispatched when someone makes a baton request.
		 */
		public static const BATON_REQUEST:String = "batonRequest";
		/**
		 * Dispatched when the baton has been released.
		 */
		public static const BATON_RELEASE:String = "batonRelease";

		/**
		 * Used with BatonObject to indicate the property that is modified.
		 */
		public var PROPERTY_ID:String;
		/**
		 * @private
		 */
		public static const INDICES_SELECT:String = "indicesSelect";
		/**
		 * @private
		 */
		public static const SCROLL_UPDATE:String = "scrollUpdate";
		
				
		public function SharedModelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		
		/**
		 * @private
		 */
		public override function clone():Event
		{
			return new SharedModelEvent(type, bubbles, cancelable);
		}
	}
}