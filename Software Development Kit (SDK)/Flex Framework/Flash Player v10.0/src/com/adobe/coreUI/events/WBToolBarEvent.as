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
package com.adobe.coreUI.events
{
	import flash.events.Event;

	/**
	 * @private
	 */
   public class  WBToolBarEvent extends Event
	{
		public static const TOOL_BAR_CLICK:String = "toolBarClick";
		public static const TOOLBAR_CHANGE:String = "toolBarChange";
		
		public var item:Object;
		
		public function WBToolBarEvent(type:String, data:Object=null)
		{
			super(type, bubbles, cancelable);
			item = data;
		}
		
	}
}