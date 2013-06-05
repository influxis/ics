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
   public class  WBCanvasEvent extends Event
	{
		public static const PROPERTIES_TOOLBAR_ADD:String = "propertiesToolbarAdd";
		public static const PROPERTIES_TOOLBAR_REMOVE:String = "propertiesToolbarRemove";
		public static const CURSOR_CHANGE:String = "cursorChange";
		public static const END_DRAWING_SHAPE:String = "endDrawingShape";
		
		public function WBCanvasEvent(p_type:String)
		{
			super(p_type);
		}

		public override function clone():Event
		{
			return new WBCanvasEvent(type);
		}

	}
}