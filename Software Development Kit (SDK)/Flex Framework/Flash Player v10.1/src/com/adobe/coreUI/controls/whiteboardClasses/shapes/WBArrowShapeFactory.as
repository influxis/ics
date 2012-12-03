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
   public class  WBArrowShapeFactory implements IWBShapeFactory
	{
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_arrow')]
		public static var CURSOR_ARROW:Class;
		[Embed (source = '../whiteboardAssets/toolBarIcons.swf#cursor_line')]
		public static var CURSOR_LINE:Class;

		public static const ARROW_HEAD:String = "arrowHead";
		public static const NO_ARROW_HEAD:String = "noArrowHead";
		
		protected var _shapeData:Object;
		protected var _toolBar:IWBPropertiesToolBar;
		
		public function get toolBar():IWBPropertiesToolBar
		{
			if (!_toolBar) {
				_toolBar = new WBPropertiesToolBar();
				var tmpShape:WBArrowShape = new WBArrowShape();
				_toolBar.propertyData = tmpShape.propertyData;
			}
			_toolBar.isFilledShape = false;
			return _toolBar;

		}
		
		public function newShape():WBShapeBase
		{
			var nShape:WBArrowShape = new WBArrowShape();
			var tmpObj:Object = nShape.definitionData;
			tmpObj.arrowHead = (_shapeData==ARROW_HEAD);
			nShape.definitionData = tmpObj;
			if (_toolBar) {
				nShape.propertyData = _toolBar.propertyData;
			}
			return nShape;
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
			if (_shapeData==ARROW_HEAD) {
				return CURSOR_ARROW;
			} else {
				return CURSOR_LINE;
			}
		}
		
		public function get factoryId():String
		{
			return null;
		}
	}
}