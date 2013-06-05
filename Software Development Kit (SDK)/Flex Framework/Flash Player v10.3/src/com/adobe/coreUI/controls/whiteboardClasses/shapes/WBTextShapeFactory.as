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
package com.adobe.coreUI.controls.whiteboardClasses.shapes
{
	import flash.display.Shape;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	
	/**
	 * @private
	 */
   public class  WBTextShapeFactory implements IWBShapeFactory
	{
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_text')]
		public static var CURSOR_TEXT:Class;
		
		public function newShape():WBShapeBase
		{
			var nShape:WBShapeBase = new WBTextShape();
			return nShape;
		}
		
		public function get toolBar():IWBPropertiesToolBar
		{
			return null;
		}
		
		public function get toggleSelectionAfterDraw():Boolean
		{
			return false;
		}
		
		public function set shapeData(p_data:Object):void
		{
		}
		
		public function get cursor():Class
		{
			return CURSOR_TEXT;
		}
		
		public function get factoryId():String
		{
			return null;
		}
		
	}
}