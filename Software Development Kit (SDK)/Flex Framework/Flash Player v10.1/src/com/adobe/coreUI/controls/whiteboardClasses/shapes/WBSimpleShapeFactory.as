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
	import com.adobe.coreUI.controls.whiteboardClasses.IWBPropertiesToolBar;
	import com.adobe.coreUI.controls.whiteboardClasses.IWBShapeFactory;
	import com.adobe.coreUI.controls.whiteboardClasses.WBShapeBase;
	
	/**
	 * @private
	 */
   public class  WBSimpleShapeFactory implements IWBShapeFactory
	{
		protected var _toolBar:IWBPropertiesToolBar;
		protected var _shapeData:Object;
		
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_highlight_area')]
		public static var CURSOR_HIGHLIGHT_AREA:Class;
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_rectangle')]
		public static var CURSOR_RECTANGLE:Class;
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_ellipse')]
		public static var CURSOR_ELLIPSE:Class;
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_rounded_rectangle')]
		public static var CURSOR_ROUNDED_RECTANGLE:Class;
		
		public static const HIGHLIGHT_AREA:String = "highlight_area";		
		
		public function newShape():WBShapeBase
		{
			var shape:WBSimpleShape = new WBSimpleShape();
			if (_shapeData!=null) {
				if (_shapeData==HIGHLIGHT_AREA) {
					shape.definitionData = WBSimpleShape.ROUNDED_RECTANGLE;
				} else {
					shape.definitionData = _shapeData;
				}
			}
			if (_toolBar) {
				shape.propertyData = _toolBar.propertyData;
			}
			return shape;
		}
		
		public function get toolBar():IWBPropertiesToolBar
		{
			if (!_toolBar) {
				_toolBar = new WBPropertiesToolBar();
				var tmpShape:WBSimpleShape = new WBSimpleShape();
				if (_shapeData==HIGHLIGHT_AREA) {
					var props:Object = tmpShape.propertyData;
					props.primaryColor = 0xffff00;
					props.alpha = 0.5;
					tmpShape.propertyData = props;
				}
				_toolBar.propertyData = tmpShape.propertyData;
			}
			return _toolBar;
		}
		
		public function get toggleSelectionAfterDraw():Boolean
		{
			return false;
		}
		
		public function set shapeData(p_data:Object):void
		{
			_shapeData = p_data;
		}
		
		public function get cursor():Class
		{
			if (_shapeData==HIGHLIGHT_AREA) {
				return CURSOR_HIGHLIGHT_AREA;
			} else if (_shapeData==WBSimpleShape.ELLIPSE) {
				return CURSOR_ELLIPSE;
			} else if (_shapeData==WBSimpleShape.RECTANGLE) {
				return CURSOR_RECTANGLE;
			} else if (_shapeData==WBSimpleShape.ROUNDED_RECTANGLE) {
				return CURSOR_ROUNDED_RECTANGLE;
			}
			return null;
		}
		
		public function get factoryId():String
		{
			return null;
		}
		
	}
}